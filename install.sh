#!/usr/bin/env bash

# clone or update the repositoy m7medVision/dotfiles
function clone_or_update() {
  if [ -d "$HOME/dotfiles" ]; then
    echo "Updating dotfiles..."
    cd $HOME/dotfiles
    git pull
  else
    echo "Cloning dotfiles..."
    git clone
}

function main() {
  clone_or_update
}
