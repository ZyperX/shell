#!/usr/bin/env bash
set -euo pipefail

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"
log(){ echo -e "${GREEN}[+]${NC} $*"; }
warn(){ echo -e "${YELLOW}[!]${NC} $*"; }

if [[ $EUID -eq 0 ]]; then
  warn "Run this script as your normal user (it will use sudo when needed)."
  exit 1
fi

PKGS=(
git curl wget zsh tmux fzf jq tree unzip zip htop build-essential
ripgrep fd-find bat btop xclip wl-clipboard python3-pip
)

log "Installing packages..."
sudo apt update
sudo apt install -y "${PKGS[@]}"

command -v bat >/dev/null || sudo ln -sf /usr/bin/batcat /usr/local/bin/bat || true
command -v fd >/dev/null || sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd || true

if ! command -v eza >/dev/null; then
  log "Installing eza..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o /etc/apt/keyrings/eza.gpg
  echo "deb [signed-by=/etc/apt/keyrings/eza.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/eza.list >/dev/null
  sudo apt update
  sudo apt install -y eza
fi

if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

clone_if_missing() {
  local repo="$1"; local dest="$2"
  [[ -d "$dest" ]] || git clone --depth=1 "$repo" "$dest"
}

clone_if_missing https://github.com/zsh-users/zsh-autosuggestions \
  "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting \
  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/zsh-users/zsh-completions \
  "$ZSH_CUSTOM/plugins/zsh-completions"
clone_if_missing https://github.com/zsh-users/zsh-history-substring-search \
  "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
clone_if_missing https://github.com/romkatv/powerlevel10k.git \
  "$ZSH_CUSTOM/themes/powerlevel10k"

cp -n ~/.zshrc ~/.zshrc.bak 2>/dev/null || true

cat > ~/.zshrc <<'EOF'
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

plugins=(
git sudo tmux fzf extract
zsh-autosuggestions
zsh-syntax-highlighting
zsh-completions
history-substring-search
)

source $ZSH/oh-my-zsh.sh

alias ls='eza --icons'
alias ll='eza -lah --icons'
alias la='eza -la --icons'
alias cat='bat'
alias grep='rg'
alias find='fd'
alias cls='clear'
alias ports='ss -tulpen'
alias myip='curl ifconfig.me'
alias weather='curl wttr.in'
alias update='sudo apt update && sudo apt upgrade -y'

if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

if command -v tmux >/dev/null && [ -z "$TMUX" ]; then
  exec tmux
fi
EOF

if ! command -v zoxide >/dev/null; then
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

mkdir -p ~/.tmux/plugins
clone_if_missing https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

cat > ~/.tmux.conf <<'EOF'
unbind C-b
set -g prefix C-b
bind C-b send-prefix

set -g mouse on
set -g history-limit 100000
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*:Tc"
set -sg escape-time 0
set -g set-clipboard on

bind | split-window -h
bind - split-window -v
bind r source-file ~/.tmux.conf \; display-message "Reloaded"

set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @plugin 'catppuccin/tmux'

set -g @continuum-restore 'on'
set -g @continuum-save-interval '15'

run '~/.tmux/plugins/tpm/tpm'
EOF

if ! grep -q "/bin/zsh" <<<"$SHELL"; then
  chsh -s "$(command -v zsh)"
fi

warn "Open tmux once, then press Ctrl+b followed by Shift+I to install TPM plugins."

cat <<MSG

=====================================================
Bootstrap complete.

Recommended next steps:

1. Restart your terminal.
2. Run:
      p10k configure
3. Open tmux.
4. Press:
      Ctrl+b  Shift+I
   to install tmux plugins.
=====================================================

MSG
