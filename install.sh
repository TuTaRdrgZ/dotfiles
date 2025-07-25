#!/bin/bash

# TuTaRdrgZ Personal Dotfiles Setup
# Auto-setup for any Unix machine with intelligent environment detection

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Global variables
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_LIB="$HOME/.local/lib"
LOCAL_SHARE="$HOME/.local/share"
HAS_SUDO=false
NEEDS_PASSWORD=false
OS=""
ENV_TYPE=""

print_banner() {
    echo -e "${PURPLE}"
    echo "╔══════════════════════════════════════╗"
    echo "║       TuTaRdrgZ Dotfiles Setup       ║"
    echo "║                                      ║"
    echo "║     Current Date: $(date '+%Y-%m-%d')      ║"
    echo "║     User: $(printf '%-20s' "$USER")║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/arch-release ]; then
            OS="arch"
        elif [ -f /etc/debian_version ]; then
            OS="debian"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
        else
            OS="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
    else
        OS="unknown"
    fi
    log_info "Detected OS: $OS"
}

# FIXED: Better sudo detection
check_sudo_advanced() {
    local has_passwordless_sudo=false
    local can_sudo=false

    # Check if sudo command exists
    if ! command -v sudo &> /dev/null; then
        log_warning "sudo command not found"
        HAS_SUDO=false
        NEEDS_PASSWORD=false
        return 1
    fi

    # Method 1: Check passwordless sudo
    if sudo -n true 2>/dev/null; then
        has_passwordless_sudo=true
        can_sudo=true
        log_success "Passwordless sudo detected"
    fi

    # Method 2: Check sudo groups membership
    if groups "$USER" 2>/dev/null | grep -q '\(wheel\|sudo\|admin\)'; then
        can_sudo=true
        log_info "User is in sudo group"
    fi

    # Method 3: Check if we can run sudo -l (even if it asks for password)
    if ! $can_sudo; then
        # This will return 0 if user CAN sudo (even with password)
        # and 1 if user CANNOT sudo at all
        if sudo -l >/dev/null 2>&1; then
            can_sudo=true
            log_info "User can use sudo (password required)"
        elif [ $? -eq 1 ]; then
            # Exit code 1 means user needs password but CAN sudo
            can_sudo=true
            log_info "User can use sudo (password verification needed)"
        fi
    fi

    # Final determination
    if [ "$has_passwordless_sudo" = true ]; then
        HAS_SUDO=true
        NEEDS_PASSWORD=false
        log_success "Administrative privileges: passwordless sudo"
    elif [ "$can_sudo" = true ]; then
        HAS_SUDO=true
        NEEDS_PASSWORD=true
        log_success "Administrative privileges: sudo with password"
    else
        HAS_SUDO=false
        NEEDS_PASSWORD=false
        log_warning "No administrative privileges detected"

        # Create local directories
        mkdir -p "$LOCAL_BIN" "$LOCAL_LIB" "$LOCAL_SHARE"

        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
            echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc 2>/dev/null || true
            export PATH="$LOCAL_BIN:$PATH"
            log_info "Added ~/.local/bin to PATH"
        fi
    fi
}

# FIXED: Detect environment based on actual capabilities
detect_environment() {
    local env_type="unknown"

    # Priority 1: Check if we have admin privileges
    if [ "$HAS_SUDO" = true ]; then
        # We have sudo, check if it's educational or home environment
        if [[ "$PWD" == *"/nfs/homes/"* ]] || [[ "$HOME" == *"/nfs/homes/"* ]] || [ -d "/goinfre" ] || [ -d "/sgoinfre" ]; then
            env_type="educational"
            log_info "Educational environment with admin privileges"
        else
            env_type="home"
            log_info "Home environment with admin privileges"
        fi
    else
        # No sudo, check environment type
        if [[ "$PWD" == *"/nfs/homes/"* ]] || [[ "$HOME" == *"/nfs/homes/"* ]] || [ -d "/goinfre" ] || [ -d "/sgoinfre" ]; then
            env_type="educational"
            log_info "Educational environment without admin privileges"
        else
            env_type="restricted"
            log_info "Restricted environment without admin privileges"
        fi
    fi

    ENV_TYPE="$env_type"
}

# Install packages with system package manager (with password prompt)
install_system_packages_with_password() {
    log_info "Installing packages with system package manager (password may be required)..."

    case $OS in
        "arch")
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm git curl wget zsh tmux nodejs npm python python-pip fzf ripgrep fd bat exa git-delta
            ;;
        "debian")
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y git curl wget zsh tmux nodejs npm python3 python3-pip fzf ripgrep fd-find bat
            ;;
        "redhat")
            sudo dnf update -y
            sudo dnf install -y git curl wget zsh tmux nodejs npm python3 python3-pip fzf ripgrep fd-find bat
            ;;
        "macos")
            # Install Homebrew if not exists
            if ! command -v brew &> /dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git curl wget zsh tmux node python fzf ripgrep fd bat exa git-delta
            ;;
        *)
            log_error "Unsupported OS for system installation"
            return 1
            ;;
    esac

    log_success "System packages installed!"
}

# Install packages with system package manager (passwordless)
install_system_packages_passwordless() {
    log_info "Installing packages with system package manager (passwordless)..."

    case $OS in
        "arch")
            sudo pacman -Syu --noconfirm
            sudo pacman -S --noconfirm git curl wget zsh tmux nodejs npm python python-pip fzf ripgrep fd bat exa git-delta
            ;;
        "debian")
            sudo apt update && sudo apt upgrade -y
            sudo apt install -y git curl wget zsh tmux nodejs npm python3 python3-pip fzf ripgrep fd-find bat
            ;;
        "redhat")
            sudo dnf update -y
            sudo dnf install -y git curl wget zsh tmux nodejs npm python3 python3-pip fzf ripgrep fd-find bat
            ;;
        "macos")
            if ! command -v brew &> /dev/null; then
                /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            fi
            brew install git curl wget zsh tmux node python fzf ripgrep fd bat exa git-delta
            ;;
    esac

    log_success "System packages installed!"
}

# Install Neovim locally
install_neovim_local() {
    log_info "Installing Neovim locally..."

    if command -v nvim &> /dev/null; then
        log_success "Neovim already installed"
        return 0
    fi

    cd /tmp

    case $OS in
        "linux")
            # Download AppImage
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
            chmod u+x nvim.appimage
            mv nvim.appimage "$LOCAL_BIN/nvim"
            ;;
        "macos")
            # Download macOS binary
            curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-macos.tar.gz
            tar xzf nvim-macos.tar.gz
            mv nvim-macos "$LOCAL_LIB/nvim"
            ln -sf "$LOCAL_LIB/nvim/bin/nvim" "$LOCAL_BIN/nvim"
            ;;
    esac

    log_success "Neovim installed locally"
}

# Install Node.js locally using nvm
install_node_local() {
    log_info "Installing Node.js locally via nvm..."

    if command -v node &> /dev/null; then
        log_success "Node.js already installed"
        return 0
    fi

    # Install nvm
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

    # Source nvm
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # Install latest LTS node
    nvm install --lts
    nvm use --lts
    nvm alias default lts/*

    log_success "Node.js installed via nvm"
}

# Install Starship prompt locally
install_starship_local() {
    log_info "Installing Starship prompt locally..."

    if command -v starship &> /dev/null; then
        log_success "Starship already installed"
        return 0
    fi

    curl -sS https://starship.rs/install.sh | sh -s -- -b "$LOCAL_BIN" -y
    log_success "Starship installed locally"
}

# Install fzf locally
install_fzf_local() {
    log_info "Installing fzf locally..."

    if command -v fzf &> /dev/null; then
        log_success "fzf already installed"
        return 0
    fi

    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --bin
    ln -sf ~/.fzf/bin/fzf "$LOCAL_BIN/fzf"

    log_success "fzf installed locally"
}

# Install ripgrep locally
install_ripgrep_local() {
    log_info "Installing ripgrep locally..."

    if command -v rg &> /dev/null; then
        log_success "ripgrep already installed"
        return 0
    fi

    cd /tmp

    case $OS in
        "linux")
            RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -LO "https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            tar xzf "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            mv "ripgrep-${RG_VERSION}-x86_64-unknown-linux-musl/rg" "$LOCAL_BIN/"
            ;;
        "macos")
            RG_VERSION=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -LO "https://github.com/BurntSushi/ripgrep/releases/latest/download/ripgrep-${RG_VERSION}-x86_64-apple-darwin.tar.gz"
            tar xzf "ripgrep-${RG_VERSION}-x86_64-apple-darwin.tar.gz"
            mv "ripgrep-${RG_VERSION}-x86_64-apple-darwin/rg" "$LOCAL_BIN/"
            ;;
    esac

    log_success "ripgrep installed locally"
}

# Install fd locally
install_fd_local() {
    log_info "Installing fd locally..."

    if command -v fd &> /dev/null; then
        log_success "fd already installed"
        return 0
    fi

    cd /tmp

    case $OS in
        "linux")
            FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -LO "https://github.com/sharkdp/fd/releases/latest/download/fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            tar xzf "fd-${FD_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            mv "fd-${FD_VERSION}-x86_64-unknown-linux-musl/fd" "$LOCAL_BIN/"
            ;;
        "macos")
            FD_VERSION=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -LO "https://github.com/sharkdp/fd/releases/latest/download/fd-${FD_VERSION}-x86_64-apple-darwin.tar.gz"
            tar xzf "fd-${FD_VERSION}-x86_64-apple-darwin.tar.gz"
            mv "fd-${FD_VERSION}-x86_64-apple-darwin/fd" "$LOCAL_BIN/"
            ;;
    esac

    log_success "fd installed locally"
}

# Install bat locally
install_bat_local() {
    log_info "Installing bat locally..."

    if command -v bat &> /dev/null; then
        log_success "bat already installed"
        return 0
    fi

    cd /tmp

    case $OS in
        "linux")
            BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -LO "https://github.com/sharkdp/bat/releases/latest/download/bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            tar xzf "bat-${BAT_VERSION}-x86_64-unknown-linux-musl.tar.gz"
            mv "bat-${BAT_VERSION}-x86_64-unknown-linux-musl/bat" "$LOCAL_BIN/"
            ;;
        "macos")
            BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
            curl -LO "https://github.com/sharkdp/bat/releases/latest/download/bat-${BAT_VERSION}-x86_64-apple-darwin.tar.gz"
            tar xzf "bat-${BAT_VERSION}-x86_64-apple-darwin.tar.gz"
            mv "bat-${BAT_VERSION}-x86_64-apple-darwin/bat" "$LOCAL_BIN/"
            ;;
    esac

    log_success "bat installed locally"
}

# Install exa locally
install_exa_local() {
    log_info "Installing exa locally..."

    if command -v exa &> /dev/null; then
        log_success "exa already installed"
        return 0
    fi

    cd /tmp

    case $OS in
        "linux")
            curl -LO https://github.com/ogham/exa/releases/latest/download/exa-linux-x86_64-v0.10.1.zip
            unzip -q exa-linux-x86_64-v0.10.1.zip 2>/dev/null || unzip exa-linux-x86_64-v0.10.1.zip
            mv bin/exa "$LOCAL_BIN/" 2>/dev/null || mv exa-linux-x86_64 "$LOCAL_BIN/exa"
            ;;
        "macos")
            curl -LO https://github.com/ogham/exa/releases/latest/download/exa-macos-x86_64-v0.10.1.zip
            unzip -q exa-macos-x86_64-v0.10.1.zip 2>/dev/null || unzip exa-macos-x86_64-v0.10.1.zip
            mv bin/exa "$LOCAL_BIN/" 2>/dev/null || mv exa-macos-x86_64 "$LOCAL_BIN/exa"
            ;;
    esac

    log_success "exa installed locally"
}

# Install all tools locally
install_tools_local() {
    log_info "Installing tools locally (no sudo required)..."

    install_neovim_local
    install_node_local
    install_starship_local
    install_fzf_local
    install_ripgrep_local
    install_fd_local
    install_bat_local
    install_exa_local

    log_success "All tools installed locally!"
}

# FIXED: Smart package installation that actually uses sudo when available
install_packages_smart() {
    log_info "Determining optimal installation method..."
    log_info "Sudo available: $HAS_SUDO, Password needed: $NEEDS_PASSWORD"

    if [ "$HAS_SUDO" = true ]; then
        # We have sudo - use system package manager
        log_info "Using system package manager (sudo available)"
        if [ "$NEEDS_PASSWORD" = true ]; then
            echo -e "${YELLOW}This will ask for your password...${NC}"
            install_system_packages_with_password
        else
            install_system_packages_passwordless
        fi
        # Still install starship locally as some distros don't have it
        install_starship_local
    else
        # No sudo - install everything locally
        log_info "Using local installation (no sudo available)"
        install_tools_local
    fi
}

# Setup Zsh (works without sudo)
setup_zsh() {
    log_info "Setting up Zsh..."
    
    # Check if zsh is available
    if ! command -v zsh &> /dev/null; then
        log_error "Zsh not found after installation. Something went wrong."
        return 1
    fi
    
    # Install Oh My Zsh
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        log_info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    else
        log_success "Oh My Zsh already installed"
    fi
    
    # Install plugins
    ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
    
    # zsh-syntax-highlighting
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
        log_info "Installing zsh-syntax-highlighting..."
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
    else
        log_success "zsh-syntax-highlighting already installed"
    fi
    
    # zsh-autosuggestions
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
        log_info "Installing zsh-autosuggestions..."
        git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
    else
        log_success "zsh-autosuggestions already installed"
    fi
    
    # zsh-vi-mode
    if [ ! -d "$ZSH_CUSTOM/plugins/zsh-vi-mode" ]; then
        log_info "Installing zsh-vi-mode..."
        git clone https://github.com/jeffreytse/zsh-vi-mode.git $ZSH_CUSTOM/plugins/zsh-vi-mode
    else
        log_success "zsh-vi-mode already installed"
    fi
    
    # powerlevel10k theme
    if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
        log_info "Installing powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
    else
        log_success "powerlevel10k already installed"
    fi
    
    log_success "Zsh setup complete!"
}

# Setup Neovim
setup_neovim() {
    log_info "Setting up Neovim..."

    # Backup existing config
    if [ -d "$HOME/.config/nvim" ]; then
        mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%s)"
        log_warning "Backed up existing Neovim config"
    fi

    # Clone your nvim config repository
    log_info "Cloning TuTaRdrgZ nvim configuration..."
    git clone https://github.com/TuTaRdrgZ/nvim_config.git "$HOME/.config/nvim"

    if [ $? -eq 0 ]; then
        log_success "Neovim configuration cloned successfully"
    else
        log_error "Failed to clone nvim config. Creating basic setup..."
        # Fallback: create basic nvim config directory
        mkdir -p "$HOME/.config/nvim"
        cat > "$HOME/.config/nvim/init.lua" << 'EOF'
-- Basic Neovim configuration
-- Clone failed, using minimal setup

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.termguicolors = true
vim.opt.scrolloff = 8
vim.opt.signcolumn = "yes"

-- Basic key mappings
vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
EOF
        log_info "Created basic Neovim configuration as fallback"
    fi

    log_success "Neovim setup complete!"
}
# Setup Tmux
setup_tmux() {
    log_info "Setting up Tmux..."

    # Install TPM (Tmux Plugin Manager)
    if [ ! -d "$HOME/.tmux/plugins/tpm" ]; then
        git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
    fi

    log_success "Tmux setup complete!"
}

# Link dotfiles
link_dotfiles() {
    log_info "Linking dotfiles..."

    # Create basic configs if they don't exist
    mkdir -p "$DOTFILES_DIR/configs/"{zsh,tmux,git}

    # Create basic .zshrc if it doesn't exist
    if [ ! -f "$DOTFILES_DIR/configs/zsh/.zshrc" ]; then
        cat > "$DOTFILES_DIR/configs/zsh/.zshrc" << 'EOF'
# Basic Zsh configuration
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)
source $ZSH/oh-my-zsh.sh

# Load local customizations
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

# Load starship if available
if command -v starship &> /dev/null; then
    eval "$(starship init zsh)"
fi
EOF
    fi

    # Create basic .tmux.conf if it doesn't exist
    if [ ! -f "$DOTFILES_DIR/configs/tmux/.tmux.conf" ]; then
        cat > "$DOTFILES_DIR/configs/tmux/.tmux.conf" << 'EOF'
# Basic Tmux configuration
set -g prefix C-a
unbind C-b
bind C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1
set -g base-index 1
setw -g pane-base-index 1

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF
    fi

    # Create basic .gitconfig if it doesn't exist
    if [ ! -f "$DOTFILES_DIR/configs/git/.gitconfig" ]; then
        cat > "$DOTFILES_DIR/configs/git/.gitconfig" << 'EOF'
[user]
    name = TuTaRdrgZ
    email = your-email@example.com

[core]
    editor = nvim
    autocrlf = input

[init]
    defaultBranch = main

[pull]
    rebase = false
EOF
    fi

    # Link configs
    ln -sf "$DOTFILES_DIR/configs/zsh/.zshrc" "$HOME/.zshrc"
    ln -sf "$DOTFILES_DIR/configs/tmux/.tmux.conf" "$HOME/.tmux.conf"
    ln -sf "$DOTFILES_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"

    # Link nvim config if exists
    if [ -d "$DOTFILES_DIR/configs/nvim" ]; then
        ln -sf "$DOTFILES_DIR/configs/nvim" "$HOME/.config/nvim"
    fi

    log_success "Dotfiles linked!"
}

# Change shell to zsh (if possible)
change_shell() {
    if [ "$HAS_SUDO" = true ] && [ "$SHELL" != "$(which zsh)" ]; then
        log_info "Changing shell to zsh..."
        if [ "$NEEDS_PASSWORD" = true ]; then
            chsh -s $(which zsh)
        else
            sudo chsh -s $(which zsh) "$USER"
        fi
        log_success "Shell changed to zsh (restart required)"
    elif [ "$HAS_SUDO" = false ]; then
        log_warning "Cannot change shell without sudo. Adding exec zsh to shell profile"
        echo 'exec zsh' >> ~/.bashrc
        echo 'exec zsh' >> ~/.profile 2>/dev/null || true
    fi
}

# Create environment-specific configurations
setup_environment_specific() {
    log_info "Setting up environment-specific configurations..."

    case "$ENV_TYPE" in
        "educational")
            setup_educational_environment
            ;;
        "home")
            setup_home_environment
            ;;
        "restricted")
            setup_restricted_environment
            ;;
    esac
}

# Create educational environment-specific aliases and functions
setup_educational_environment() {
    log_info "Setting up educational environment configurations..."

    cat >> ~/.zshrc.local << 'EOF'
# Educational Environment Specific Configurations

# Development tools
alias norm='norminette'
alias norminette-check='norminette *.c *.h'

# Debugging tools
alias valgrind-check='valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes'
alias valgrind-simple='valgrind --leak-check=full'

# Compilation functions
c_compile() {
    gcc -Wall -Wextra -Werror -std=c99 "$@"
}

c_compile_debug() {
    gcc -Wall -Wextra -Werror -g -std=c99 "$@"
}

# Project management
project_init() {
    local project_name="$1"
    if [ -z "$project_name" ]; then
        echo "Usage: project_init <project_name>"
        return 1
    fi

    mkdir -p "$project_name"/{src,include,obj}
    touch "$project_name"/Makefile
    touch "$project_name"/README.md
    echo "# $project_name" > "$project_name"/README.md
    echo "Project structure created for $project_name"
}

# Git setup for projects
project_git_setup() {
    git init
    echo "*.o\n*.a\na.out\n.DS_Store\n*.dSYM" > .gitignore
    git add .
    git commit -m "Initial commit"
    echo "Git repository initialized"
}

# Quick project check
project_check() {
    echo "Running norminette..."
    norminette *.c *.h 2>/dev/null || echo "No .c/.h files found or norminette issues"

    echo "Checking compilation..."
    if [ -f "Makefile" ]; then
        make re
        echo "Compilation check complete!"
    else
        echo "No Makefile found"
    fi
}

# Shared storage management (if available)
alias shared='cd /goinfre/$USER 2>/dev/null || cd /sgoinfre/$USER 2>/dev/null || echo "Shared storage not available"'

# Make sure local bin is in PATH
export PATH="$HOME/.local/bin:$PATH"
EOF

    log_success "Educational environment configured!"
}

# Setup home environment
setup_home_environment() {
    log_info "Setting up home environment configurations..."

    cat >> ~/.zshrc.local << 'EOF'
# Home Environment Specific Configurations

# Development shortcuts
alias docker-clean='docker system prune -a'
alias docker-stop-all='docker stop $(docker ps -q)'
alias git-clean='git branch --merged | grep -v "\*\|main\|master" | xargs -n 1 git branch -d'

# System monitoring
alias ports='netstat -tulanp'
alias meminfo='free -m -l -t'
alias cpuinfo='lscpu'

# Package management shortcuts
if command -v pacman &> /dev/null; then
    alias update='sudo pacman -Syu'
    alias install='sudo pacman -S'
elif command -v apt &> /dev/null; then
    alias update='sudo apt update && sudo apt upgrade'
    alias install='sudo apt install'
elif command -v dnf &> /dev/null; then
    alias update='sudo dnf update'
    alias install='sudo dnf install'
fi

export PATH="$HOME/.local/bin:$PATH"
EOF

    log_success "Home environment configured!"
}

# Setup restricted environment
setup_restricted_environment() {
    log_info "Setting up restricted environment configurations..."

    cat >> ~/.zshrc.local << 'EOF'
# Restricted Environment Specific Configurations

# Safe aliases for restricted environments
alias ll='ls -la'
alias la='ls -la'

# Development helpers
alias grep='grep --color=auto'
alias diff='diff --color=auto'

# Make sure local bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Local development tools
export EDITOR='nvim'
export VISUAL='nvim'
EOF

    log_success "Restricted environment configured!"
}

# Show final status and instructions
show_final_status() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════╗"
    echo "║         Setup Complete!              ║"
    echo "║                                      ║"
    case "$ENV_TYPE" in
        "educational")
            echo "║  Perfect for educational use!        ║"
            ;;
        "home")
            echo "║  Perfect for home development!       ║"
            ;;
        *)
            echo "║  Perfect for your environment!       ║"
            ;;
    esac
    echo "║                                      ║"
    echo "║  Next steps:                         ║"
    echo "║  1. Restart your terminal            ║"
    echo "║     OR run: source ~/.zshrc          ║"
    echo "║  2. Run: tmux                        ║"
    echo "║  3. Enjoy your setup!                ║"
    echo "║                                      ║"
    if [ "$HAS_SUDO" = false ]; then
        echo "║  Note: Tools installed in:           ║"
        echo "║  ~/.local/bin (already in PATH)      ║"
        echo "║                                      ║"
    fi
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"

    # Show installed tools
    echo -e "${CYAN}Installed tools:${NC}"
    command -v nvim >/dev/null && echo "Neovim: $(nvim --version | head -n1)"
    command -v node >/dev/null && echo "Node.js: $(node --version)"
    command -v tmux >/dev/null && echo "Tmux: $(tmux -V)"
    command -v fzf >/dev/null && echo "fzf: $(fzf --version)"
    command -v rg >/dev/null && echo "ripgrep: $(rg --version | head -n1)"
    command -v fd >/dev/null && echo "fd: $(fd --version)"
    command -v bat >/dev/null && echo "bat: $(bat --version)"
    command -v exa >/dev/null && echo "exa: $(exa --version)"
    command -v starship >/dev/null && echo "starship: $(starship --version)"
    command -v zsh >/dev/null && echo "zsh: $(zsh --version)"
}

# Main installation function
main() {
    print_banner

    log_info "Starting TuTaRdrgZ dotfiles setup..."

    # Detection phase
    detect_os
    check_sudo_advanced
    detect_environment

    log_info "Environment: $ENV_TYPE"
    log_info "Sudo available: $HAS_SUDO"
    if [ "$HAS_SUDO" = true ]; then
        log_info "Password required: $NEEDS_PASSWORD"
    fi

    # Installation phase
    install_packages_smart
    setup_zsh
    setup_neovim
    setup_tmux
    link_dotfiles
    change_shell
    setup_environment_specific

    # Completion
    show_final_status
}

# Error handling
trap 'log_error "Script failed at line $LINENO. Exit code: $?"' ERR

# Run main function
main "$@"
