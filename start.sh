#!/bin/bash
# Start the bridge in a tmux session and keep the Mac awake while it runs.
# Run this from Terminal (the app you gave Full Disk Access), not over SSH.
cd "$(dirname "$0")"
SESSION=remotecontrol

if ! command -v tmux >/dev/null; then
  echo "tmux not found; running in the foreground (keep this window open)."
  exec caffeinate -dis python3 bridge.py
fi

if tmux has-session -t "$SESSION" 2>/dev/null; then
  echo "Already running. Attach with: tmux attach -t $SESSION"
  exit 0
fi

tmux new-session -d -s "$SESSION" "caffeinate -dis python3 bridge.py; echo 'bridge exited'; read"
echo "Bridge started. Watch it with: tmux attach -t $SESSION   (detach: Ctrl-b d)"
echo "Stop it with: tmux kill-session -t $SESSION"
