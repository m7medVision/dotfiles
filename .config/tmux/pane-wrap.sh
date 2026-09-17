#!/bin/sh
# pane-wrap.sh — single pane step with edge wrap-around.
# Usage: pane-wrap.sh L|R|U|D <pane-id>
#   Interior: one step in the requested direction.
#   At edge:  sweep to the far edge of the same row/column.
# All tmux calls carry an explicit target so the script behaves the same
# from a key binding, run-shell -t, or a plain shell.
set -u

dir=${1:?direction L/R/U/D required}
pane=${2:?pane id required}
case $dir in
  L) at='#{pane_at_left}'   step=L sweep=R done_at='#{pane_at_right}'  ;;
  R) at='#{pane_at_right}'  step=R sweep=L done_at='#{pane_at_left}'   ;;
  U) at='#{pane_at_top}'    step=U sweep=D done_at='#{pane_at_bottom}' ;;
  D) at='#{pane_at_bottom}' step=D sweep=U done_at='#{pane_at_top}'    ;;
  *) echo "pane-wrap.sh: bad direction '$dir'" >&2; exit 1 ;;
esac

if [ "$(tmux display-message -t "$pane" -p "$at")" = 1 ]; then
  win=$(tmux display-message -t "$pane" -p '#{session_name}:#{window_index}')
  cur=$pane
  i=0
  while [ "$i" -lt 20 ]; do
    tmux select-pane -t "$cur" -"$sweep" >/dev/null 2>&1 || break
    cur=$(tmux display-message -t "$win" -p '#{pane_id}')
    i=$((i + 1))
    [ "$(tmux display-message -t "$cur" -p "$done_at")" = 1 ] && break
  done
else
  tmux select-pane -t "$pane" -"$step"
fi
