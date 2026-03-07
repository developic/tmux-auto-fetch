#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/src"
source "$SCRIPTS_DIR/toggle.sh"
source "$SCRIPTS_DIR/git.sh"

path="$(tmux display-message -p "#{pane_current_path}")"
cfg="$HOME/.config/tmux"
wl="$cfg/whitelist"

# Toggle if -w flag passed
[[ "$1" == "-w" ]] && toggle "$path" && exit

# Skip if whitelisted
grep -Fxq "$path" "$wl" && exit

# Get interval from tmux config (default 300)
SLEEP_INTERVAL=$(tmux show-option -gqv @tmux-fetch-sleep)
SLEEP_INTERVAL=${SLEEP_INTERVAL:-300}

# Initial git check
check_git "$path"

# Auto-check loop
while true; do
    sleep "$SLEEP_INTERVAL"
    check_git "$path"
done
