export ZSH="$HOME/.oh-my-zsh"
export PATH="$HOME/dotfiles/scripts:$PATH"

ZSH_THEME="kafeitu"

plugins=(git zsh-autosuggestions sudo zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh

export OPENCV_LOG_LEVEL=ERROR
fastfetch

alias ls="lsd"
alias cat="bat"
alias work="cd ~/Documents/work"
alias update="yay -Syu && flatpak update"
alias purge="yay -Qdtq | paru -R - && flatpak uninstall --unused"
alias vim="nvim"

bindkey -s '^F' tmux-sessionizer^M

# bun completions
[ -s "/home/yasai/.bun/_bun" ] && source "/home/yasai/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

export PATH=$PATH:/home/yasai/.spicetify
export PATH=/home/yasai/.local/bin:/home/yasai/.bun/bin:/home/yasai/dotfiles/scripts:/usr/local/sbin:/usr/local/bin:/usr/bin:/usr/bin/site_perl:/usr/bin/vendor_perl:/usr/bin/core_perl:/home/yasai/.spicetify
