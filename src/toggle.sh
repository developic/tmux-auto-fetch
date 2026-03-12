#!/usr/bin/env bash

# Ensure whitelist file exists
mkdir -p "$cfg"
touch "$wl"

toggle() {

    # If inside a git repo, get top-level folder
    if git -C $path rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        path=$(git -C $path rev-parse --show-toplevel)
    fi

    # Toggle whitelist
    if grep -Fxq $path $wl; then
        grep -Fxv $path $wl > $wl.tmp
        mv $wl.tmp $wl
        tmux display-message "Auto-git enabled for $path"
    else
        echo $path >> $wl
        tmux display-message "Auto-git disabled (whitelisted) for $path"
    fi
}

# Support -w option for toggle
[[ $1 == -w ]] && toggle $2 && exit