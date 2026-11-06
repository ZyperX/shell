# Terminal Setup

A fast, keyboard-driven terminal for Debian/Ubuntu and WSL: **zsh + Oh My Zsh + Starship + tmux**, with fuzzy search everywhere, searchable history, and no stray mouse input.

One script installs and configures everything. It is safe to re-run.

## Repository files

| File | Purpose |
|---|---|
| `terminal-bootstrap.sh` | The installer. Run this. |
| `tmux-status.sh` | Status bar script (also embedded in the installer). Copy to `~/.config/tmux/scripts/` to update it on its own. |
| `starship-xiong-chiamiov.toml` | Optional prompt theme recreating Oh My Zsh's *xiong-chiamiov* (see [Alternative prompt theme](#alternative-prompt-theme-xiong-chiamiov)). |
| `.gitattributes` | Keeps Unix line endings so the scripts still run if committed from Windows. |

---

## Contents

1. [What you get](#what-you-get)
2. [Requirements](#requirements)
3. [Install](#install)
4. [First run checklist](#first-run-checklist)
5. [Files it creates](#files-it-creates)
6. [Cheatsheet: tmux](#cheatsheet-tmux)
7. [Cheatsheet: tmux plugins](#cheatsheet-tmux-plugins)
8. [The tmux status bar](#the-tmux-status-bar)
9. [Cheatsheet: shell (zsh)](#cheatsheet-shell-zsh)
10. [Cheatsheet: CLI tools](#cheatsheet-cli-tools)
11. [The prompt (Starship)](#the-prompt-starship) (and the [xiong-chiamiov theme](#alternative-prompt-theme-xiong-chiamiov))
12. [Customizing](#customizing)
13. [Troubleshooting](#troubleshooting)
14. [Updating](#updating)
15. [Rolling back](#rolling-back)

---

## What you get

| Layer | Tool | What it does |
|---|---|---|
| Shell | **zsh** + **Oh My Zsh** | Shell and plugin framework |
| Prompt | **Starship** | Fast prompt: directory, git, language, VPN IP, command time, exit code |
| Multiplexer | **tmux** | Sessions, windows and panes that survive closing the terminal |
| History | **atuin** | Full-screen, searchable history on `Ctrl-r` |
| Fuzzy finder | **fzf** (latest) | `Ctrl-t` files, `Alt-c` directories, used by many plugins |
| Completion | **fzf-tab** | Every `Tab` completion becomes a fuzzy list with previews |
| Typing help | **zsh-autosuggestions** | Grey suggestions from history as you type |
| | **zsh-syntax-highlighting** | Valid commands green, typos red, before you press Enter |
| | **history-substring-search** | ↑/↓ search history by what you've already typed |
| | **zsh-completions** | Extra completion definitions |
| | **you-should-use** | Reminds you when an alias exists for what you typed |
| OMZ plugins | **git**, **sudo**, **extract**, **fzf** | Git aliases, `Esc Esc` for sudo, one-command unzip |
| Navigation | **zoxide** | `z proj` jumps to your most-used matching folder |
| tmux plugins | **tmux-sensible** | Sane defaults |
| | **tmux-resurrect** | Save and restore sessions across reboots |
| | **tmux-yank** | Copy to the system clipboard |
| | **tmux-sessionx** | Fuzzy session picker with preview |
| | **tmux-fingers** | Copy IPs, URLs, hashes from the screen with letter hints |
| | **catppuccin** | Status bar theme (Mocha) |
| Status bar | **tmux-status.sh** (custom) | Bottom right: VPN IP, live ↓↑ speed, Wi-Fi, CPU, RAM, battery, date/time |
| Modern CLI | **eza**, **bat**, **ripgrep**, **fd**, **btop**, **jq** | Better `ls`, `cat`, `grep`, `find`, `top`, JSON tool |

**Mouse is off in tmux on purpose.** No accidental pane switches, no junk characters. Toggle it with `prefix m` when you need it.

---

## Requirements

- Debian, Ubuntu, or Ubuntu on WSL2
- A user with `sudo`
- A **Nerd Font** set in your terminal (for icons). Recommended: *JetBrainsMono Nerd Font* from <https://www.nerdfonts.com>.
  On Windows Terminal: Settings → your Ubuntu profile → Appearance → Font face.

---

## Install

```bash
chmod +x terminal-bootstrap.sh
./terminal-bootstrap.sh
```

Run it as your normal user, not with `sudo`. It asks for your password when needed.

What it does, in order:

1. Installs apt packages (skips any your release doesn't have instead of failing)
2. Installs eza, zoxide, fzf, atuin and Starship from their official sources
3. Installs Oh My Zsh and the zsh plugins
4. Writes `~/.zshrc`, `~/.config/starship.toml`, `~/.tmux.conf` (old ones are backed up)
5. Clones all tmux plugins (no need to press `prefix I`)
6. Sets zsh as your default shell

---

## First run checklist

1. Set a Nerd Font in your terminal.
2. Close **all** terminal windows, then from any shell run `tmux kill-server`.
3. Open a new terminal. You should land in a tmux session called `main` with the Starship prompt.
4. **tmux-fingers wizard:** the first time it loads, it asks how to install its binary. Choose **"Download a standalone binary"**.
5. Import your old history: `atuin import auto`
6. Optional: set up history sync (see [atuin](#atuin--history-search)).

---

## Files it creates

| File | Purpose |
|---|---|
| `~/.zshrc` | Shell config |
| `~/.config/starship.toml` | Prompt config |
| `~/.tmux.conf` | tmux config |
| `~/.oh-my-zsh/custom/plugins/` | zsh plugins |
| `~/.tmux/plugins/` | tmux plugins (TPM) |
| `~/.config/tmux/plugins/catppuccin/` | tmux theme |
| `~/.config/tmux/scripts/tmux-status.sh` | Status bar info (CPU, RAM, network, Wi-Fi, battery, VPN) |
| `~/.fzf/` | fzf (binary in `~/.fzf/bin`) |
| `~/.atuin/` | atuin binary |
| `~/.local/bin/starship` | Starship binary |
| `*.bak.YYYYMMDD-HHMMSS` | Backups of anything overwritten |

---

## Cheatsheet: tmux

**Prefix = `Ctrl+b`.** Press it, release, then press the key.

### Sessions

| Keys | Action |
|---|---|
| `prefix o` | **Session picker** (sessionx) |
| `prefix d` | Detach (session keeps running) |
| `prefix $` | Rename session |
| `prefix s` | Built-in session list |
| `prefix (` / `)` | Previous / next session |
| `tmux new -s name` | New named session (from a shell) |
| `tmux a -t name` | Attach to a session |
| `tmux ls` | List sessions |
| `tmux kill-session -t name` | Kill a session |

### Windows (tabs)

| Keys | Action |
|---|---|
| `prefix c` | New window (in current directory) |
| `prefix n` / `p` | Next / previous window |
| `prefix 1`…`9` | Go to window number |
| `prefix w` | Window list with preview |
| `prefix ,` | Rename window |
| `prefix &` | Kill window |

### Panes (splits)

| Keys | Action |
|---|---|
| `prefix \|` | Split side by side (current directory) |
| `prefix -` | Split top/bottom (current directory) |
| `prefix ←↑↓→` | Move to pane |
| `prefix Ctrl+←↑↓→` | Resize pane (hold Ctrl, tap arrows) |
| `prefix z` | Zoom pane full screen / back |
| `prefix x` | Kill pane |
| `prefix q` | Show pane numbers (press a number to jump) |
| `prefix Space` | Cycle layouts |
| `prefix {` / `}` | Swap pane left / right |
| `prefix !` | Turn pane into its own window |

### Scroll and copy (copy mode, vi keys)

| Keys | Action |
|---|---|
| `prefix [` | Enter copy mode |
| `PgUp` / `PgDn`, `Ctrl-u` / `Ctrl-d` | Scroll page / half page |
| `g` / `G` | Top / bottom of history |
| `/` then text | Search down (`?` searches up); `n` / `N` next / previous match |
| `v` | Start selection |
| `y` | Copy selection to system clipboard |
| `q` | Exit copy mode |

### Other

| Keys | Action |
|---|---|
| `prefix m` | **Toggle mouse** on/off |
| `prefix r` | Reload `~/.tmux.conf` |
| `prefix :` | tmux command prompt |
| `prefix ?` | List every key binding |

---

## Cheatsheet: tmux plugins

### sessionx — session picker

`prefix o` opens a popup with your sessions and a live preview.

| Keys (inside picker) | Action |
|---|---|
| type + `Enter` | Switch to the matching session |
| new name + `Enter` | Create a session with that name |
| folder name + `Enter` | zoxide match → new session in that folder |
| `Ctrl-p` / `Ctrl-n` | Move up / down |
| `Ctrl-r` | Rename session |
| `Alt-Backspace` | Kill session |
| `Ctrl-w` | Show all windows |
| `Ctrl-t` | Tree of sessions and windows |
| `Ctrl-u` / `Ctrl-d` | Scroll preview |
| `?` | Toggle preview |
| `Esc` | Close |

Tip: one session per target or project (`acme-recon`, `notes`, `tools`), each with its own windows.

### tmux-fingers — copy from the screen

| Keys | Action |
|---|---|
| `prefix F` | Highlight IPs, URLs, paths, hashes, UUIDs with letter hints |
| letter | Copy that match |
| `Shift` + letter | Paste it straight into the prompt |
| `Ctrl` + letter | Open it (URLs) |
| `Tab` … `Tab` | Multi-select, then copy all |
| `prefix J` | Jump: move the copy-mode cursor to a match |
| `q` / `Esc` | Cancel |

### tmux-resurrect — survive reboots

| Keys | Action |
|---|---|
| `prefix Ctrl-s` | Save all sessions, windows, panes, directories and pane text |
| `prefix Ctrl-r` | Restore the last save |

Save before shutting down WSL or rebooting. It does not autosave.

### tmux-yank — clipboard

| Keys | Action |
|---|---|
| `y` (in copy mode) | Copy selection to system clipboard |
| `prefix y` | Copy the current command line |
| `prefix Y` | Copy the current pane's directory |

---

## The tmux status bar

The bottom-right of the tmux bar shows live system info, refreshed every 3 seconds:

```
VPN 10.10.14.7 │ NET ↓1.2M ↑40K │ WiFi Rishi's Gala.. 100% 866Mb │ CPU 12% │ RAM 3.1/16G │ BAT+ 98% │ Fri 06 Nov 22:18  main
```

| Segment | Meaning | Where it comes from |
|---|---|---|
| `VPN 10.10.14.7` | VPN IP (only shown when connected) | `tun*`, `wg*` or `tap*` interface inside WSL/Linux |
| `NET ↓1.2M ↑40K` | Live download / upload speed, per second | On WSL: **whole Windows machine** (`netstat.exe -e`). On Linux: all real interfaces |
| `WiFi Rishi's Gala.. 100% 866Mb` | Wi-Fi name (shortened past 14 characters), signal strength, link speed to the router | On WSL: Windows (`netsh.exe`), refreshed every 20s. On Linux: `nmcli` |
| `CPU 12%` | CPU usage | Linux side (on WSL: the WSL VM, i.e. your tools, not all of Windows) |
| `RAM 3.1/16G` | RAM used / total | Linux side (on WSL: memory given to WSL) |
| `BAT 87%` / `BAT+ 98%` | Battery; `+` means charging | `/sys/class/power_supply`; hidden on desktops |
| `Fri 06 Nov 22:18` | Date and time | tmux |
| `main` | Current tmux session name | tmux |

**Why text labels instead of icons:** Nerd Font icons can be drawn wider than tmux counts them. On a full-width bar that pushes the last few characters past the screen edge, and the terminal then scrolls on every refresh, printing the bar over and over. Plain labels always measure correctly.

On WSL, the Windows lookups (Wi-Fi and network totals) run in a detached background job and the bar reads their cached results, so tmux never waits on Windows. Network speed therefore lags one refresh (about 3 seconds) behind.

Battery colour: green when charging or above 40%, yellow below 40%, red below 20%.

**Link speed vs live speed:** `866Mb` is the connection rate between your laptop and the router (the maximum possible). `↓1.2M` is what's actually being downloaded right now, in megabytes per second.

**VPN on Windows vs WSL:** the VPN segment shows VPNs running *inside* WSL (e.g. `sudo openvpn lab.ovpn`). A VPN app running on Windows doesn't create a `tun0` inside WSL, so it won't appear.

---

## Cheatsheet: shell (zsh)

### Line editing

| Keys | Action |
|---|---|
| `→` or `End` | Accept the whole grey suggestion |
| `Alt-f` / `Ctrl-→` | Accept the suggestion one word at a time |
| `↑` / `↓` | History matching what you've typed (`nmap` + ↑) |
| `Esc Esc` | Add `sudo` to the start of the line (or the last command) |
| `Ctrl-a` / `Ctrl-e` | Start / end of line |
| `Ctrl-w` | Delete previous word |
| `Ctrl-u` | Delete whole line |
| `Alt-.` | Insert last argument of previous command |
| `Ctrl-l` / `cls` | Clear screen |
| `Ctrl-x Ctrl-e` | Edit the current command in `$EDITOR` |

### atuin — history search

| Keys / command | Action |
|---|---|
| `Ctrl-r` | Open full-screen history search |
| type | Filter (fuzzy) |
| `Ctrl-r` (inside) | Cycle scope: global → host → session → directory |
| `Enter` | Run the command (or place it on the prompt, depending on `enter_accept` in `~/.config/atuin/config.toml`) |
| `Tab` | Put it on the prompt to edit |
| `Esc` | Close |
| `atuin import auto` | Import existing zsh history (once) |
| `atuin stats` | Most-used commands |
| `atuin search <text>` | Search from the command line |

**Sync between machines (optional).** History is local by default. To share it between WSL and a VPS:

```bash
atuin register -u <user> -e <email>   # on the first machine
atuin login -u <user>                 # on the others
atuin sync
```

History is end-to-end encrypted; keep the key shown by `atuin key` safe. You can also self-host the atuin server so history never leaves your machines.

Prefix a command with a **space** to keep it out of zsh history (useful for commands with tokens).

### fzf

| Keys | Action |
|---|---|
| `Ctrl-t` | Fuzzy-find a file, insert its path |
| `Alt-c` | Fuzzy-find a directory and `cd` into it |
| inside fzf: `Ctrl-j` / `Ctrl-k` | Move down / up |
| inside fzf: `Tab` | Mark multiple items |

### fzf-tab — fuzzy Tab completion

Press `Tab` after anything: `cd`, `git checkout`, `kill`, `ssh`, `docker`, file arguments.

| Keys | Action |
|---|---|
| type | Filter the list |
| `Enter` | Accept |
| `Ctrl-Space` | Select multiple |
| `<` / `>` | Switch completion group |
| `/` | Accept a directory and keep completing inside it |

`cd` + `Tab` shows a preview of each folder's contents.

### zoxide — smart cd

| Command | Action |
|---|---|
| `z proj` | Jump to the most-used folder matching "proj" |
| `z foo bar` | Match folders containing both words |
| `zi` | Interactive picker (fzf) |
| `z -` | Previous directory |
| `z ..` | Normal `cd` behaviour still works |

It learns from every `cd`, so it gets better over time.

### extract

| Command | Action |
|---|---|
| `x file.tar.gz` / `extract file.zip` | Unpack any archive type |

### you-should-use

No keys. Type `git status` in full and it reminds you: *You should use: `gst`*. Run `alias` to see everything available, or `alias | rg git` for git only.

### Common git aliases (Oh My Zsh)

| Alias | Command |
|---|---|
| `gst` | `git status` |
| `ga` / `gaa` | `git add` / `git add --all` |
| `gcmsg "msg"` | `git commit -m "msg"` |
| `gp` / `gl` | `git push` / `git pull` |
| `gco` / `gcb name` | `git checkout` / `git checkout -b name` |
| `gsw` | `git switch` |
| `gd` | `git diff` |
| `glog` | Pretty one-line graph log |
| `gcl` | `git clone --recurse-submodules` |

### Custom aliases

| Alias | Runs |
|---|---|
| `ls` | `eza --icons --group-directories-first` |
| `ll` | Long list with hidden files and git status |
| `la` | Long list with hidden files |
| `lt` | Tree, 2 levels |
| `cat` | `bat --paging=never` (syntax highlighting) |
| `ports` | `ss -tulpen` (listening ports + processes) |
| `myip` | Your public IP |
| `weather` | Weather in the terminal |
| `update` | `sudo apt update && sudo apt upgrade -y` |
| `cls` | `clear` |

`grep` and `find` are **not** aliased, so scripts and pasted one-liners keep working. Use `rg` and `fd` directly.

---

## Cheatsheet: CLI tools

| Tool | Example | What it does |
|---|---|---|
| `rg` | `rg -i "api_key" .` | Fast recursive search, respects `.gitignore` |
| | `rg -l TODO` | Only list matching files |
| | `rg -uu secret` | Include hidden and ignored files |
| `fd` | `fd config` | Find files by name |
| | `fd -e js` | By extension |
| | `fd -H .env` | Include hidden files |
| `bat` | `bat file.py` | View with syntax highlighting and line numbers |
| | `bat -A file` | Show invisible characters |
| `eza` | `lt`, `eza -l --git` | Listings with icons and git status |
| `jq` | `cat out.json \| jq '.[] .host'` | Query JSON |
| `btop` | `btop` | System monitor |
| `fzf` | `cat urls.txt \| fzf` | Fuzzy-pick from any list |

---

## The prompt (Starship)

Example:

```
~/work/acme  main !2 ?1   3.12  󰖂 10.10.14.7 took 5s
❯
```

| Part | Meaning |
|---|---|
| `user@host` | Only shown over SSH or as root (root is red) |
| Directory | Truncated to the repo root inside git repos; lock icon if read-only |
| ` main` | Git branch |
| `!2 ?1` | Git status: `!` modified, `?` untracked, `+` staged, `⇡⇣` ahead/behind |
| ` 3.12` | Python version / virtualenv (also Node, Go, Rust, Docker when relevant) |
| `󰖂 10.10.14.7` | Your VPN `tun0` IP, only when connected |
| `took 5s` | Shown for commands longer than 2 seconds |
| `✦` | Background jobs running |
| `✘ 1` (right side) | Exit code of a failed command |
| `❯` | Green after success, red after failure |

Config file: `~/.config/starship.toml`. Changes apply on the next prompt, no restart needed.

### Alternative prompt theme: xiong-chiamiov

`starship-xiong-chiamiov.toml` recreates the classic Oh My Zsh theme, with git, Python, VPN IP and command-duration blocks that appear only when relevant:

```
┌─[user@host] - [~/work/acme] - [Fri Nov 06, 22:18] - [ main ?] - [took 5s]
└─[$]>
```

The `$` turns red when the last command failed. To use it:

```bash
cp ~/.config/starship.toml ~/.config/starship.toml.mine
cp starship-xiong-chiamiov.toml ~/.config/starship.toml
```

Re-running the installer replaces `starship.toml` with the default theme, so copy it back afterwards.

---

## Customizing

**Starship**

- Use a different VPN interface: edit `[custom.vpn]` and replace `tun0`.
- Show the time: add `$time` to `right_format` and add a `[time]` section with `disabled = false`.
- Try a preset: `starship preset --list`, then `starship preset <name> -o ~/.config/starship.toml` (this replaces the provided config).
- Debug slow prompts: `starship timings`.

**tmux**

- Turn the mouse on permanently: change `set -g mouse off` to `on` in `~/.tmux.conf`.
- Add autosave: add `set -g @plugin 'tmux-plugins/tmux-continuum'` and `set -g @continuum-restore 'on'`, then `prefix I`.
- Change theme flavour: `@catppuccin_flavor` → `latte`, `frappe`, `macchiato` or `mocha`.
- Status bar refresh rate: `set -g status-interval 3` in `~/.tmux.conf` (seconds).
- Shorten or lengthen Wi-Fi names: change `SSID_MAX=14` near the top of `~/.config/tmux/scripts/tmux-status.sh`.
- Remove or reorder status segments: edit the `assemble` section at the bottom of `~/.config/tmux/scripts/tmux-status.sh`. Each segment is one `parts+=` line; delete a line to hide it, move it to reorder.
- Change the date/time format: edit the `%a %d %b %H:%M` part of `status-right` in `~/.tmux.conf` (standard `strftime` codes, e.g. `%H:%M:%S` for seconds).

**zsh**

- Disable tmux auto-start for one shell: `NO_TMUX=1 zsh`. To disable permanently, delete the auto-start block at the top of `~/.zshrc`.
- Add your own aliases at the bottom of `~/.zshrc`.

Re-running the script **overwrites** `~/.zshrc`, `~/.tmux.conf` and `~/.config/starship.toml` (with backups). Keep personal additions in the script itself, or copy them back from the `.bak` file.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Junk like `^[[<35;12;8M` appears | Should be gone (mouse off + reset hook). If it happens once, press `Enter`; the next prompt resets it. Make sure you ran `tmux kill-server` after installing. |
| Icons show as boxes or `?` | Set a Nerd Font in your terminal settings. |
| Mouse wheel doesn't scroll in tmux | Expected (mouse is off). Use `prefix [` + `PgUp`, or `prefix m` to turn mouse on. |
| Old prompt (p10k) still showing | Run `tmux kill-server`, open a new terminal. Remove leftovers with `rm -rf ~/.oh-my-zsh/custom/themes/powerlevel10k ~/.p10k.zsh`. |
| `prefix o` does nothing / errors | sessionx needs the new fzf: check `fzf --version` and `which fzf-tmux`. Then `tmux kill-server`. |
| `prefix F` does nothing | The fingers binary isn't installed yet. Reload with `prefix r` to bring the setup wizard back and pick "Download a standalone binary". If it still doesn't appear: `rm -rf ~/.tmux/plugins/tmux-fingers`, re-run the script, then `tmux kill-server`. |
| `Ctrl-r` shows the old fzf list | atuin isn't on PATH: open a new terminal, or check `~/.atuin/bin/atuin --version`. |
| Colors look wrong in tmux | Check `echo $TERM` inside tmux shows `tmux-256color` or `screen-256color`, and your terminal supports truecolor. |
| Wi-Fi shows "turn on Location" | Windows 11 hides Wi-Fi details from command-line tools unless Location is on. Windows Settings → Privacy & security → Location → turn on **Location services** and **Let desktop apps access your location**. |
| No Wi-Fi segment at all | You're on Ethernet, Wi-Fi is off, or (on native Linux) `nmcli` isn't installed. |
| No battery segment | Desktop PC, or WSL can't see the battery: check `ls /sys/class/power_supply`. |
| Status bar blank or only updates when you press a key | Check `tmux show -g status-interval` prints `3` (not `0`), and that `~/.config/tmux/scripts/tmux-status.sh` runs instantly (`time ~/.config/tmux/scripts/tmux-status.sh`). Then `tmux kill-server` and reopen. |
| Network speed shows `↓-- ↑--` | Normal for the first refresh after tmux starts; it fills in 3 seconds later. |
| Status bar repeats up the screen / last word wraps to a new line | The bar is wider than the window. Remove segments or lower `SSID_MAX` (see [Customizing](#customizing)), or reduce the font size. Never add Nerd Font icons to the bar: they cause this. |
| Clipboard copy doesn't reach Windows | Windows Terminal supports OSC 52 out of the box; make sure "Allow writing to clipboard" isn't disabled. |
| tmux opens inside VS Code terminal | It shouldn't (it's skipped there). If it does, check `echo $TERM_PROGRAM`. |
| Shell still bash | `chsh -s $(which zsh)`, then log out and back in (on WSL: `wsl --shutdown` from Windows). |

---

## Updating

| What | How |
|---|---|
| tmux plugins | `prefix U`, then type `all` |
| zsh plugins | `omz update` (Oh My Zsh), and `git -C <plugin dir> pull` for custom plugins |
| fzf | `cd ~/.fzf && git pull && ./install --bin` (or re-run the script) |
| Starship | `curl -sS https://starship.rs/install.sh \| sh -s -- -y -b ~/.local/bin` |
| atuin | Re-run the installer: `curl --proto '=https' --tlsv1.2 -LsSf https://setup.atuin.sh \| sh` |
| Everything else | `update` |

---

## Rolling back

Every overwritten config is saved next to the original:

```bash
ls ~/.zshrc.bak.* ~/.tmux.conf.bak.* ~/.config/starship.toml.bak.*
cp ~/.zshrc.bak.20261106-215400 ~/.zshrc   # pick the timestamp you want
```

Then `tmux kill-server` and open a new terminal.
