# TuTaRdrgZ Dotfiles

Personal development environment setup with multiple installation methods.

## 🚀 Quick Installation (Recommended)

For automatic setup:

```bash
curl -fsSL https://raw.githubusercontent.com/TuTaRdrgZ/dotfiles/main/install.sh | bash
```

This method:
-  **Detects your environment** (educational/home/restricted)
-  **Handles permissions** automatically (sudo/no-sudo)
-  **Installs tools locally** when needed
-  **Works everywhere** (Linux, macOS, containers)

## 🎯 Manual Installation (Advanced Users)

For precise control using GNU Stow:

### Prerequisites

- [GNU Stow](https://www.gnu.org/software/stow/)
- [Git](https://git-scm.com/)
- [WezTerm](https://wezfurlong.org/wezterm/index.html)
- [Neovim](https://neovim.io/)
- [FastFetch](https://github.com/fastfetch-cli/fastfetch)

### Steps

1. **Clone the repository:**
   ```bash
   git clone https://github.com/TuTaRdrgZ/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. **Install everything:**
   ```bash
   ./stow-install.sh
   ```

3. **Or install specific packages:**
   ```bash
   ./stow-install.sh nvim zsh wezterm
   ```

## 📁 Repository Structure

```
dotfiles/
├── install.sh              # Intelligent auto-installer
├── stow-install.sh         # GNU Stow installer
├── nvim/                   # Neovim configuration
│   └── .config/nvim/
├── zsh/                    # Zsh configuration
│   └── .zshrc
├── wezterm/               # WezTerm configuration
│   └── .config/wezterm/
├── fastfetch/             # FastFetch configuration
│   └── .config/fastfetch/
├── scripts/               # Custom scripts
│   └── .local/bin/
└── configs/               # Auto-installer configs
    ├── zsh/
    ├── nvim/
    └── git/
```

## ⚙️ Configuration Details

### Neovim
- Modern Lua configuration
- Plugin management with lazy.nvim
- Custom keymaps and options
- LSP support

### Zsh
- Oh My Zsh integration
- Powerlevel10k theme
- Custom aliases and functions
- Environment-specific configurations

### WezTerm
- Custom themes (Kanagawa)
- Optimized performance settings
- Cross-platform compatibility

### FastFetch
- Custom system information display
- Beautiful ASCII art
- Performance metrics

## 🔧 Usage

### Automatic Method
The intelligent installer sets up everything automatically and adapts to your environment.

### Stow Method
Each package can be managed individually:

```bash
# Install specific configurations
stow nvim
stow zsh
stow wezterm

# Remove configurations
stow -D nvim
stow -D zsh
```

## 🔄 Updates

### Automatic Installer
```bash
cd ~/.dotfiles
git pull
./install.sh
```

### Stow Method
```bash
cd ~/.dotfiles
git pull
./stow-install.sh
```

## 🌍 Environment Support

- ✅ **Educational environments** (no sudo required)
- ✅ **Home environments** (full privileges)
- ✅ **Restricted environments** (safe defaults)
- ✅ **Containers and VMs**
- ✅ **Linux** (Arch, Debian, RedHat)
- ✅ **macOS**

## 🎨 Key Features

### Modern CLI Tools (Auto-installed)
- **fzf** - Fuzzy finder
- **ripgrep** - Fast grep
- **fd** - Fast find
- **bat** - Better cat
- **exa** - Modern ls
- **starship** - Cross-shell prompt

### Development Tools
- **Neovim** with LSP
- **Tmux** with TPM
- **Node.js** via nvm
- **Git** with delta

## 🔑 Key Aliases

```bash
# Navigation
ll          # exa -la --icons --git
..          # cd ..
...         # cd ../..

# Git
g           # git
ga          # git add
gc          # git commit -m
gp          # git push
gs          # git status

# Development
v           # nvim
t           # tmux
pn          # pnpm
```

## 🛠️ Troubleshooting

### Missing GNU Stow
```bash
# Arch Linux
sudo pacman -S stow

# Debian/Ubuntu
sudo apt install stow

# macOS
brew install stow
```

## 📄 License

MIT License - feel free to use and modify.

---

**Choose your installation method:**
- 🚀 **Quick & Smart**: `curl -fsSL https://raw.githubusercontent.com/TuTaRdrgZ/dotfiles/main/install.sh | bash`
- 🎯 **Manual Control**: `git clone && ./stow-install.sh`

⭐ **Star this repo if it helped you!**
