#!/bin/bash
set -e

echo "🚀 Starting macOS Developer Setup..."

########################################
# Xcode CLI Tools
########################################
if ! xcode-select -p &>/dev/null; then
  echo "📦 Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "⚠ Complete popup, then re-run script."
  exit 1
else
  echo "✅ Xcode Command Line Tools installed."
fi

########################################
# Homebrew
########################################
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "🍺 Updating Homebrew..."
brew update

BREW_PREFIX="$(brew --prefix)"

########################################
# Helpers
########################################
install_formula() {
  if brew list --formula | grep -q "^$1\$"; then
    echo "✅ $1 already installed."
  else
    echo "📦 Installing $1..."
    brew install "$1"
  fi
}

install_cask() {
  if brew list --cask | grep -q "^$1\$"; then
    echo "✅ $1 already installed."
  elif [ -d "/Applications/${2}.app" ]; then
    echo "⚠ ${2}.app already exists. Skipping."
  else
    echo "📦 Installing $1..."
    brew install --cask "$1"
  fi
}

########################################
# Core CLI
########################################
install_formula git
install_formula wget
install_formula jq
install_formula fish
install_formula starship
install_formula mise
brew tap buo/cask-upgrade || true

########################################
# Fonts
########################################
brew tap homebrew/cask-fonts || true
install_cask font-geist-mono-nerd-font "GeistMonoNerdFont"

########################################
# Terminal
########################################
install_cask ghostty Ghostty

########################################
# Configure Fish Shell
########################################

FISH_PATH="$BREW_PREFIX/bin/fish"

if ! grep -q "$FISH_PATH" /etc/shells; then
  echo "🔧 Adding fish to allowed shells..."
  echo "$FISH_PATH" | sudo tee -a /etc/shells > /dev/null
fi

CURRENT_SHELL="$(dscl . -read /Users/$USER UserShell | awk '{print $2}')"

if [ "$CURRENT_SHELL" != "$FISH_PATH" ]; then
  echo "🐟 Setting fish as default shell..."
  chsh -s "$FISH_PATH"
else
  echo "✅ Fish already default."
fi

########################################
# Fish Config Setup
########################################

FISH_CONFIG="$HOME/.config/fish/config.fish"
mkdir -p "$(dirname "$FISH_CONFIG")"

# Add Homebrew to PATH
if ! grep -q "brew shellenv" "$FISH_CONFIG" 2>/dev/null; then
  echo "" >> "$FISH_CONFIG"
  echo "# Homebrew" >> "$FISH_CONFIG"
  echo "eval ($BREW_PREFIX/bin/brew shellenv)" >> "$FISH_CONFIG"
fi

# Starship init
if ! grep -q "starship init fish" "$FISH_CONFIG" 2>/dev/null; then
  echo "" >> "$FISH_CONFIG"
  echo "# Starship" >> "$FISH_CONFIG"
  echo "starship init fish | source" >> "$FISH_CONFIG"
fi

# Mise activation
if ! grep -q "mise activate fish" "$FISH_CONFIG" 2>/dev/null; then
  echo "" >> "$FISH_CONFIG"
  echo "# Mise" >> "$FISH_CONFIG"
  echo "mise activate fish | source" >> "$FISH_CONFIG"
fi

########################################
# Install Node via Mise
########################################

echo "📦 Installing Node 22 via mise..."
mise use -g node@22

########################################
# Ghostty Config
########################################

GHOSTTY_CONFIG="$HOME/.config/ghostty/config"
mkdir -p "$(dirname "$GHOSTTY_CONFIG")"

if [ ! -f "$GHOSTTY_CONFIG" ]; then
  cat <<EOF > "$GHOSTTY_CONFIG"
font-family = GeistMono Nerd Font
font-size = 14
theme = dark
EOF
  echo "🖥 Ghostty config created."
else
  echo "✅ Ghostty config already exists."
fi

########################################
# SSH key for bitbucket
########################################
if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "🔐 Generating SSH key…"
  read -p "Enter email for SSH key: " sshemail
  ssh-keygen -t ed25519 -C "$sshemail"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  echo ""
  echo "📋 SSH public key:"
  cat ~/.ssh/id_ed25519.pub
fi

########################################
# Git config
########################################
if ! git config --global user.name &>/dev/null; then
  read -p "Enter your Git user name: " gitname
  git config --global user.name "$gitname"
fi

if ! git config --global user.email &>/dev/null; then
  read -p "Enter your Git email: " gitemail
  git config --global user.email "$gitemail"
fi

echo "🎉 Setup Complete."
echo ""
echo "👉 Run: mise ls"
echo "👉 Restart terminal or open Ghostty."