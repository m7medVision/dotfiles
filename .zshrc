export ZSH="$HOME/.oh-my-zsh"
plugins=(git starship)

source $ZSH/oh-my-zsh.sh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
export PATH="$HOME/.dotnet:$PATH"
export PATH="$PATH:$HOME/.dotnet/tools"
export PATH="/home/mohammed/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/mohammed/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"

[ -s "/home/mohammed/.bun/_bun" ] && source "/home/mohammed/.bun/_bun"

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

. "$HOME/.local/bin/env"

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/home/mohammed/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/home/mohammed/anaconda3/etc/profile.d/conda.sh" ]; then
        . "/home/mohammed/anaconda3/etc/profile.d/conda.sh"
    else
        export PATH="/home/mohammed/anaconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

