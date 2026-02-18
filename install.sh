#!/bin/bash

set -e

echo "🚀 Starting Mac Developer Setup..."

########################################
# Ask for sudo upfront
########################################
sudo -v

########################################
# Install Xcode Command Line Tools
########################################
if ! xcode-select -p &>/dev/null; then
  echo "📦 Installing Xcode Command Line Tools..."
  xcode-select --install
  echo "⚠️ Complete installation popup, then re-run script."
  exit 1
else
  echo "✅ Xcode Command Line Tools already installed."
fi

########################################
# Homebrew Setup + Permission Fix
########################################
if command -v brew &>/dev/null; then
  echo "✅ Homebrew already installed."

  BREW_PREFIX=$(brew --prefix)

  if [ ! -w "$BREW_PREFIX" ]; then
    echo "🔧 Fixing Homebrew permissions..."
    sudo chown -R "$USER" "$BREW_PREFIX"
  fi

else
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Apple Silicon PATH fix
if [[ $(uname -m) == "arm64" ]]; then
  if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

brew update

########################################
# Install Core Packages
########################################
PACKAGES=(git nvm yarn wget jq)

for pkg in "${PACKAGES[@]}"; do
  if brew list "$pkg" &>/dev/null; then
    echo "✅ $pkg already installed."
  else
    echo "📦 Installing $pkg..."
    brew install "$pkg"
  fi
done

########################################
# Setup NVM
########################################
mkdir -p ~/.nvm

if ! grep -q 'NVM_DIR' ~/.zshrc 2>/dev/null; then
  echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.zshrc
  echo '[ -s "$(brew --prefix nvm)/nvm.sh" ] && \. "$(brew --prefix nvm)/nvm.sh"' >> ~/.zshrc
fi

source ~/.zshrc || true

########################################
# Install Node LTS
########################################
if ! command -v node &>/dev/null; then
  echo "📦 Installing latest LTS Node..."
  nvm install --lts
  nvm alias default lts/*
else
  echo "✅ Node already installed."
fi

########################################
# Git Config
########################################
if ! git config --global user.name &>/dev/null; then
  read -p "Enter your Git name: " gitname
  git config --global user.name "$gitname"
fi

if ! git config --global user.email &>/dev/null; then
  read -p "Enter your Git email: " gitemail
  git config --global user.email "$gitemail"
fi

########################################
# SSH Setup
########################################
if [ ! -f ~/.ssh/id_ed25519 ]; then
  echo "🔐 Generating SSH key..."
  read -p "Enter email for SSH key: " sshemail
  ssh-keygen -t ed25519 -C "$sshemail"
  eval "$(ssh-agent -s)"
  ssh-add ~/.ssh/id_ed25519
  echo "📋 Copy this key to Bitbucket:"
  cat ~/.ssh/id_ed25519.pub
else
  echo "✅ SSH key already exists."
fi

echo ""
echo "🎉 Setup Complete!"
echo "Restart your terminal or run: source ~/.zshrc"

