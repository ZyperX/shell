#!/usr/bin/env bash
# Terminal bootstrap: zsh + Oh My Zsh + Starship + tmux + modern CLI tools (Debian/Ubuntu/WSL)
# Safe to re-run: configs are backed up with a timestamp, existing clones are skipped.
set -euo pipefail

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"; NC="\033[0m"
log()  { echo -e "${GREEN}[+]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
die()  { echo -e "${RED}[x]${NC} $*" >&2; exit 1; }

[[ $EUID -eq 0 ]] && die "Run as your normal user (sudo is used when needed)."
command -v apt-get >/dev/null || die "This script needs a Debian/Ubuntu system (apt)."

STAMP="$(date +%Y%m%d-%H%M%S)"
mkdir -p "$HOME/.local/bin" "$HOME/.config"

backup() { [[ -e "$1" ]] && cp -a "$1" "$1.bak.$STAMP" && log "Backed up $1 -> $1.bak.$STAMP"; return 0; }

clone_if_missing() {
  local repo="$1" dest="$2"; shift 2
  if [[ -d "$dest/.git" ]]; then
    log "Already present: $dest"
  else
    git clone --depth=1 "$@" "$repo" "$dest"
  fi
}

# Install only packages that exist in this distro release; report the rest instead of aborting.
install_pkgs() {
  local avail=() missing=() p
  for p in "$@"; do
    if apt-cache show "$p" >/dev/null 2>&1; then avail+=("$p"); else missing+=("$p"); fi
  done
  if (( ${#avail[@]} )); then sudo apt-get install -y "${avail[@]}"; fi
  if (( ${#missing[@]} )); then warn "Not in your apt repos (skipped): ${missing[*]}"; fi
}

# ---------------------------------------------------------------- packages
# fzf is NOT taken from apt: Ubuntu's version is too old for tmux-sessionx. Installed from git below.
PKGS=(
  git curl wget ca-certificates gnupg zsh tmux jq tree unzip zip
  htop btop build-essential ripgrep fd-find bat python3-pip
  xclip wl-clipboard ncurses-term zoxide eza iproute2
)

log "Installing packages..."
sudo apt-get update
install_pkgs "${PKGS[@]}"

# Debian/Ubuntu ship bat/fd under different names
if ! command -v bat >/dev/null && [[ -x /usr/bin/batcat ]]; then sudo ln -sf /usr/bin/batcat /usr/local/bin/bat; fi
if ! command -v fd  >/dev/null && [[ -x /usr/bin/fdfind ]]; then sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd; fi

# eza: older Ubuntu releases don't have it in apt -> use the official repo
if ! command -v eza >/dev/null; then
  log "Installing eza from its official repo..."
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor --yes -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list >/dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update
  sudo apt-get install -y eza
fi

# zoxide fallback (installs to ~/.local/bin)
if ! command -v zoxide >/dev/null && [[ ! -x "$HOME/.local/bin/zoxide" ]]; then
  log "Installing zoxide..."
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh
fi

# fzf (latest) + fzf-tmux, from the official repo
if [[ -d "$HOME/.fzf/.git" ]]; then
  log "Updating fzf..."
  git -C "$HOME/.fzf" pull --ff-only -q || warn "fzf update failed, keeping current version"
else
  git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
fi
"$HOME/.fzf/install" --bin
# Symlink so tmux plugins (which don't read .zshrc) can find them too
sudo ln -sf "$HOME/.fzf/bin/fzf"      /usr/local/bin/fzf
sudo ln -sf "$HOME/.fzf/bin/fzf-tmux" /usr/local/bin/fzf-tmux

# atuin (searchable shell history). Shell init is written into .zshrc below.
if ! command -v atuin >/dev/null && [[ ! -x "$HOME/.atuin/bin/atuin" ]]; then
  log "Installing atuin..."
  curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh \
    | sh -s -- --non-interactive || warn "atuin install failed - see https://docs.atuin.sh"
fi

# Starship prompt (required)
if ! command -v starship >/dev/null && [[ ! -x "$HOME/.local/bin/starship" ]]; then
  log "Installing Starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- -y -b "$HOME/.local/bin"
fi
[[ -x "$HOME/.local/bin/starship" ]] || command -v starship >/dev/null || die "Starship install failed."

# ---------------------------------------------------------------- oh my zsh + plugins
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  log "Installing Oh My Zsh..."
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions      "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting  "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
clone_if_missing https://github.com/zsh-users/zsh-completions          "$ZSH_CUSTOM/plugins/zsh-completions"
clone_if_missing https://github.com/Aloxaf/fzf-tab                     "$ZSH_CUSTOM/plugins/fzf-tab"
clone_if_missing https://github.com/MichaelAquilina/zsh-you-should-use "$ZSH_CUSTOM/plugins/you-should-use"
# history-substring-search ships with Oh My Zsh, no clone needed.

# ---------------------------------------------------------------- .zshrc
backup "$HOME/.zshrc"
cat > "$HOME/.zshrc" <<'EOF'
# ---- generated by terminal-bootstrap.sh ----

# PATH first, so tmux (started below) inherits it too
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/.fzf/bin" "$HOME/.atuin/bin" $path)
export PATH

# Auto-start tmux: attach to one "main" session instead of a new one per window.
# Skipped in VS Code, over SSH, or with: NO_TMUX=1 zsh
if [[ -o interactive && -z "$TMUX" && -z "$NO_TMUX" && -z "$SSH_CONNECTION" \
      && "$TERM_PROGRAM" != "vscode" ]] && command -v tmux >/dev/null; then
  exec tmux new-session -A -s main
fi

export ZSH="$HOME/.oh-my-zsh"
ZSH_CUSTOM="$ZSH/custom"
ZSH_THEME=""                # prompt is handled by Starship
export FZF_BASE="$HOME/.fzf"

# zsh-completions is meant to be added to fpath, not loaded as a plugin
fpath+=("$ZSH_CUSTOM/plugins/zsh-completions/src")

# Order matters: fzf-tab before autosuggestions; syntax-highlighting before history-substring-search
plugins=(
  git sudo extract fzf
  fzf-tab
  you-should-use
  zsh-autosuggestions
  zsh-syntax-highlighting
  history-substring-search
)

# you-should-use: show the reminder after the command's output, not before
export YSU_MESSAGE_POSITION="after"

source "$ZSH/oh-my-zsh.sh"

# History (set after OMZ, which otherwise overrides these)
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

# fzf-tab
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always $realpath'

# Kill stray mouse escape codes: if a program crashed or was killed while mouse
# tracking was on, the terminal keeps sending junk like "^[[<35;12;8M".
# This turns all tracking modes off before each prompt.
_reset_mouse_tracking() { printf '\e[?1000l\e[?1002l\e[?1003l\e[?1005l\e[?1006l\e[?1015l'; }
autoload -Uz add-zsh-hook
add-zsh-hook precmd _reset_mouse_tracking

# Aliases (grep/find are NOT overridden - rg/fd have different flags and break scripts)
if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -lah --icons --git --group-directories-first'
  alias la='eza -la --icons'
  alias lt='eza --tree --level=2 --icons'
fi
command -v bat >/dev/null && alias cat='bat --paging=never'
alias cls='clear'
alias ports='ss -tulpen'
alias myip='curl -s ifconfig.me; echo'
alias weather='curl wttr.in'
alias update='sudo apt update && sudo apt upgrade -y'

command -v zoxide >/dev/null && eval "$(zoxide init zsh)"

# atuin owns Ctrl-R. Up arrow stays with history-substring-search (prefix-matching).
command -v atuin >/dev/null && eval "$(atuin init zsh --disable-up-arrow)"

# Prompt
eval "$(starship init zsh)"
EOF
log "Wrote ~/.zshrc"

# ---------------------------------------------------------------- starship.toml
backup "$HOME/.config/starship.toml"
cat > "$HOME/.config/starship.toml" <<'EOF'
# ---- generated by terminal-bootstrap.sh ----
"$schema" = 'https://starship.rs/config-schema.json'
add_newline = true
palette = "catppuccin_mocha"

# Line 1: who/where, repo, language, VPN IP, duration. Line 2: the prompt symbol.
format = """
$username$hostname$directory$git_branch$git_status$git_state\
$python$nodejs$golang$rust$docker_context\
${custom.vpn}$cmd_duration$jobs
$character"""
right_format = "$status"

[username]
show_always = false            # only shown over SSH or as root
style_user = "bold mauve"
style_root = "bold red"
format = "[$user]($style)@"

[hostname]
ssh_only = true
style = "bold peach"
format = "[$hostname]($style) "

[directory]
style = "bold lavender"
truncation_length = 4
truncate_to_repo = true
read_only = " 󰌾"

[git_branch]
symbol = " "
style = "bold green"

[git_status]
style = "bold red"

[python]
symbol = " "
style = "yellow"

[cmd_duration]
min_time = 2000                # show only for commands taking > 2s
style = "yellow"
format = "took [$duration]($style) "

[jobs]
symbol = "✦ "
style = "bold blue"

[status]
disabled = false
format = "[✘ $status]($style)"
style = "bold red"

[character]
success_symbol = "[❯](bold green)"
error_symbol = "[❯](bold red)"

# Shows your VPN (tun0) IP when connected - handy for labs / reverse shells
[custom.vpn]
when = "ip link show tun0"
command = "ip -4 -o addr show tun0 | awk '{print $4}' | cut -d/ -f1"
shell = ["bash", "--noprofile", "--norc"]
symbol = "󰖂 "
style = "bold teal"
format = "[$symbol$output]($style) "

[palettes.catppuccin_mocha]
rosewater = "#f5e0dc"
flamingo = "#f2cdcd"
pink = "#f5c2e7"
mauve = "#cba6f7"
red = "#f38ba8"
maroon = "#eba0ac"
peach = "#fab387"
yellow = "#f9e2af"
green = "#a6e3a1"
teal = "#94e2d5"
sky = "#89dceb"
sapphire = "#74c7ec"
blue = "#89b4fa"
lavender = "#b4befe"
text = "#cdd6f4"
subtext1 = "#bac2de"
overlay0 = "#6c7086"
surface0 = "#313244"
base = "#1e1e2e"
EOF
log "Wrote ~/.config/starship.toml"

# ---------------------------------------------------------------- tmux plugins
# Cloned directly so nothing depends on pressing prefix+I. TPM still handles updates (prefix+U).
TPM_DIR="$HOME/.tmux/plugins"
mkdir -p "$TPM_DIR"
clone_if_missing https://github.com/tmux-plugins/tpm             "$TPM_DIR/tpm"
clone_if_missing https://github.com/tmux-plugins/tmux-sensible   "$TPM_DIR/tmux-sensible"
clone_if_missing https://github.com/tmux-plugins/tmux-resurrect  "$TPM_DIR/tmux-resurrect"
clone_if_missing https://github.com/tmux-plugins/tmux-yank       "$TPM_DIR/tmux-yank"
clone_if_missing https://github.com/omerxx/tmux-sessionx         "$TPM_DIR/tmux-sessionx"
clone_if_missing https://github.com/Morantron/tmux-fingers       "$TPM_DIR/tmux-fingers"
# Catppuccin recommends a manual clone (TPM has a name clash with it); pinned to a release tag.
clone_if_missing https://github.com/catppuccin/tmux.git \
  "$HOME/.config/tmux/plugins/catppuccin/tmux" -b v2.1.2

# Use proper tmux terminfo if available, else fall back
if infocmp tmux-256color >/dev/null 2>&1; then TMUX_TERM="tmux-256color"; else TMUX_TERM="screen-256color"; fi

# ---------------------------------------------------------------- tmux status-bar script
# CPU, RAM, live up/down, Wi-Fi, battery, VPN IP for the bottom-right of the tmux bar
mkdir -p "$HOME/.config/tmux/scripts"
cat > "$HOME/.config/tmux/scripts/tmux-status.sh" <<'STATUS_EOF'
#!/usr/bin/env bash
# tmux status-bar segments: CPU, RAM, live network up/down, Wi-Fi, battery, VPN IP.
# Called by tmux every few seconds via #(...). Prints one tmux-formatted line and exits instantly.
#
# On WSL2, Wi-Fi and network totals come from Windows (netsh.exe / netstat.exe). Those calls are
# slow and misbehave when run directly inside a tmux status job, so they run in a fully detached
# background refresher that writes to a cache; this script only ever reads the cache.
set -u

# Cache dir for values kept between refreshes. Must be writable: on WSL, /run/user/<uid> often
# isn't (WSLg owns it), so fall back to ~/.cache.
CACHE=""
for d in "${XDG_RUNTIME_DIR:+$XDG_RUNTIME_DIR/tmux-status}" "${XDG_CACHE_HOME:-$HOME/.cache}/tmux-status"; do
  [[ -n "$d" ]] || continue
  if mkdir -p "$d" 2>/dev/null && [[ -w "$d" ]] && : 2>/dev/null > "$d/.probe"; then CACHE=$d; break; fi
done
[[ -n "$CACHE" ]] || { printf '#[fg=#f38ba8]tmux-status: no writable cache dir'; exit 0; }

WIN="${TMUX_STATUS_WIN:-/mnt/c/Windows/System32}"
if [[ -n "${TMUX_STATUS_WSL:-}" ]]; then
  IS_WSL=$TMUX_STATUS_WSL
elif grep -qi microsoft /proc/version 2>/dev/null; then
  IS_WSL=1
else
  IS_WSL=0
fi

WIFI_TTL=20   # seconds between Wi-Fi lookups

# Catppuccin Mocha colours
TXT="#cdd6f4"; DIM="#6c7086"
RED="#f38ba8"; YELLOW="#f9e2af"; GREEN="#a6e3a1"
TEAL="#94e2d5"; SKY="#89dceb"; BLUE="#89b4fa"; MAUVE="#cba6f7"

seg() { printf '#[fg=%s]%s #[fg=%s]%s' "$1" "$2" "$TXT" "$3"; }   # colour label text
# Labels are plain text on purpose: Nerd Font icons can be drawn wider than tmux counts them,
# which pushes the bar past the screen edge and makes the terminal scroll on every refresh.
SSID_MAX=14   # long Wi-Fi names are shortened to keep the bar on one line

human() {   # bytes -> 512B / 34K / 1.2M
  awk -v b="$1" 'BEGIN{ if (b<1024) printf "%dB", b; else if (b<1048576) printf "%.0fK", b/1024; else printf "%.1fM", b/1048576 }'
}

age() { [[ -e "$1" ]] && echo $(( $(date +%s) - $(stat -c %Y "$1") )) || echo 99999; }

# ---------------------------------------------------------------- CPU (% since last refresh)
cpu() {
  local _ u n s i w q sq st idle total pt pi f="$CACHE/cpu"
  read -r _ u n s i w q sq st _ < /proc/stat
  idle=$(( i + w )); total=$(( u + n + s + i + w + q + sq + st ))
  if read -r pt pi 2>/dev/null < "$f" && (( total > pt )); then
    printf '%d%%' $(( 100 * ( (total - pt) - (idle - pi) ) / (total - pt) ))
  else
    printf -- '--'
  fi
  echo "$total $idle" > "$f"
}

# ---------------------------------------------------------------- RAM (used/total)
ram() {
  awk '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{printf "%.1f/%.0fG", (t-a)/1048576, t/1048576}' /proc/meminfo
}

# ---------------------------------------------------------------- network totals "rx tx"
net_bytes() {
  local out=""
  if (( IS_WSL )) && [[ -x "$WIN/netstat.exe" ]]; then
    # Whole-Windows totals. Language-independent: first row holding two numbers.
    out=$("$WIN/netstat.exe" -e 2>/dev/null | tr -d '\r' \
          | awk 'NF==3 && $2 ~ /^[0-9]+$/ && $3 ~ /^[0-9]+$/ {print $2, $3; exit}')
  fi
  if [[ -z "$out" ]]; then
    out=$(awk -F'[: ]+' 'NR>2 && $2!="lo" && $2 !~ /^(tun|wg|tap|docker|veth|br-|virbr)/ {rx+=$3; tx+=$11}
                         END{print rx+0, tx+0}' /proc/net/dev)
  fi
  echo "$out"
}

# ---------------------------------------------------------------- live up/down speed
net() {
  local now rx tx pnow prx ptx dt down up f="$CACHE/net"
  read -r rx tx < <(net_bytes)
  now=$(date +%s%N)
  if read -r pnow prx ptx 2>/dev/null < "$f" && (( now > pnow )); then
    dt=$(( (now - pnow) / 1000000 ))                       # ms
    (( dt < 1 )) && dt=1
    down=$(( (rx - prx) * 1000 / dt )); up=$(( (tx - ptx) * 1000 / dt ))
    (( down < 0 )) && down=0; (( up < 0 )) && up=0         # counter reset
    printf '↓%s ↑%s' "$(human "$down")" "$(human "$up")"
  else
    printf -- '↓-- ↑--'
  fi
  echo "$now $rx $tx" > "$f"
}

# ---------------------------------------------------------------- Wi-Fi "SSID signal rate" (uncached)
wifi_query() {
  local raw ssid sig rate
  if (( IS_WSL )) && [[ -x "$WIN/netsh.exe" ]]; then
    raw=$("$WIN/netsh.exe" wlan show interfaces 2>/dev/null | tr -d '\r')
    if grep -qi 'location' <<<"$raw"; then
      printf 'turn on Location'                            # Windows 11 hides Wi-Fi info without it
      return
    fi
    ssid=$(awk -F': ' '/^ *SSID /{print $2; exit}' <<<"$raw")
    sig=$(awk -F': '  '/^ *Signal/{print $2; exit}' <<<"$raw")
    rate=$(awk -F': ' '/Receive rate/{print $2; exit}' <<<"$raw")
    [[ -n "$ssid" ]] && printf '%s\t%s\t%s' "$ssid" "$sig" "${rate:+${rate%%.*}Mb}"
  elif command -v nmcli >/dev/null; then
    IFS=: read -r ssid sig rate < <(nmcli -t -f active,ssid,signal,rate dev wifi 2>/dev/null \
                                    | awk -F: '$1=="yes"{print $2":"$3":"$4; exit}')
    [[ -n "${ssid:-}" ]] && printf '%s\t%s%%\t%s' "$ssid" "$sig" "${rate:+${rate%% *}Mb}"
  fi
  return 0
}

# ---------------------------------------------------------------- background refresher (WSL)
# Runs net + Wi-Fi lookups detached from tmux, one at a time, and writes results to the cache.
refresh_async() {
  local lock="$CACHE/refresh.lock"
  if ! mkdir "$lock" 2>/dev/null; then
    (( $(age "$lock") > 30 )) && rmdir "$lock" 2>/dev/null   # clear a stale lock
    return
  fi
  (
    trap 'rmdir "$lock" 2>/dev/null' EXIT
    net > "$CACHE/net.out.tmp" && mv -f "$CACHE/net.out.tmp" "$CACHE/net.out"
    if (( $(age "$CACHE/wifi.out") >= WIFI_TTL )); then
      wifi_query > "$CACHE/wifi.out.tmp" && mv -f "$CACHE/wifi.out.tmp" "$CACHE/wifi.out"
    fi
  ) </dev/null >/dev/null 2>&1 &
  disown 2>/dev/null || true
}

# ---------------------------------------------------------------- battery
battery() {
  local d cap st icon col
  for d in /sys/class/power_supply/*; do
    [[ "$(cat "$d/type" 2>/dev/null)" == "Battery" ]] || continue
    cap=$(cat "$d/capacity" 2>/dev/null) || continue
    st=$(cat "$d/status" 2>/dev/null)
    if [[ "$st" == "Charging" ]]; then icon="BAT+"; else icon="BAT"; fi
    if   [[ "$st" == "Charging" || "$st" == "Full" ]]; then col=$GREEN
    elif (( cap < 20 )); then col=$RED
    elif (( cap < 40 )); then col=$YELLOW
    else col=$GREEN; fi
    seg "$col" "$icon" "${cap}%"
    return 0
  done
  return 1
}

# ---------------------------------------------------------------- VPN IP (tun/wg/tap inside WSL/Linux)
vpn() {
  ip -4 -o addr show 2>/dev/null | awk '$2 ~ /^(tun|wg|tap)/ {split($4, a, "/"); print a[1]; exit}'
}

# ---------------------------------------------------------------- gather
if (( IS_WSL )); then
  refresh_async                                             # updates cache for the next refresh
  netv=$(cat "$CACHE/net.out" 2>/dev/null); netv=${netv:-↓-- ↑--}
  w=$(cat "$CACHE/wifi.out" 2>/dev/null)
else
  netv=$(net)
  if (( $(age "$CACHE/wifi.out") >= WIFI_TTL )); then wifi_query > "$CACHE/wifi.out"; fi
  w=$(cat "$CACHE/wifi.out" 2>/dev/null)
fi

# ---------------------------------------------------------------- assemble (one parts+= per segment)
parts=()
v=$(vpn);  [[ -n "$v" ]] && parts+=("$(seg "$TEAL" "VPN" "$v")")
parts+=("$(seg "$SKY" "NET" "$netv")")
if [[ -n "$w" ]]; then
  IFS=$'\t' read -r ssid sig rate <<<"$w"
  if [[ -n "${sig:-}" ]]; then                        # normal case: shorten long SSIDs
    (( ${#ssid} > SSID_MAX )) && ssid="${ssid:0:SSID_MAX-2}.."
    w="$ssid $sig${rate:+ $rate}"
  fi
  parts+=("$(seg "$BLUE" "WiFi" "$w")")
fi
parts+=("$(seg "$RED" "CPU" "$(cpu)")")
parts+=("$(seg "$MAUVE" "RAM" "$(ram)")")
b=$(battery) && parts+=("$b")

out=""
for p in "${parts[@]}"; do
  [[ -n "$out" ]] && out+="#[fg=$DIM] │ "
  out+="$p"
done
printf '%s' "$out"
STATUS_EOF
chmod +x "$HOME/.config/tmux/scripts/tmux-status.sh"
log "Wrote ~/.config/tmux/scripts/tmux-status.sh"

# ---------------------------------------------------------------- .tmux.conf
backup "$HOME/.tmux.conf"
cat > "$HOME/.tmux.conf" <<'EOF'
# ---- generated by terminal-bootstrap.sh ----
# Prefix stays Ctrl+b (default)

# --- Mouse: OFF. No accidental clicks/pane switches, no leaked escape codes.
#     prefix + m toggles it when you actually want to drag-resize panes.
set -g mouse off
bind m set -g mouse \; display-message "Mouse: #{?mouse,ON,OFF}"

# Keyboard scrolling/copy: prefix + [  then PgUp/PgDn, / to search, v to select, y to copy, q to quit
setw -g mode-keys vi
bind -T copy-mode-vi v send -X begin-selection

# --- Terminal / input
set -g default-terminal "@TMUX_TERM@"
set -ga terminal-overrides ",*256col*:Tc,xterm*:Tc"
# 0 can split escape sequences on WSL/SSH and print garbage; 10ms is safe and still instant
set -sg escape-time 10
set -g focus-events on
set -g set-clipboard on
set -g history-limit 100000

# --- Windows & panes
set -g base-index 1
setw -g pane-base-index 1
set -g renumber-windows on
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display-message "Reloaded ~/.tmux.conf"

# --- Plugins (TPM)
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-yank'
set -g @plugin 'omerxx/tmux-sessionx'
set -g @plugin 'Morantron/tmux-fingers'

# Resurrect: prefix + Ctrl-s = save, prefix + Ctrl-r = restore
set -g @resurrect-capture-pane-contents 'on'

# SessionX: prefix + o opens the session picker (popup)
set -g @sessionx-bind 'o'
set -g @sessionx-zoxide-mode 'on'
set -g @sessionx-fzf-builtin-tmux 'on'
set -g @sessionx-window-height '85%'
set -g @sessionx-window-width '75%'

# Fingers: prefix + F = hint-copy, prefix + J = jump
set -g @fingers-key F
set -g @fingers-jump-key J

# --- Theme: Catppuccin v2 (needs a Nerd Font in your terminal for the icons)
set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style 'rounded'
run ~/.config/tmux/plugins/catppuccin/tmux/catppuccin.tmux
set -g status-left ""

# --- Bottom-right: VPN | NET ↓↑ | WiFi | CPU | RAM | BAT | date-time | session (plain text, no icons)
set -g status-interval 3
set -g status-right-length 250
set -g status-right "#(~/.config/tmux/scripts/tmux-status.sh)"
set -ag status-right "#[fg=#6c7086] │ #[fg=#cdd6f4]%a %d %b %H:%M "
# Session name as a plain pill (catppuccin's session module adds an icon that can overflow the bar)
set -ag status-right "#[fg=#11111b,bg=#a6e3a1,bold] #S #[default]"

# TPM must be the last plugin line
run '~/.tmux/plugins/tpm/tpm'

# Re-assert after plugins load so nothing can stop the bar from refreshing on its own
set -g status on
set -g status-interval 3
EOF
sed -i "s/@TMUX_TERM@/$TMUX_TERM/" "$HOME/.tmux.conf"
log "Wrote ~/.tmux.conf (default-terminal: $TMUX_TERM)"

# ---------------------------------------------------------------- default shell
ZSH_BIN="$(command -v zsh)"
CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
if [[ "$CURRENT_SHELL" != "$ZSH_BIN" ]]; then
  log "Setting zsh as your default shell (may ask for your password)..."
  chsh -s "$ZSH_BIN" || warn "chsh failed - run: chsh -s $ZSH_BIN"
fi

# Reload tmux config if a server is already running
if tmux info >/dev/null 2>&1; then tmux source-file "$HOME/.tmux.conf" || true; fi

cat <<'MSG'

=====================================================
 Bootstrap complete.

 1. Set a Nerd Font in your terminal (e.g. "JetBrainsMono Nerd Font").
 2. Close ALL terminal windows and run:  tmux kill-server
    then open a new terminal.
 3. tmux-fingers shows a one-time setup wizard on first load:
    pick "Download a standalone binary".
 4. Import old history into atuin:  atuin import auto

 Keys (prefix = Ctrl+b)
   prefix o         session picker (sessionx)
   prefix F / J     copy / jump with hints (fingers)
   prefix m         toggle mouse
   prefix [         scroll / copy mode (q to exit)
   prefix Ctrl-s/r  save / restore sessions
   Ctrl-r           search history (atuin)

 Full guide: README.md
=====================================================
MSG
