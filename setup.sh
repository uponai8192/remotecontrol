#!/bin/bash
# One-time setup: create config.json, then check permissions with the doctor.
set -e
cd "$(dirname "$0")"

if [[ "$(uname)" != "Darwin" ]]; then
  echo "This needs to run on your Mac." >&2
  exit 1
fi
command -v python3 >/dev/null || { echo "python3 not found. Run: xcode-select --install" >&2; exit 1; }

if [[ ! -f config.json ]]; then
  cp config.example.json config.json
  echo "Created config.json. Put your own phone number / Apple ID email in allowed_senders."
  ${EDITOR:-nano} config.json
fi

chmod +x start.sh
python3 bridge.py doctor
