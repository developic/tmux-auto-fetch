declare -A LAST_COMMITS

check_git() {
    local path="$1"

    # skip whitelist repos
    if [[ -f "$wl" ]] && grep -Fxq "$path" "$wl"; then
        return
    fi

    # ensure valid repo
    git -C "$path" rev-parse --is-inside-work-tree >/dev/null 2>&1 || return
    git -C "$path" rev-parse "@{u}" >/dev/null 2>&1 || return

    # fetch updates safely
    if command -v timeout >/dev/null; then
        timeout 5 git -C "$path" fetch --quiet >/dev/null 2>&1 || return
    else
        git -C "$path" fetch --quiet >/dev/null 2>&1 || return
    fi

    local commits
    commits=$(git -C "$path" rev-list HEAD..@{u} --count 2>/dev/null) || return
    [[ "$commits" -eq 0 ]] && return

    local last_commits="${LAST_COMMITS[$path]:-0}"
    [[ "$commits" -le "$last_commits" ]] && return
    LAST_COMMITS["$path"]="$commits"

    tmux display-message "git remote has [↑ $commits] new commit(s)\nPull updates? (y/n)"

    read -rsn1 key
    if [[ "$key" == "y" ]]; then

        if [[ -n $(git -C "$path" status --porcelain 2>/dev/null) ]]; then
            tmux display-message "Git pull blocked: unstaged changes present"
            return
        fi

        local branch
        branch=$(git -C "$path" branch --show-current)
        [[ -z "$branch" ]] && return

        local before after out st

        before=$(git -C "$path" rev-parse HEAD)

        out=$(git -C "$path" pull --rebase origin "$branch" 2>&1)
        st=$?

        after=$(git -C "$path" rev-parse HEAD)

        if [[ "$st" -eq 0 ]]; then
            if [[ "$before" == "$after" ]]; then
                tmux display-message "Repository already up to date"
            else
                tmux display-message "Repository updated successfully"
                LAST_COMMITS["$path"]=0
            fi
        else

            tmux display-popup -E bash -c "
cd \"$path\" || exit

printf '\nGit pull failed\n\n'
echo \"$out\"

printf '\nOptions:\n'
printf 'r retry pull\n'
printf 'c check incoming commits\n'
printf 't accept remote version\n'
printf 'l keep local version\n'
printf 's stash then pull\n'
printf 'x exit\n\n'

read -rsn1 opt

case \$opt in
r)
    git pull --rebase
    ;;
c)
    git --no-pager log HEAD..@{u}
    ;;
t)
    git checkout --theirs -- .
    git add .
    git rebase --continue 2>/dev/null
    ;;
l)
    git checkout --ours -- .
    git add .
    git rebase --continue 2>/dev/null
    ;;
s)
    git stash
    git pull --rebase
    git stash pop
    ;;
x)
    :
    ;;
esac

printf '\nPress any key to close...'
read -rsn1
"
        fi

    else
        tmux display-message "Pull skipped"
    fi
}
