if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Oh My Zsh not found. Installing..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installation complete."
fi

export ZSH="$HOME/.oh-my-zsh"
export PATH="$PATH:/home/mohammed/.dotnet/tools"
export DISABLE_AUTO_TITLE='true'
ZSH_THEME="robbyrussell"
plugins=(git npm node docker zoxide bun uv dotnet command-not-found golang)
source $ZSH/oh-my-zsh.sh
alias zshconfig="source ~/.zshrc"
alias v="nvim"
alias lg="lazygit"
alias ld="lazydocker"
alias lcfzf="lazycommit commit | fzf --prompt='Pick commit> ' | xargs -r -I {} git commit -m \"{}\" "
alias oh="sh ~/dotfiles/.config/Scripts/toggle-omo.sh"
alias venv=source venv/bin/activate
export PATH="/home/mohammed/.config/herd-lite/bin:$PATH"
export PHP_INI_SCAN_DIR="/home/mohammed/.config/herd-lite/bin:$PHP_INI_SCAN_DIR"
alias open="xdg-open"
alias l="eza -l --icons --git -a"
alias lt="eza --tree --level=2 --long --icons --git"
alias ltree="eza --tree --level=2  --icons --git"
alias oc=opencode

# ── Arabic / RTL ──────────────────────────────────────────────────────
# Plain kitty gets single WORDS right but leaves sentence word order logical.
# For full sentences you need a Mode B window (force_ltr yes) + fribidi:
alias kar='kitty --config ~/.config/kitty/arabic-rtl.conf'

# fribidi emits visually-ordered text. A plain kitty window reverses RTL runs
# itself and would undo that, so warn instead of silently printing garbage.
# (foot does no reordering at all, so it is fine there.)
_rtl_filter() {
  if [[ -n "$KITTY_WINDOW_ID" && -z "$KITTY_BIDI" ]]; then
    print -u2 "rtl: plain kitty re-reverses this — run 'kar' for a Mode B window."
  fi
  fribidi --nopad "$@"
}
rtl() { _rtl_filter "$@" }                  # rtl notes.ar
alias -g R='| _rtl_filter'                  # git log R
export EDITOR="nvim"

export GOPATH=$HOME/go
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

[ -s "/home/mohammed/.bun/_bun" ] && source "/home/mohammed/.bun/_bun"


export PATH="$PATH:$HOME/.cargo/bin"

_direnv_hook() {
  trap -- '' SIGINT
  eval "$("/usr/bin/direnv" export zsh)"
  trap - SIGINT
}
typeset -ag precmd_functions
if (( ! ${precmd_functions[(I)_direnv_hook]} )); then
  precmd_functions=(_direnv_hook $precmd_functions)
fi
typeset -ag chpwd_functions
if (( ! ${chpwd_functions[(I)_direnv_hook]} )); then
  chpwd_functions=(_direnv_hook $chpwd_functions)
fi

export PATH="$HOME/.local/bin:$PATH"

# strix
export PATH=/home/mohammed/.strix/bin:$PATH
