# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.

fastfetch

if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

export ZSH="$HOME/.oh-my-zsh"
export MAIL="bautrodr@student.42barcelona.com"

ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=( 
    git
    archlinux
    zsh-autosuggestions
    zsh-syntax-highlighting
	zsh-vi-mode
)

[[ -r ~/.config/znap/znap.zsh ]] ||
    git clone --depth 1 -- \
        https://github.com/marlonrichert/zsh-snap.git ~/.config/znap
source ~/.config/znap/znap.zsh  # Start Znap


source $ZSH/oh-my-zsh.sh

#alias
alias ls=lsd
alias tetris="sudo pacman"
alias "sudo tetris"="sudo pacman"
alias open="~/.local/bin/open.sh"

eval $(thefuck --alias)
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
export DEBUGINFOD_URLS=https://debuginfod.archlinux.org
export PATH=:/home/tuta/.local/bin:$PATH
export PATH=:/home/tuta/.local/share/pipx/shared/bin/:$PATH
export PATH=:/home/tuta/.cargo/bin/:$PATH
