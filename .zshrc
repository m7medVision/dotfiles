if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installation complete."
fi

export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:/home/mohammed/.dotnet/tools"
ZSH_THEME="robbyrussell"
plugins=(git npm node docker zoxide bun uv dotnet)
source $ZSH/oh-my-zsh.sh
alias zshconfig="source ~/.zshrc"
alias vi="nvim"
alias vim="nvim"
alias lg="lazygit"
alias ld="lazydocker"
alias venv=source venv/bin/activate
export PATH="/home/mohammed/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/mohammed/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
if [ -f ~/.zshenv ]; then
  source ~/.zshenv
fi
export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"
