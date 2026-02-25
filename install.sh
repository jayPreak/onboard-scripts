#!/bin/bash
set -e

echo "🚀 Starting macOS Developer Setup…"

########################################
# Ask for sudo upfront
########################################
sudo -v

########################################
# Install Xcode Command Line Tools
########################################
if ! xcode-select -p &>/dev/null; then
  echo "📦 Installing Xcode Command Line Tools…"
  xcode-select --install
  echo "⚠ Complete install and re-run script."
  exit 1
else
  echo "✅ Xcode Command Line Tools installed."
fi

########################################
# Install Homebrew
########################################
if ! command -v brew &>/dev/null; then
  echo "🍺 Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon PATH fix
if [[ $(uname -m) == "arm64" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew update

########################################
# Essential CLI tools (Homebrew)
########################################
FORMULAE=(
  git
  wget
  jq
  fish
)

for pkg in "${FORMULAE[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed."
  else
    echo "📦 Installing $pkg…"
    brew install "$pkg"
  fi
done

########################################
# GUI Apps (Casks)
########################################
CASKS=(
  ghostty
  font-geist-mono-nerd-font
)

for app in "${CASKS[@]}"; do
  if brew list --cask "$app" &>/dev/null; then
    echo "✅ $app installed."
  else
    echo "📦 Installing $app (cask)…"
    brew install --cask "$app"
  fi
done

# Upgrade all outdated apps
echo "⬆️ Upgrading all outdated Homebrew formulae and casks…"
brew update
brew upgrade
brew cu -a || true

########################################
# Set fish as default shell
########################################
FISH_PATH=$(command -v fish)
if ! grep -q "$FISH_PATH" /etc/shells; then
  echo "🐟 Adding fish to shells list…"
  echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
echo "🐟 Setting fish as default shell…"
chsh -s "$FISH_PATH"

########################################
# Install mise
########################################
if ! command -v mise &>/dev/null; then
  echo "📥 Installing mise…"
  curl https://mise.run | sh
fi

# Add mise activate to fish config
if ! grep -q "mise activate fish" ~/.config/fish/config.fish 2>/dev/null; then
  echo "✨ Activating mise in fish…"
  echo 'eval "$(~/.local/bin/mise activate fish)"' >> ~/.config/fish/config.fish
fi

########################################
# Node Install via mise
########################################
echo "📦 Installing Node (latest stable) via mise…"
mise use --global node@latest

########################################
# Starship Prompt
########################################
if ! command -v starship &>/dev/null; then
  echo "⭐ Installing starship prompt…"
  curl -fsSL https://starship.rs/install.sh | sh -s -- --yes
fi

# Configure fish to init starship
if ! grep -q "starship init fish" ~/.config/fish/config.fish 2>/dev/null; then
  echo "starship init fish | source" >> ~/.config/fish/config.fish
fi

########################################
# SSH key
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

echo ""
echo "🎉 Developer setup is complete!"
echo "📀 Restart terminal to start using fish + starship + mise (Node installed)"