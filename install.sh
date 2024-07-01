#!/usr/bin/env sh

# clone or update the repositoy m7medVision/dotfiles
clone_or_update() {
  if [ -d "$HOME/dotfiles" ]; then
    echo "Updating dotfiles..."
    cd $HOME/dotfiles
    git pull
  else
    echo "Cloning dotfiles..."
    git clone https://github.com/m7medVision/dotfiles.git $HOME/dotfiles
    stow -d $HOME/dotfiles -t $HOME -S bash
  fi
}

function main() {
  clone_or_update
}
