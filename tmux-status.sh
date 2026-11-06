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
