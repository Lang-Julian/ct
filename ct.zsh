#!/usr/bin/env zsh
# ct — Terminal Task Tagger
# Visual task identification for fast terminal switching.
# Supports iTerm2 (background image + badge + tab color) and any terminal (title + ASCII art).
#
# Usage:  ct <name>     Tag terminal (any name — icon auto-generated on first use)
#         ct clear      Reset everything
#         ct list       Show all tasks with icons
#         ct log        Show task history with durations
#         ct            Show current task + timer

_CT_DIR="${CT_DIR:-$HOME/.ct}"
_CT_ICON_DIR="${_CT_DIR}/icons"
_CT_CURRENT=""
_CT_ACTIVE=0           # accumulated active seconds
_CT_LAST_PROMPT=0      # timestamp of last prompt
_CT_IDLE=${CT_IDLE:-600}  # seconds before a gap counts as idle (default: 10 min)

zmodload zsh/datetime 2>/dev/null  # for EPOCHSECONDS

# ─── Pre-built tasks ────────────────────────────────────────────
# Format:  key  "label;r;g;b;icon_file"

typeset -gA _CT_TASKS
_CT_TASKS=(
    box       "AI in the Box;30;100;220;box"
    aitb      "AI in the Box;30;100;220;box"
    li        "LinkedIn;0;119;181;li"
    linkedin  "LinkedIn;0;119;181;li"
    web       "Website;40;180;70;web"
    site      "Website;40;180;70;web"
    infra     "Infrastruktur;220;170;30;infra"
    brane     "Brane AIF;200;40;70;brane"
    sales     "Sales;240;130;20;sales"
    content   "Content;140;60;200;content"
)

# ─── Load user config (optional) ────────────────────────────────

[[ -f "${_CT_DIR}/config.zsh" ]] && source "${_CT_DIR}/config.zsh"

# ─── Parse task definition ──────────────────────────────────────

_ct_parse() {
    local def="${_CT_TASKS[$1]}"
    if [[ -n "$def" ]]; then
        _p_label="${def%%;*}"; local rest="${def#*;}"
        _p_r="${rest%%;*}"; rest="${rest#*;}"
        _p_g="${rest%%;*}"; rest="${rest#*;}"
        _p_b="${rest%%;*}"; _p_icon="${rest#*;}"
        return 0
    fi
    return 1
}

# ─── Hash-based color for custom tasks ──────────────────────────

_ct_hash_rgb() {
    python3 -c "
import hashlib, colorsys
h=int(hashlib.sha256('$1'.encode()).hexdigest()[:8],16)
r,g,b=colorsys.hls_to_rgb((h%360)/360,.5,.7)
print(f'{int(r*255)};{int(g*255)};{int(b*255)}')
" 2>/dev/null || echo "120;120;180"
}

# ─── Slug: safe filename from any input ─────────────────────────

_ct_slug() {
    echo "${1//[^a-zA-Z0-9_-]/-}" | tr '[:upper:]' '[:lower:]' | sed 's/--*/-/g;s/^-//;s/-$//'
}

# ─── Timer (smart: only counts active time between prompts) ──────
#
# How it works:
# - Every prompt (precmd), we check the gap since last prompt
# - Gap < CT_IDLE (default 10 min) → active time, add to counter
# - Gap >= CT_IDLE → you were away (sleep, meeting, other window), skip
# - Result: only real focus time is counted

_ct_now() {
    if (( ${+EPOCHSECONDS} )); then
        echo "$EPOCHSECONDS"
    else
        date +%s
    fi
}

_ct_fmt_duration() {
    local secs="$1"
    local hrs=$(( secs / 3600 ))
    local mins=$(( (secs % 3600) / 60 ))
    if (( hrs > 0 )); then
        echo "${hrs}h ${mins}m"
    elif (( mins > 0 )); then
        echo "${mins}m"
    else
        echo "<1m"
    fi
}

_ct_tick() {
    # Called every precmd — accumulates active time
    [[ -z "$_CT_CURRENT" ]] && return
    local now="$(_ct_now)"
    if (( _CT_LAST_PROMPT > 0 )); then
        local gap=$(( now - _CT_LAST_PROMPT ))
        if (( gap > 0 && gap < _CT_IDLE )); then
            (( _CT_ACTIVE += gap ))
        fi
    fi
    _CT_LAST_PROMPT=$now
}

_ct_active_time() {
    # Returns formatted active time
    (( _CT_ACTIVE > 0 )) || { echo "<1m"; return; }
    _ct_fmt_duration "$_CT_ACTIVE"
}

# ─── Task log ────────────────────────────────────────────────────

_ct_log_entry() {
    local action="$1" label="$2" duration="$3"
    local ts="$(date '+%Y-%m-%d %H:%M')"
    mkdir -p "$_CT_DIR"
    echo "${ts}|${action}|${label}|${duration}" >> "${_CT_DIR}/log"
}

_ct_log_end_current() {
    [[ -z "$_CT_CURRENT" ]] && return
    _ct_tick  # capture final gap
    local elapsed="$(_ct_active_time)"
    _ct_log_entry "end" "$_CT_CURRENT" "$elapsed"
}

# ─── iTerm2 / WezTerm escape sequences ──────────────────────────

_ct_has_iterm_proto() {
    [[ "$TERM_PROGRAM" == "iTerm.app" || "$TERM_PROGRAM" == "WezTerm" ]]
}

_ct_badge() {
    _ct_has_iterm_proto || return
    printf "\e]1337;SetBadgeFormat=%s\a" "$(echo -n "$1" | base64)"
}

_ct_tab_color() {
    _ct_has_iterm_proto || return
    printf "\e]6;1;bg;red;brightness;%s\a" "$1"
    printf "\e]6;1;bg;green;brightness;%s\a" "$2"
    printf "\e]6;1;bg;blue;brightness;%s\a" "$3"
}

_ct_tab_color_reset() {
    _ct_has_iterm_proto || return
    printf "\e]6;1;bg;*;default\a"
}

_ct_bg_image() {
    _ct_has_iterm_proto || return
    if [[ -n "$1" && -f "$1" ]]; then
        printf "\e]1337;SetBackgroundImageFile=%s\a" "$(echo -n "$1" | base64)"
    else
        printf "\e]1337;SetBackgroundImageFile=\a"
    fi
}

_ct_title() {
    printf "\033]0;%s\007" "$1"
}

# ─── Dynamic badge (updated every prompt) ───────────────────────

_ct_precmd() {
    [[ -z "$_CT_CURRENT" ]] && return

    # Tick the timer (smart: skips idle gaps)
    _ct_tick

    local badge="$_CT_CURRENT"

    # Git branch
    local branch
    branch="$(git branch --show-current 2>/dev/null)"
    [[ -n "$branch" ]] && badge+=$'\n'"$branch"

    # Short path (last 2 components)
    local short_path="${PWD/#$HOME/~}"
    if [[ "$short_path" == */*/* ]]; then
        local parent="${${PWD:h}:t}"
        short_path="…/${parent}/${PWD:t}"
    fi
    badge+=$'\n'"$short_path"

    # Active time
    local active="$(_ct_active_time)"
    badge+=$'\n'"$active"

    _ct_badge "$badge"
    _ct_title "◈ $_CT_CURRENT"
}

# Register precmd hook
autoload -Uz add-zsh-hook 2>/dev/null
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _ct_precmd
else
    precmd_functions+=(_ct_precmd)
fi

# ─── Icon generation (transparent, automatic) ───────────────────

_ct_ensure_icon() {
    local task="$1"
    local slug="$(_ct_slug "$task")"
    local icon_path="${_CT_ICON_DIR}/${slug}.png"

    [[ -f "$icon_path" ]] && echo "$icon_path" && return 0

    if ! python3 -c "from PIL import Image" 2>/dev/null; then
        if [[ ! -f "${_CT_DIR}/.pillow-warned" ]]; then
            echo -e "\033[33m  Pillow nicht gefunden — pip install Pillow fuer Background-Images\033[0m" >&2
            touch "${_CT_DIR}/.pillow-warned" 2>/dev/null
        fi
        return 1
    fi

    mkdir -p "$_CT_ICON_DIR"

    local gen_script="${_CT_DIR}/gen-icons.py"
    if [[ -f "$gen_script" ]]; then
        python3 "$gen_script" --task "$task" --out "$icon_path" 2>/dev/null
    else
        python3 - "$task" "$icon_path" <<'PYEOF'
import sys, hashlib, colorsys, os
from PIL import Image, ImageDraw, ImageFont
name, out = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(out), exist_ok=True)
W, H, A = 1000, 800, 38
h = int(hashlib.sha256(name.encode()).hexdigest()[:8], 16)
r, g, b = colorsys.hls_to_rgb((h % 360) / 360, 0.5, 0.7)
c = (int(r*255), int(g*255), int(b*255), A)
img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rounded_rectangle([W//2-250, H//2-150, W//2+250, H//2+100], radius=25, outline=c, width=5)
txt = name.upper().replace("-", " ").replace("_", " ")
for p in ["~/Library/Fonts/JetBrainsMonoNerdFontPropo-Bold.ttf", "/System/Library/Fonts/Menlo.ttc"]:
    try:
        f = ImageFont.truetype(os.path.expanduser(p), min(64, max(32, 700 // max(len(txt), 1))))
        break
    except: f = ImageFont.load_default()
bb = d.textbbox((0, 0), txt, font=f)
d.text(((W-(bb[2]-bb[0]))//2, H//2-50), txt, fill=c, font=f)
img.save(out)
PYEOF
    fi

    [[ -f "$icon_path" ]] && echo "$icon_path" || return 1
}

# ─── ASCII art fallback ─────────────────────────────────────────

_ct_ascii() {
    local task="$1" label="$2"
    local r="\033[0m"
    case "$task" in
        box|aitb) echo -e "\033[1;34m
        ╭───────────────╮
       ╱│              ╱│
      ╱ │   ◈  A I   ╱ │
     ╭───────────────╮  │
     │  │   I N      │  │
     │  ╰────────────│──╯
     │ ╱    B O X    │ ╱
     ╰───────────────╯${r}" ;;
        li|linkedin) echo -e "\033[1;36m
     ╔═══════════════╗
     ║  ██           ║
     ║  ██  ███████  ║
     ║  ██  ██   ██  ║
     ║  ██  ██   ██  ║
     ╚═══════════════╝${r}" ;;
        web|site) echo -e "\033[1;32m
     ┌── ● ● ● ──────────┐
     │  ┌──────────────┐  │
     │  │   ╱──●──╲    │  │
     │  │  ●───┼───●   │  │
     │  │   ╲──●──╱    │  │
     │  └──────────────┘  │
     └────────────────────┘${r}" ;;
        infra) echo -e "\033[1;33m
     ┌───────────────────┐
     │ ▪▪▪ ═══════  ◉ ◉ │
     ├───────────────────┤
     │ ▪▪▪ ═══════  ◉ ◉ │
     ├───────────────────┤
     │ ▪▪▪ ═══════  ◉ ◉ │
     └────────┬──────────┘
        ══════╧══════${r}" ;;
        brane) echo -e "\033[1;31m
          ╱╲
         ╱╱╲╲
        ╱╱◈◈╲╲
       ╱╱ AIF ╲╲
       ╲╲─────╱╱
        ╲─────╱${r}" ;;
        sales) echo -e "\033[38;5;208m
              ┃
           ┃  ┃
        ┃  ┃  ┃  ┃
     ┃  ┃  ┃  ┃  ┃
     ┻──┻──┻──┻──┻──
      S A L E S  ▲${r}" ;;
        content) echo -e "\033[1;35m
     ┌──────────────────┐
     │ ≡≡≡≡≡≡≡≡≡≡≡≡≡≡ │
     │ ≡≡≡≡≡≡≡≡≡≡     │
     │ ≡≡≡≡≡≡≡≡≡≡≡≡≡  │
     │ ≡≡≡≡≡≡≡≡       │
     └──────────────────┘✎${r}" ;;
        *) echo -e "\033[1;37m
     ╔══════════════════╗
     ║  $(printf '%-16s' "${(U)label}")║
     ╚══════════════════╝${r}" ;;
    esac
}

# ─── Main ────────────────────────────────────────────────────────

ct() {
    # No args — show current task + context
    if [[ -z "$1" ]]; then
        if [[ -n "$_CT_CURRENT" ]]; then
            _ct_tick
            local active="$(_ct_active_time)"
            local branch="$(git branch --show-current 2>/dev/null)"
            local short_path="${PWD/#$HOME/~}"
            echo ""
            echo -e "  \033[1;37m◈ $_CT_CURRENT\033[0m"
            [[ -n "$branch" ]] && echo -e "  \033[34m$branch\033[0m"
            echo -e "  \033[2m$short_path\033[0m"
            echo -e "  \033[33m$active active\033[0m"
            echo ""
        else
            echo ""
            echo "  ct <name>     Tag terminal (icon auto-generated)"
            echo "  ct clear      Reset"
            echo "  ct list       Show all"
            echo "  ct log        Task history"
            echo ""
            echo "  Pre-built:  box  li  web  infra  brane  sales  content"
            echo "  Custom:     ct deploy  ct debug  ct whatever"
            echo ""
        fi
        return 0
    fi

    local task="${1:l}"

    # ── List
    if [[ "$task" == "list" || "$task" == "ls" ]]; then
        echo ""
        echo -e "  \033[1mPre-built:\033[0m"
        echo -e "    box         AI in the Box     \033[34m████\033[0m"
        echo -e "    li          LinkedIn          \033[36m████\033[0m"
        echo -e "    web         Website           \033[32m████\033[0m"
        echo -e "    infra       Infrastruktur     \033[33m████\033[0m"
        echo -e "    brane       Brane AIF         \033[31m████\033[0m"
        echo -e "    sales       Sales             \033[38;5;208m████\033[0m"
        echo -e "    content     Content           \033[35m████\033[0m"
        if [[ -d "$_CT_ICON_DIR" ]]; then
            local -a customs
            for f in "${_CT_ICON_DIR}"/*.png(N); do
                local name="${f:t:r}"
                [[ "$name" == (box|li|web|infra|brane|sales|content) ]] && continue
                customs+=("$name")
            done
            if (( ${#customs} > 0 )); then
                echo ""
                echo -e "  \033[1mCustom (cached):\033[0m"
                for c in "${customs[@]}"; do
                    echo "    $c"
                done
            fi
        fi
        echo ""
        return 0
    fi

    # ── Log
    if [[ "$task" == "log" ]]; then
        if [[ ! -f "${_CT_DIR}/log" ]]; then
            echo -e "\n  \033[2mNo task history yet.\033[0m\n"
            return 0
        fi
        echo ""
        echo -e "  \033[1mTask History:\033[0m"
        echo ""
        # Show last 20 entries, formatted
        tail -20 "${_CT_DIR}/log" | while IFS='|' read -r ts action label duration; do
            if [[ "$action" == "start" ]]; then
                echo -e "  \033[32m▶\033[0m $ts  \033[1m$label\033[0m"
            elif [[ "$action" == "end" ]]; then
                echo -e "  \033[31m■\033[0m $ts  \033[2m$label\033[0m  ($duration)"
            fi
        done
        # Show current if active
        if [[ -n "$_CT_CURRENT" ]]; then
            _ct_tick
            local active="$(_ct_active_time)"
            echo ""
            echo -e "  \033[33m●\033[0m now       \033[1m$_CT_CURRENT\033[0m  ($active active)"
        fi
        echo ""
        return 0
    fi

    # ── Clear / Reset
    if [[ "$task" == "clear" || "$task" == "reset" ]]; then
        _ct_log_end_current
        _ct_badge ""
        _ct_tab_color_reset
        _ct_bg_image ""
        _ct_title "Terminal"
        _CT_CURRENT=""
        _CT_ACTIVE=0
        _CT_LAST_PROMPT=0
        echo -e "\n  \033[2mReset.\033[0m\n"
        return 0
    fi

    # ── Log end of previous task
    _ct_log_end_current

    # ── Resolve task
    local label rgb_r rgb_g rgb_b icon_file slug
    slug="$(_ct_slug "$task")"

    if _ct_parse "$task"; then
        label="$_p_label"
        rgb_r="$_p_r"; rgb_g="$_p_g"; rgb_b="$_p_b"
        icon_file="$_p_icon"
    else
        label="$1"
        local rgb="$(_ct_hash_rgb "$slug")"
        rgb_r="${rgb%%;*}"; local _rest="${rgb#*;}"
        rgb_g="${_rest%%;*}"; rgb_b="${_rest#*;}"
        icon_file="$slug"
    fi

    # ── Icon (auto-generate if needed)
    local icon_path=""
    icon_path="$(_ct_ensure_icon "$icon_file" 2>/dev/null)"

    # ── Apply
    if _ct_has_iterm_proto; then
        [[ -n "$icon_path" && -f "$icon_path" ]] && _ct_bg_image "$icon_path"
        _ct_badge "$label"
        _ct_tab_color "$rgb_r" "$rgb_g" "$rgb_b"
    else
        _ct_ascii "$task" "$label"
    fi

    _ct_title "◈ $label"
    _CT_CURRENT="$label"
    _CT_ACTIVE=0
    _CT_LAST_PROMPT="$(_ct_now)"

    # Log start
    _ct_log_entry "start" "$label" ""

    echo ""
    echo -e "  \033[1;37m◈ $label\033[0m"
    echo ""
}

# ─── Tab completion ──────────────────────────────────────────────

_ct_complete() {
    local -a tasks
    tasks=(box li web infra brane sales content clear list log)
    if [[ -d "$_CT_ICON_DIR" ]]; then
        for f in "${_CT_ICON_DIR}"/*.png(N); do
            local name="${f:t:r}"
            [[ "$name" == (box|li|web|infra|brane|sales|content) ]] && continue
            tasks+=("$name")
        done
    fi
    _describe 'task' tasks
}
compdef _ct_complete ct 2>/dev/null
