# remotecontrol

Control your Mac by texting it. A small Python script watches Messages for texts
from your own phone number or Apple ID, runs each one as a Claude Code task, and
texts back the answer. Claude can use a browser (Playwright MCP) to do things on
websites for you.

```
iPhone --iMessage--> Mac: bridge.py --> claude -p (+ Playwright browser)
iPhone <--iMessage-- Mac: reply prefixed with 🤖
```

## Setup (on the Mac, before you leave)

You need: macOS, Claude Code logged in (`claude` works in Terminal), Node.js
(`npx`), and Python 3 (`xcode-select --install` if `python3` is missing).

1. **Clone and configure**
   ```bash
   git clone https://github.com/uponai8192/remotecontrol ~/remotecontrol
   cd ~/remotecontrol
   ./setup.sh
   ```
   `setup.sh` creates `config.json` and opens it. Set `allowed_senders` to
   **your own** phone number and/or Apple ID email, and nobody else's. Anyone on
   this list can run commands on your Mac.

2. **Grant permissions** (System Settings > Privacy & Security)
   - **Full Disk Access** for Terminal (or iTerm) so the script can read
     `~/Library/Messages/chat.db`. Quit and reopen Terminal afterwards.
   - **Automation > Messages** for Terminal. macOS asks the first time the
     script sends a text; click Allow.

3. **Run the doctor until everything says OK**
   ```bash
   python3 bridge.py doctor
   ```
   It checks each piece, lists your recent texts with the verdict it would
   give each one (`COMMAND` or `ignored`), sends a test text to your phone, and
   starts a headless Claude to confirm the Playwright browser tools load.
   Text the Mac something from your phone first, so there is a message to check.

4. **Log in to websites in the bridge's browser.** The bridge's browser has its
   own profile (`~/.remotecontrol/playwright-profile`), separate from your normal
   Chrome and from any Playwright session in your terminal. Open Chrome with that
   profile and log in to every site you'll want it to use:
   ```bash
   open -na "Google Chrome" --args --user-data-dir="$HOME/.remotecontrol/playwright-profile"
   ```
   Then **quit that Chrome window completely (Cmd-Q)**. While it's open, the
   profile is locked and the bridge can't start its browser.
   If Playwright later says Chrome isn't installed, run `npx playwright install chrome`.

5. **Start it**
   ```bash
   ./start.sh
   ```
   This runs the bridge in tmux under `caffeinate` so the Mac doesn't sleep.
   Start it from Terminal, the app that has Full Disk Access, not over SSH.
   Keep the Mac plugged in. If the lid will be closed, connect a display.
   Within a few seconds your phone should get **"🤖 Bridge online."** If it
   doesn't, the log lines printed by `start.sh` say what's wrong.

6. **Test it from your phone** before you go: text
   `go to amazon.com and tell me if I'm logged in` (this proves your logins
   carried over), then try `STATUS`, `STOP` and `NEW`.

## Texting it

Send any task in plain English:

- `What's the status of my latest Amazon order?`
- `Check in for my Delta flight tomorrow, confirmation ABC123`
- `Find the cheapest nonstop SFO to JFK next Friday on Google Flights`
- `Download my latest invoice from <site> into ~/Downloads`

Each text continues the same conversation, so follow-ups like `yes, do it` or
`now check the other one` work.

| Text     | Does                                   |
|----------|----------------------------------------|
| `STOP`   | Cancel the running task                |
| `NEW`    | Start a fresh conversation             |
| `STATUS` | Say what it's working on               |
| `HELP`   | List commands                          |

One task runs at a time. Tasks time out after `task_timeout_minutes`.

## Texting yourself

If you text your own number or Apple ID from your iPhone, the Mac records those
messages as sent *by you*. With `allow_self_chat: true` (the default) the bridge
accepts them in the chat with your own handle. It skips its own replies because
they start with 🤖. If this gives you trouble, text the Mac from a second
Apple ID instead, add that handle to `allowed_senders`, and set
`allow_self_chat` to `false`.

## Safety

- Only texts from `allowed_senders` in one-to-one chats are acted on. Group chats
  are ignored.
- By default Claude can use only the browser plus read-only file tools
  (`allowed_tools`). Any other tool is refused, because nobody is there to
  approve it.
- Claude is told never to buy, send, post, delete or submit anything without your
  explicit YES in an earlier text, and to treat web page content as data rather
  than instructions. That reduces the risk but can't guarantee it, so only log
  the bridge's browser into sites you're comfortable with it using.
- To let it run shell commands, add `"Bash"` to `allowed_tools`. Setting
  `permission_mode` to `bypassPermissions` allows everything. Both widen what a
  misread text or a malicious web page could do.
- A log is kept in `state/bridge.log`.

## Config reference (`config.json`)

| Key | Default | Meaning |
|-----|---------|---------|
| `allowed_senders` | — | Your phone number(s) / Apple ID email(s). Required. |
| `allow_self_chat` | `true` | Accept texts you send to your own handle. |
| `work_dir` | `~/remotecontrol-work` | Folder Claude runs in. |
| `permission_mode` | `default` | Claude Code permission mode. |
| `allowed_tools` | browser + Read/Glob/Grep | Tools Claude may use without asking. |
| `max_turns` | `60` | Max agent steps per task. |
| `task_timeout_minutes` | `15` | Kill a task after this long. |
| `poll_seconds` | `3` | How often to check for new texts. |
| `claude_bin` | `claude` | Path to the Claude Code CLI. |
| `model` | `""` | Optional model override. |
| `playwright_profile_dir` | `~/.remotecontrol/playwright-profile` | Browser profile (logins live here). |
| `playwright_extra_args` | `[]` | Extra `@playwright/mcp` flags, e.g. `["--browser", "chrome"]`. |

## Troubleshooting

- **No reply at all:** `tmux attach -t remotecontrol` and look at the log. Run
  `python3 bridge.py doctor` and check that your texts show as `COMMAND`.
- **"unable to open database file":** Terminal doesn't have Full Disk Access, or
  wasn't reopened after you granted it.
- **Replies fail to send:** grant Automation > Messages to Terminal, and make
  sure Messages is signed in to iMessage on the Mac.
- **Browser won't start:** another Playwright instance is using the same
  profile. Use a separate `playwright_profile_dir`, or close the other one.
