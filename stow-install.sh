#!/bin/bash
# GNU Stow installer for dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_banner() {
    echo "╔══════════════════════════════════════╗"
    echo "║       TuTaRdrgZ Dotfiles (Stow)      ║"
    echo "╚══════════════════════════════════════╝"
}

install_with_stow() {
    local packages=("$@")
    
    if [ ${#packages[@]} -eq 0 ]; then
        packages=("nvim" "zsh" "wezterm" "fastfetch" "scripts")
    fi
    
    echo "Installing packages: ${packages[*]}"
    
    for package in "${packages[@]}"; do
        if [ -d "$package" ]; then
            echo "📦 Installing $package..."
            stow "$package"
            echo "✅ $package installed"
        else
            echo "⚠️  Package $package not found"
        fi
    done
}

main() {
    print_banner
    
    if ! command -v stow &> /dev/null; then
        echo "❌ GNU Stow not found. Please install it first."
        echo "   Arch: sudo pacman -S stow"
        echo "   Debian: sudo apt install stow"
        echo "   macOS: brew install stow"
        exit 1
    fi
    
    cd "$DOTFILES_DIR"
    install_with_stow "$@"
    
    echo "🎉 Stow installation complete!"
}

main "$@"
