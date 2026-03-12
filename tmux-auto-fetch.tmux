#!/usr/bin/env bash

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="${CURRENT_DIR}/src"

cfg="$HOME/.config/tmux"
wl="$CFG/whitelist"

source "$SCRIPTS_DIR/toggle.sh"
source "$SCRIPTS_DIR/git.sh"
source "$SCRIPTS_DIR/keybind.sh"


# set keybinding
set_toggle_binding

if [[ "$1" == "-w" ]]; then
    path="$(tmux display-message -p "#{pane_current_path}")"
    toggle "$path"
    exit
fi

SLEEP_INTERVAL=$(tmux show-option -gqv @tmux-fetch-sleep)
SLEEP_INTERVAL=${SLEEP_INTERVAL:-3}

while true; do

    path="$(tmux display-message -p "#{pane_current_path}")"

    if [[ -n "$path" ]]; then
        check_git "$path"
    fi

    sleep "$SLEEP_INTERVAL"

done
