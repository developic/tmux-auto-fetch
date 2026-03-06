set -g @auto_fetch_interval 300

run-shell -b "while true; do ~/.tmux/plugins/tmux-auto-fetch/auto-fetch.sh; sleep #{@auto_fetch_interval}; done"
