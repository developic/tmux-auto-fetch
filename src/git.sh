#!/usr/bin/env bash

check_git() {
    local path="$1"

    # Ensure inside a git repo with upstream
    git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
    git -C "$path" rev-parse "@{u}" >/dev/null 2>&1 || return

    # Fetch remote changes quietly
    git -C "$path" fetch --quiet
    local commits
    commits=$(git -C "$path" rev-list HEAD..@{u} --count)
    [[ "$commits" -eq 0 ]] && return

    # Detect unstaged changes
    if [[ -n $(git -C "$path" status --porcelain) ]]; then
        tmux display-message "⚠️ Git pull blocked: unstaged changes present. Remote has [↑ $commits] new commit(s)."
        return
    fi

    # Show remote commits and prompt in tmux display-message
    tmux display-message "Git remote has [↑ $commits] new commit(s). Pull updates? (y/n)"

    # Popup: just handle the pull and conflicts, no repeated prompt
    tmux display-popup -E bash -c "
cd \"$path\" || exit

# Perform pull
before=\$(git rev-parse HEAD)
out=\$(git pull --rebase 2>&1)
st=\$?
after=\$(git rev-parse HEAD)

if [[ \$st -eq 0 ]]; then
    if [[ \"\$before\" == \"\$after\" ]]; then
        tmux display-message 'Repository already up to date'
    else
        tmux display-message 'Repository updated successfully'
    fi
else
    printf '\nGit pull failed\n\n'
    echo \"\$out\"
    printf '\nOptions:\n'
    printf 'r retry pull\n'
    printf 'c check incoming commits\n'
    printf 't accept remote version\n'
    printf 'l keep local version\n'
    printf 's stash then pull\n'
    printf 'x exit\n\n'

    read -rsn1 opt
    case \$opt in
        r) git pull --rebase ;;
        c) git --no-pager log HEAD..@{u}; read -n1 ;;
        t) git checkout --theirs .; git add .; git rebase --continue; tmux display-message 'Used remote version' ;;
        l) git checkout --ours .; git add .; git rebase --continue; tmux display-message 'Kept local version' ;;
        s) git stash; git pull --rebase; git stash pop; tmux display-message 'Pulled after stashing' ;;
        x) : ;;
    esac
fi
"
}