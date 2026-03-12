#!/usr/bin/env bash

toggle_option="@toggle-key"
default_toggle_key="C-w"

set_toggle_binding() {
    local key
    key=$(tmux show-option -gqv "$toggle_option")
    key=${key:-$default_toggle_key}

    tmux bind-key "$key" run-shell "$CURRENT_DIR/tmux-auto-fetch.tmux -w"
}

