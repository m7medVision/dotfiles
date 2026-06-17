#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# session-switcher.sh
# A tmux session switcher with inline creation of new sessions and
# git worktrees, plus session cleanup.
#
# Launched by the  prefix + s  binding in .tmux.conf.
#
# Inside the popup:
#   enter    → switch to the selected session
#   ctrl-x   → kill the selected session (asks before removing a worktree)
#   ctrl-n   → create a new session (prompts for a name)
#   ctrl-w   → create a git worktree + a session cd'ing into it
#   esc      → cancel
#
# Why the two-step design: `tmux switch-client` issued from *inside*
# `display-popup -E` is unreliable. So the popup only records the chosen
# target in $TARGET_FILE; the actual switch runs from main() once the
# popup has closed (the reliable run-shell context).
# ─────────────────────────────────────────────────────────────────────
set -uo pipefail

SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

# ── Entry point: open the popup, then switch once it closes ─────────-
main() {
  local pane_path target_file
  pane_path="$(tmux display -p '#{pane_current_path}')"
  target_file="$(mktemp "${TMPDIR:-/tmp}/tmux-switch.XXXXXX")"

  tmux display-popup -E \
    -e "PANE_PATH=$pane_path" \
    -e "TARGET_FILE=$target_file" \
    -w 80% -h 70% -b rounded \
    -T " tmux sessions " \
    "$SELF menu"

  # Popup is closed now — perform the deferred switch from this (reliable) context.
  if [ -s "$target_file" ]; then
    local target
    target="$(head -n1 "$target_file")"
    if [ -n "$target" ] && tmux has-session -t "$target" 2>/dev/null; then
      tmux switch-client -t "$target"
    fi
  fi
  rm -f "$target_file"
}

# ── Popup body: the interactive menu (loops so kills refresh the list) ─
run_menu() {
  local pane_path="${PANE_PATH:-$PWD}"

  local in_repo=""
  if git -C "$pane_path" rev-parse --is-inside-work-tree &>/dev/null; then
    in_repo=1
  fi

  while :; do
    local sessions header out key sel
    sessions="$(tmux list-sessions -F '#{session_name}' 2>/dev/null || true)"

    header=" enter: switch  |  ctrl-x: kill  |  ctrl-n: new session"
    [ -n "$in_repo" ] && header="$header  |  ctrl-w: worktree"

    # Feed sessions to fzf (nothing when there are none, so no blank phantom row).
    out="$( { [ -n "$sessions" ] && printf '%s\n' "$sessions"; } \
      | fzf --expect=enter,ctrl-n,ctrl-w,ctrl-x \
            --header="$header" \
            --reverse --info=inline \
            --prompt="session> " \
            --preview 'tmux list-windows -t {} -F "#{window_index}: #{window_name}  [#{pane_current_path}]" 2>/dev/null' \
            --preview-window='right,55%,border-left' )" || true

    key="$(printf '%s' "$out" | head -n1)"
    sel="$(printf '%s' "$out" | sed -n '2p')"
    sel="${sel%$'\r'}"

    case "$key" in
      enter)  [ -n "$sel" ] && { switch_to "$sel"; return; } ;;
      ctrl-n) new_session "$pane_path"; return ;;
      ctrl-w) if [ -n "$in_repo" ]; then new_worktree "$pane_path"; return; fi ;;
      ctrl-x) [ -n "$sel" ] && kill_session "$sel"; continue ;;  # refresh the list
      *)      return ;;  # cancelled (Esc / Ctrl-C)
    esac
  done
}

# ── Actions ─────────────────────────────────────────────────────────

# Record a session to switch to once the popup closes (see main()).
request_switch() {
  printf '%s\n' "$1" > "${TARGET_FILE:-/dev/null}"
}

switch_to() {
  request_switch "$1"
}

new_session() {
  local pane_path="$1" default name
  default="$(basename "$pane_path")"

  name="$(prompt_text "new session name> " "$default")"
  name="${name%%$'\n'*}"
  [ -z "$name" ] && return 0

  tmux has-session -t "$name" 2>/dev/null || tmux new-session -d -s "$name" -c "$pane_path"
  request_switch "$name"
}

new_worktree() {
  local pane_path="$1" repo_root repo_name
  repo_root="$(git -C "$pane_path" rev-parse --show-toplevel 2>/dev/null)"
  if [ -z "$repo_root" ]; then
    fail "Not inside a git repository."
    return 1
  fi
  repo_name="$(basename "$repo_root")"

  local branch
  branch="$(pick_branch "$repo_root")"
  branch="${branch%%$'\n'*}"
  [ -z "$branch" ] && return 0

  local safe_branch="${branch//\//-}"
  local wt_path="$repo_root/.worktrees/$safe_branch"
  local session_name="${repo_name}-${safe_branch}"

  # Keep the repo status clean: make sure .worktrees/ is ignored.
  ensure_worktrees_ignored "$repo_root"

  if [ ! -d "$wt_path" ]; then
    # If the branch is already checked out (e.g. the main worktree on `main`),
    # don't error — just open a session in that existing worktree.
    local existing
    existing="$(worktree_for_branch "$repo_root" "$branch")"
    if [ -n "$existing" ]; then
      wt_path="$existing"
    elif git -C "$repo_root" show-ref --verify --quiet "refs/heads/$branch"; then
      git -C "$repo_root" worktree add "$wt_path" "$branch" \
        || { fail "git worktree add failed."; return 1; }
    elif git -C "$repo_root" show-ref --verify --quiet "refs/remotes/origin/$branch"; then
      git -C "$repo_root" worktree add -b "$branch" "$wt_path" "origin/$branch" \
        || { fail "git worktree add failed."; return 1; }
    else
      git -C "$repo_root" worktree add -b "$branch" "$wt_path" \
        || { fail "git worktree add failed."; return 1; }
    fi
  fi

  tmux has-session -t "$session_name" 2>/dev/null \
    || tmux new-session -d -s "$session_name" -c "$wt_path"
  request_switch "$session_name"
}

# Kill a session; if it lives in a linked git worktree, ask whether to
# remove the worktree too. The session is always killed either way.
kill_session() {
  local sess="$1"

  local current
  current="$(tmux display -p '#{client_session}' 2>/dev/null)"
  if [ "$sess" = "$current" ]; then
    fail "Can't kill the session you're attached to — switch away first."
    return 1
  fi

  local sdir wt_top=""
  sdir="$(tmux display -t "$sess" -p '#{pane_current_path}' 2>/dev/null)"
  if [ -n "$sdir" ] && git -C "$sdir" rev-parse --is-inside-work-tree &>/dev/null; then
    wt_top="$(git -C "$sdir" rev-parse --show-toplevel 2>/dev/null)"
    # A *linked* worktree has a `.git` FILE (the main worktree has a `.git` dir).
    [ -f "$wt_top/.git" ] || wt_top=""
  fi

  if [ -n "$wt_top" ]; then
    if confirm "Also remove worktree '$wt_top'? (session is killed regardless)"; then
      if git -C "$wt_top" worktree remove "$wt_top" 2>/dev/null; then
        :
      else
        fail "Worktree has changes — left on disk. Remove manually with --force."
      fi
    fi
  fi

  tmux kill-session -t "$sess" 2>/dev/null || fail "Failed to kill '$sess'."
}

# ── Helpers ─────────────────────────────────────────────────────────

# fzf-based freeform text input (typed query is returned).
prompt_text() {
  local prompt="$1" default="${2:-}" out
  out="$(printf '' | fzf --print-query --query="$default" \
          --prompt="$prompt" --reverse --info=hidden --height=3 2>/dev/null)" || true
  printf '%s' "$(printf '%s' "$out" | head -n1)"
}

# Tiny yes/no confirm (defaults to "no", the safe choice).
confirm() {
  local prompt="$1" choice
  choice="$(printf 'no\nyes\n' \
    | fzf --prompt="$prompt " --reverse --info=hidden --height=5 2>/dev/null)" || true
  [ "$choice" = "yes" ]
}

# Pick an existing branch or type a new one. Filters out the bogus
# `origin` (origin/HEAD symref) and `HEAD` entries.
pick_branch() {
  local repo_root="$1" branches out query sel
  branches="$(git -C "$repo_root" branch --all --format='%(refname:short)' 2>/dev/null \
    | sed 's#^origin/##' | grep -vxE 'origin|HEAD' | sort -u)"

  out="$( { [ -n "$branches" ] && printf '%s\n' "$branches"; } \
    | fzf --print-query \
          --prompt="branch (new or existing)> " \
          --header=" type a new branch name, or pick an existing one " \
          --reverse --info=inline 2>/dev/null)" || true

  query="$(printf '%s' "$out" | head -n1)"
  sel="$(printf '%s' "$out" | sed -n '2p')"
  printf '%s' "${sel:-$query}"
}

# Return the path of the worktree that has $branch checked out, if any.
worktree_for_branch() {
  local repo_root="$1" branch="$2"
  git -C "$repo_root" worktree list --porcelain 2>/dev/null | awk -v b="refs/heads/$branch" '
    /^worktree / { wt = substr($0, 10) }
    /^branch /   { if (substr($0, 8) == b) { print wt; exit } }
  '
}

# Make sure the repo ignores .worktrees/ (appended only once).
ensure_worktrees_ignored() {
  local repo_root="$1" gi="$1/.gitignore"
  if [ -f "$gi" ] && grep -qxF '.worktrees/' "$gi"; then
    return 0
  fi
  {
    # Add a separating newline if the file lacks a trailing one.
    [ -s "$gi" ] && [ -n "$(tail -c1 "$gi" 2>/dev/null)" ] && printf '\n'
    printf '.worktrees/\n'
  } >> "$gi"
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
