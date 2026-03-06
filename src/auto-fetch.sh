#!/usr/bin/env bash

pane_path=$(tmux display-message -p "#{pane_current_path}")
whitelist="$HOME/.config/tmux/git-auto-whitelist"

# create directory only if it does not exist
[ -d "$(dirname "$whitelist")" ] || mkdir -p "$(dirname "$whitelist")"

# create whitelist file if missing
[ -f "$whitelist" ] || touch "$whitelist"

toggle_whitelist() {
    if grep -Fxq "$pane_path" "$whitelist"; then
        grep -Fxv "$pane_path" "$whitelist" > "$whitelist.tmp"
        mv "$whitelist.tmp" "$whitelist"
        tmux display-message "auto git enabled for this project"
    else
        echo "$pane_path" >> "$whitelist"
        tmux display-message "auto git disabled (whitelisted project)"
    fi
}

# toggle mode
if [ "$1" = "-w" ]; then
    toggle_whitelist
    exit 0
fi

# skip if whitelisted
grep -Fxq "$pane_path" "$whitelist" && exit 0

# check if git repo
[ -d "$pane_path/.git" ] || exit 0

cd "$pane_path" || exit 0

git fetch --quiet

LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse @{u} 2>/dev/null)

if [ "$LOCAL" != "$REMOTE" ]; then

    tmux display-message "git remote has new commits. consider pulling."

    tmux display-popup -E "bash -c '
printf \"remote repository has new commits\n\npull updates? (y/n)\n\n\"
read -rsn1 key

if [ \"\$key\" = \"y\" ]; then

    pull_output=\$(git pull --rebase 2>&1)
    status=\$?

    if [ \$status -eq 0 ]; then
        tmux display-message \"repository updated successfully\"
    else

        printf \"git pull failed\n\n\"
        echo \"\$pull_output\"
        printf \"\nresolution options:\n\"
        printf \"r retry pull\n\"
        printf \"c check incoming commits\n\"
        printf \"t accept remote version\n\"
        printf \"l keep local version\n\"
        printf \"s stash changes then pull\n\"
        printf \"x exit\n\n\"

        read -rsn1 opt

        case \"\$opt\" in
        r)
            git pull --rebase
        ;;
        c)
            git --no-pager log HEAD..@{u}
            read -n1
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

    fi

else
    tmux display-message \"pull skipped\"
fi
'"
fi