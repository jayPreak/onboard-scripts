#!/bin/bash
set -e

echo "🧹 Mac Developer Full Cleanup"
echo "⚠ This will remove:"
echo "  - Node (mise)"
echo "  - mise"
echo "  - fish"
echo "  - starship"
echo "  - ghostty"
echo "  - nerd font"
echo "  - cask-upgrade"
echo ""
read -p "Continue? (y/n): " confirm

if [ "$confirm" != "y" ]; then
  echo "Cancelled."
  exit 0
fi

########################################
# Reset Shell to macOS Default
########################################

CURRENT_SHELL="$(dscl . -read /Users/$USER UserShell | awk '{print $2}')"

if [ "$CURRENT_SHELL" != "/bin/zsh" ]; then
  echo "🔄 Resetting default shell to /bin/zsh..."
  chsh -s /bin/zsh
else
  echo "✅ Shell already system default."
fi

########################################
# Remove fish FIRST (prevents mise recursion)
########################################

echo "🗑 Cleaning fish functions and cache..."

rm -rf "$HOME/.config/fish"
rm -rf "$HOME/.local/share/fish"
rm -rf "$HOME/.cache/fish"

if brew list --formula | grep -q "^fish$"; then
  echo "🗑 Removing fish..."
  brew uninstall fish
else
  echo "✅ fish not installed."
fi

########################################
# Remove Node from Mise
########################################

if command -v mise &>/dev/null; then
  echo "🗑 Removing Node 22 from mise..."
  mise uninstall node@22 || true
fi

########################################
# Remove Brew Formulas
########################################

remove_formula() {
  if brew list --formula | grep -q "^$1\$"; then
    echo "🗑 Removing $1..."
    brew uninstall "$1"
  else
    echo "✅ $1 not installed."
  fi
}

remove_formula mise
remove_formula starship
remove_formula fish

########################################
# Remove Brew Casks
########################################

remove_cask() {
  if brew list --cask | grep -q "^$1\$"; then
    echo "🗑 Removing $1..."
    brew uninstall --cask "$1"
  else
    echo "✅ $1 not installed."
  fi
}

remove_cask ghostty
remove_cask font-geist-mono-nerd-font
brew untap buo/cask-upgrade || true

########################################
# Remove Config Files
########################################

echo "🗑 Cleaning config files..."

rm -rf "$HOME/.config/fish"
rm -rf "$HOME/.config/ghostty"
rm -rf "$HOME/.local/share/mise"
rm -rf "$HOME/.config/mise"

########################################
# Optional: Remove Homebrew
########################################

echo ""
read -p "Remove Homebrew completely? (y/n): " remove_brew

if [ "$remove_brew" = "y" ]; then
  echo "🗑 Uninstalling Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)"
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

echo "✅ Cleanup Complete."