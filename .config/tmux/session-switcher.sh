#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# session-switcher.sh
# A tmux session switcher with inline creation of new sessions and
# git worktrees.
#
# Launched by the  prefix + s  binding in .tmux.conf.
#
# Inside the popup:
#   enter    → switch to the selected session
#   ctrl-n   → create a new session (prompts for a name)
#   ctrl-w   → create a git worktree + a session cd'ing into it
# ─────────────────────────────────────────────────────────────────────
set -uo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# ── Entry point: open the popup ──────────────────────────────────────
main() {
  local pane_path
  pane_path="$(tmux display -p '#{pane_current_path}')"
  tmux display-popup -E \
    -e "PANE_PATH=$pane_path" \
    -w 80% -h 70% -b rounded \
    -T " tmux sessions " \
    "$SELF menu"
}

# ── Popup body: the interactive menu ────────────────────────────────
run_menu() {
  local pane_path="${PANE_PATH:-$PWD}"

  local sessions in_repo header
  sessions="$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)"

  # Enable ctrl-w only when the pane lives inside a git repo
  if git -C "$pane_path" rev-parse --show-toplevel &>/dev/null; then
    in_repo=1
  fi

  header=" > enter: switch  |  ctrl-n: new session"
  [ -n "$in_repo" ] && header="$header  |  ctrl-w: worktree + session"
  header="$header "

  local out key sel
  out="$(printf '%s\n' "$sessions" \
    | fzf --expect=enter,ctrl-n,ctrl-w \
          --header="$header" \
          --reverse --info=inline \
          --prompt="session> " \
          --height=100%)" || true

  key="$(printf '%s' "$out" | head -n1)"
  sel="$(printf '%s' "$out" | tail -n +2 | head -n1)"

  case "$key" in
    enter)    [ -n "$sel" ] && switch_to "$sel" ;;
    ctrl-n)   new_session "$pane_path" ;;
    ctrl-w)   [ -n "$in_repo" ] && new_worktree "$pane_path" ;;
    *)        ;;  # cancelled
  esac
}

# ── Actions ─────────────────────────────────────────────────────────

switch_to() {
  tmux switch-client -t "$1"
}

new_session() {
  local pane_path="$1"
  local default name
  default="$(basename "$pane_path")"

  name="$(prompt_text "new session name> " "$default")"
  [ -z "$name" ] && return 0

  if tmux has-session -t "$name" 2>/dev/null; then
    tmux switch-client -t "$name"
  else
    tmux new-session -d -s "$name" -c "$pane_path"
    tmux switch-client -t "$name"
  fi
}

new_worktree() {
  local pane_path="$1"
  local repo_root repo_name
  repo_root="$(git -C "$pane_path" rev-parse --show-toplevel 2>/dev/null)"
  if [ -z "$repo_root" ]; then
    fail "Not inside a git repository."
    return 1
  fi
  repo_name="$(basename "$repo_root")"

  local branch
  branch="$(pick_branch "$repo_root")" || return 1
  [ -z "$branch" ] && return 0

  # Sanitize branch name for use as a path / session suffix
  local safe_branch="${branch//\//-}"
  local wt_path="$repo_root/.worktrees/$safe_branch"
  local session_name="${repo_name}-${safe_branch}"

  # Create the worktree (or reuse if it already exists)
  if [ ! -d "$wt_path" ]; then
    if git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
      git -C "$repo_root" worktree add "$wt_path" "$branch" || { fail "git worktree add failed."; return 1; }
    elif git -C "$repo_root" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      git -C "$repo_root" worktree add -b "$branch" "$wt_path" "origin/$branch" || { fail "git worktree add failed."; return 1; }
    else
      git -C "$repo_root" worktree add -b "$branch" "$wt_path" || { fail "git worktree add failed."; return 1; }
    fi
  fi

  # Create the session (or reuse) and cd into the worktree
  if tmux has-session -t "$session_name" 2>/dev/null; then
    tmux switch-client -t "$session_name"
  else
    tmux new-session -d -s "$session_name" -c "$wt_path"
    tmux switch-client -t "$session_name"
  fi
}

# ── Helpers ─────────────────────────────────────────────────────────

# fzf-based freeform text input (typed query is returned).
prompt_text() {
  local prompt="$1" default="${2:-}" out
  out="$(printf '\n' | fzf --print-query --query="$default" \
          --prompt="$prompt" --reverse --info=hidden --height=3 2>/dev/null)" || true
  printf '%s' "$(printf '%s' "$out" | head -n1)"
}

# Pick an existing branch or type a new one.
pick_branch() {
  local repo_root="$1" branches out query sel
  branches="$(git -C "$repo_root" branch --all --format='%(refname:short)' 2>/dev/null \
    | sed 's#^origin/##' | sort -u)"

  out="$(printf '%s\n' "$branches" \
    | fzf --print-query \
          --prompt="branch (new or existing)> " \
          --header=" type a new branch or pick an existing one " \
          --reverse --info=inline --height=100% 2>/dev/null)" || true

  query="$(printf '%s' "$out" | head -n1)"
  sel="$(printf '%s' "$out" | tail -n +2 | head -n1)"
  printf '%s' "${sel:-$query}"
}

# Show an error and keep it visible briefly before the popup closes.
fail() {
  printf '\033[31m%s\033[0m\n' "$1" >&2
  sleep 1.2
}

# ── Dispatch ────────────────────────────────────────────────────────
case "${1:-}" in
  menu) run_menu ;;
  *)    main ;;
esac
