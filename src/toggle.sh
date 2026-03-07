#!/usr/bin/env bash

cfg="$HOME/.config/tmux"
wl="$cfg/whitelist"
mkdir -p "$cfg"
touch "$wl"

toggle() {
    local path="$1"
    if grep -Fxq "$path" "$wl"; then
        grep -Fxv "$path" "$wl" > "$wl.tmp"
        mv "$wl.tmp" "$wl"
        tmux display-message "auto git enabled for this project"
    else
        echo "$path" >> "$wl"
        tmux display-message "auto git disabled (whitelisted)"
    fi
}

[[ "$1" == "-w" ]] && toggle "$2" && exit
