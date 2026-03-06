#!/usr/bin/env bash

pane_path=$(tmux display-message -p "#{pane_current_path}")
whitelist="$HOME/.config/tmux/whitelist"

# create directory only if it does not exist
if [ ! -d "$(dirname "$whitelist")" ]; then
    mkdir -p "$(dirname "$whitelist")"
fi

# create whitelist file if missing
[ -f "$whitelist" ] || touch "$whitelist"

toggle_whitelist() {
    if grep -Fxq "$pane_path" "$whitelist"; then
        grep -Fxv "$pane_path" "$whitelist" > "$whitelist.tmp"
        mv "$whitelist.tmp" "$whitelist"
        tmux display-message "git auto-check disabled for $pane_path"
    else
        echo "$pane_path" >> "$whitelist"
        tmux display-message "git auto-check enabled for $pane_path"
    fi
}

# whitelist toggle mode
if [ "$1" = "-w" ]; then
    toggle_whitelist
    exit 0
fi

if ! grep -Fxq "$pane_path" "$whitelist"; then
    exit 0
fi

# check if directory is a git repo
if [ ! -d "$pane_path/.git" ]; then
    exit 0
fi

cd "$pane_path" || exit 0

git fetch --quiet

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null)

if [ "$LOCAL" != "$REMOTE" ]; then

    tmux display-message "⚠ git remote has new commits. consider pulling."

    answer=$(tmux display-popup -E "bash -c '
echo
echo \"remote repository has new commits\"
echo
echo \"pull updates? (y/n)\"
echo
read -rsn1 key
echo \$key
'")

    if [ "$answer" = "y" ]; then

        pull_output=$(git pull --rebase 2>&1)
        pull_status=$?

        if [ $pull_status -eq 0 ]; then
            tmux display-message "repository updated successfully"
        else

            tmux display-popup -E "bash -c '
echo \"git pull failed\"
echo
echo \"$pull_output\"
echo
echo \"resolution options:\"
echo \"r retry pull\"
echo \"c check incoming commits\"
echo \"t accept remote version\"
echo \"l keep local version\"
echo \"s stash changes then pull\"
echo \"x exit\"
echo
read -rsn1 key

case \"\$key\" in
r)
    git pull --rebase
    ;;
c)
    tmux display-popup -E \"bash -c \\\"git --no-pager log HEAD..@{u}; echo; read -n1\\\"\"
    ;;
t)
    git checkout --theirs .
    git add .
    git rebase --continue
    tmux display-message \"used remote version\"
    ;;
l)
    git checkout --ours .
    git add .
    git rebase --continue
    tmux display-message \"kept local version\"
    ;;
s)
    git stash
    git pull --rebase
    git stash pop
    tmux display-message \"pulled after stashing\"
    ;;
x)
    ;;
esac
'"
        fi
    fi
fi
