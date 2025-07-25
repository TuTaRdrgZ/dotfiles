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
	echo "║     Current Date: $(date '+%Y-%m-%d')║"
	echo "║     User: $(printf '%-20s' "$USER")  ║"
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

# Detect environment (educational, home, restricted)
detect_environment() {
	local env_type="unknown"

	# Check for educational environment indicators
	if [[ "$PWD" == *"/nfs/homes/"* ]] || [[ "$HOME" == *"/nfs/homes/"* ]]; then
		env_type="educational"
		log_info "Educational environment detected (nfs/homes path)"
	elif [ -d "/goinfre" ] || [ -d "/sgoinfre" ]; then
		env_type="educational"
		log_info "Educational environment detected (shared storage found)"
	elif [[ "$HOSTNAME" == *"student"* ]] || [[ "$HOSTNAME" == *"lab"* ]]; then
		env_type="educational"
		log_info "Educational environment detected (hostname)"
	elif [[ "$USER" =~ ^[a-z]{1,8}$ ]] && [ ! -w "/usr/local" ] && ! groups "$USER" | grep -q '\(wheel\|sudo\|admin\)'; then
		env_type="restricted"
		log_info "Restricted environment detected"
	elif groups "$USER" 2>/dev/null | grep -q '\(wheel\|sudo\|admin\)'; then
		env_type="home"
		log_info "Personal/home environment detected"
	else
		env_type="restricted"
		log_info "Assuming restricted environment (safe default)"
	fi

	ENV_TYPE="$env_type"
}

# Advanced sudo detection
check_sudo_advanced() {
	local has_passwordless_sudo=false
	local has_sudo_with_password=false
	local in_sudo_group=false

	# Check if sudo command exists
	if ! command -v sudo &> /dev/null; then
		log_warning "sudo command not found"
		HAS_SUDO=false
		NEEDS_PASSWORD=false
		return 1
	fi

	# Check passwordless sudo
	if sudo -n true 2>/dev/null; then
		has_passwordless_sudo=true
		log_success "Passwordless sudo available"
	fi

	# Check if user is in sudo groups
	if groups "$USER" 2>/dev/null | grep -q '\(wheel\|sudo\|admin\)'; then
		in_sudo_group=true
		has_sudo_with_password=true
		log_info "User is in sudo group"
	fi

	# Determine final sudo status
	if [ "$has_passwordless_sudo" = true ]; then
		HAS_SUDO=true
		NEEDS_PASSWORD=false
		log_success "Administrative privileges available (no password needed)"
	elif [ "$in_sudo_group" = true ]; then
		HAS_SUDO=true
		NEEDS_PASSWORD=true
		log_info "Administrative privileges available (password required)"
	else
		HAS_SUDO=false
		NEEDS_PASSWORD=false
		log_warning "No administrative privileges available"

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

# Install packages with system package manager (with password prompt)
install_system_packages_with_password() {
	log_info "Installing packages with system package manager (password required)..."

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

# Smart package installation based on environment and permissions
install_packages_smart() {
	log_info "Determining optimal installation method..."

	case "$ENV_TYPE" in
		"educational"|"restricted")
			log_info "Restricted environment detected - using local installation"
			install_tools_local
			;;
		"home")
			if [ "$HAS_SUDO" = true ] && [ "$NEEDS_PASSWORD" = true ]; then
				log_info "Home environment with sudo detected - using system package manager"
				echo -e "${YELLOW}This will ask for your password...${NC}"
				install_system_packages_with_password
				# Install starship locally as fallback
				install_starship_local
			elif [ "$HAS_SUDO" = true ] && [ "$NEEDS_PASSWORD" = false ]; then
				log_info "Passwordless sudo detected - using system package manager"
				install_system_packages_passwordless
				install_starship_local
			else
				log_warning "Unexpected: home environment without sudo, falling back to local"
				install_tools_local
			fi
			;;
		*)
			log_warning "Unknown environment, using safe local installation"
			install_tools_local
			;;
	esac
}

# Setup Zsh (works without sudo)
setup_zsh() {
	log_info "Setting up Zsh..."

	# Install Oh My Zsh
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	fi

	# Install plugins
	ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}

	# zsh-syntax-highlighting
	if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting
	fi

	# zsh-autosuggestions
	if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
		git clone https://github.com/zsh-users/zsh-autosuggestions $ZSH_CUSTOM/plugins/zsh-autosuggestions
	fi

	# powerlevel10k theme
	if [ ! -d "$ZSH_CUSTOM/themes/powerlevel10k" ]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git $ZSH_CUSTOM/themes/powerlevel10k
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

	# Create nvim config directory
	mkdir -p "$HOME/.config/nvim"

	log_success "Neovim setup ready!"
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
	# ============= EDUCATIONAL ENVIRONMENT SPECIFIC =============

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
	echo "🔍 Running norminette..."
	norminette *.c *.h 2>/dev/null || echo "No .c/.h files found or norminette issues"

	echo "🔨 Checking compilation..."
	if [ -f "Makefile" ]; then
		make re
		echo "✅ Compilation check complete!"
	else
		echo "⚠️  No Makefile found"
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
	# ============= HOME ENVIRONMENT SPECIFIC =============

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
	# ============= RESTRICTED ENVIRONMENT SPECIFIC =============

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
	echo "║         Setup Complete! 🎉           ║"
	echo "║                                      ║"
	case "$ENV_TYPE" in
		"educational")
			echo "║  Perfect for educational use! 🎓      ║"
			;;
		"home")
			echo "║  Perfect for home development! 🏠     ║"
			;;
		*)
			echo "║  Perfect for your environment! 🚀     ║"
			;;
	esac
	echo "║                                      ║"
	echo "║  Next steps:                         ║"
	echo "║  1. Restart your terminal            ║"
	echo "║     OR run: source ~/.zshrc          ║"
	echo "║  2. Run: tmux                        ║"
	echo "║  3. Enjoy your setup! 🚀              ║"
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
	command -v nvim >/dev/null && echo "✅ Neovim: $(nvim --version | head -n1)"
	command -v node >/dev/null && echo "✅ Node.js: $(node --version)"
	command -v tmux >/dev/null && echo "✅ Tmux: $(tmux -V)"
	command -v fzf >/dev/null && echo "✅ fzf: $(fzf --version)"
	command -v rg >/dev/null && echo "✅ ripgrep: $(rg --version | head -n1)"
	command -v fd >/dev/null && echo "✅ fd: $(fd --version)"
	command -v bat >/dev/null && echo "✅ bat: $(bat --version)"
	command -v exa >/dev/null && echo "✅ exa: $(exa --version)"
	command -v starship >/dev/null && echo "✅ starship: $(starship --version)"
}

# Main installation function
main() {
	print_banner

	log_info "Starting TuTaRdrgZ dotfiles setup..."

	# Detection phase
	detect_os
	detect_environment
	check_sudo_advanced

	log_info "Environment: $ENV_TYPE"

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
