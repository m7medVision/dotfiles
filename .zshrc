export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:/home/mohammed/.dotnet/tools"
ZSH_THEME="robbyrussell"
plugins=(git)
source $ZSH/oh-my-zsh.sh
alias zshconfig="source ~/.zshrc"
alias vi="nvim"
alias vim="nvim"
alias lg="lazygit"
alias ld="lazydocker"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export PATH="/home/mohammed/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/mohammed/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
if [ -f ~/.zshenv ]; then
  source ~/.zshenv
fi
