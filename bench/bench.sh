#!/usr/bin/env bash
# Times navigation and swap against a throwaway tmux server.
# usage: [RUNS=50] bench/bench.sh [git ref ...]   (defaults to the working tree)
set -euo pipefail
here=$(dirname "$(realpath "$0")")
repo=$(dirname "$here")

tmux -L tmuxnvim-bench kill-server 2>/dev/null || true
tmux -L tmuxnvim-bench new-session -d -x 200 -y 50
tmux -L tmuxnvim-bench split-window -h
sock=$(tmux -L tmuxnvim-bench display-message -p '#{socket_path}')
trap 'tmux -L tmuxnvim-bench kill-server' EXIT

run() {
    echo "== $1"
    TMUX="$sock,1,0" TMUX_PANE=%0 nvim --headless -u NONE -l "$here/bench.lua" "$2" "${RUNS:-50}" 2>&1
}

if [ $# -eq 0 ]; then
    run "working tree" "$repo"
fi
for ref in "$@"; do
    dir=$(mktemp -d)
    git -C "$repo" worktree add -q --detach "$dir" "$ref"
    run "$ref" "$dir"
    git -C "$repo" worktree remove --force "$dir"
done
