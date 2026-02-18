#!/bin/bash

set -e

echo "🧹 Mac Developer Cleanup (Safe Mode)"
echo "⚠️ This will NOT uninstall Homebrew."

read -p "Are you sure you want to remove dev setup for THIS user only? (y/n): " confirm
if [[ "$confirm" != "y" ]]; then
  echo "Aborted."
  exit 1
fi

########################################
# Remove Brew Packages (but not brew itself)
########################################
if command -v brew &>/dev/null; then
  echo "Removing installed brew packages..."
  brew uninstall --ignore-dependencies git nvm yarn wget jq 2>/dev/null || true
else
  echo "Homebrew not found. Skipping brew package removal."
fi

########################################
# Remove NVM + Node Versions (User Only)
########################################
if [ -d "$HOME/.nvm" ]; then
  echo "Removing NVM and Node versions..."
  rm -rf "$HOME/.nvm"
fi

########################################
# Clean zsh additions (only lines we added)
########################################
if [ -f "$HOME/.zshrc" ]; then
  sed -i '' '/NVM_DIR/d' "$HOME/.zshrc" 2>/dev/null || true
  sed -i '' '/nvm.sh/d' "$HOME/.zshrc" 2>/dev/null || true
fi

########################################
# Remove Git Global Config (User Only)
########################################
if [ -f "$HOME/.gitconfig" ]; then
  echo "Removing global git config..."
  rm "$HOME/.gitconfig"
fi

########################################
# Remove SSH Keys (Optional)
########################################
if [ -f "$HOME/.ssh/id_ed25519" ]; then
  read -p "Remove SSH key for this user? (y/n): " sshconfirm
  if [[ "$sshconfirm" == "y" ]]; then
    rm -f "$HOME/.ssh/id_ed25519"*
    echo "SSH keys removed."
  fi
fi

echo ""
echo "✅ Cleanup complete for THIS USER."
echo "🍺 Homebrew remains installed system-wide."

