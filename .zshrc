export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="gozilla"
source <(fzf --zsh)
source $ZSH/oh-my-zsh.sh

plugins=(git zsh-autosuggestions zsh-syntax-highlighting)


export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin


# alies for ls
alias ls='lsd'

# Created by `pipx` on 2024-10-20 21:22:45
export PATH="$PATH:/home/mohammed/.local/bin"

# bun completions
[ -s "/home/mohammed/.bun/_bun" ] && source "/home/mohammed/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
