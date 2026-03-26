#!/usr/bin/env zsh
# ct — Terminal Task Tagger
# https://github.com/Lang-Julian/ct
#
# Visual task identification for fast terminal switching.
# iTerm2/WezTerm: background image + badge + tab color
# Any terminal: title + ASCII art
#
# Usage:  ct <name>     Tag terminal (icon auto-generated on first use)
#         ct            Show current task + context
#         ct help       Full help
#         ct list       Show all tasks
#         ct log        Show task history
#         ct clear      Reset terminal

CT_VERSION="1.0.0"

_CT_DIR="${CT_DIR:-$HOME/.ct}"
_CT_ICON_DIR="${_CT_DIR}/icons"

# State — preserved across re-source
[[ -z "$_CT_CURRENT" ]]    && _CT_CURRENT=""
[[ -z "$_CT_ACTIVE" ]]     && _CT_ACTIVE=0
[[ -z "$_CT_LAST_PROMPT" ]]&& _CT_LAST_PROMPT=0
_CT_IDLE=${CT_IDLE:-600}   # idle threshold in seconds (default: 10 min)

zmodload zsh/datetime 2>/dev/null

# ─── Pre-built tasks ────────────────────────────────────────────
# Format: key  "label;r;g;b;icon_file"

typeset -gA _CT_TASKS
_CT_TASKS=(
    deploy    "Deploy;220;60;60;deploy"
    api       "API;30;100;220;api"
    web       "Frontend;40;180;70;web"
    site      "Frontend;40;180;70;web"
    frontend  "Frontend;40;180;70;web"
    infra     "Infrastructure;220;170;30;infra"
    security  "Security;200;40;70;security"
    data      "Data;240;130;20;data"
    docs      "Docs;140;60;200;docs"
)

# ─── Load user config (optional) ────────────────────────────────

[[ -f "${_CT_DIR}/config.zsh" ]] && source "${_CT_DIR}/config.zsh"

# ─── Reserved subcommands (not valid task names) ────────────────

_CT_RESERVED=(help -h --help version clear reset list ls log delete rm)

# ─── Parse task definition ──────────────────────────────────────

_ct_parse() {
    local def="${_CT_TASKS[$1]}"
    [[ -z "$def" ]] && return 1
    local rest
    _p_label="${def%%;*}"; rest="${def#*;}"
    _p_r="${rest%%;*}"; rest="${rest#*;}"
    _p_g="${rest%%;*}"; rest="${rest#*;}"
    _p_b="${rest%%;*}"; _p_icon="${rest#*;}"
    return 0
}

# ─── Slug: safe filename from any input (pure zsh, no subshells) ─

_ct_slug() {
    local s="${1//[^a-zA-Z0-9_-]/-}"
    s="${(L)s}"              # lowercase
    s="${s//--##/-}"         # collapse multiple dashes
    s="${s#-}"; s="${s%-}"   # strip leading/trailing dash
    [[ -z "$s" ]] && s="unnamed"
    echo "$s"
}

# ─── Hash-based color for custom tasks (injection-safe) ──────────

_ct_hash_rgb() {
    local result
    result="$(python3 - "$1" <<'PYEOF'
import sys, hashlib, colorsys
h = int(hashlib.sha256(sys.argv[1].encode()).hexdigest()[:8], 16)
r, g, b = colorsys.hls_to_rgb((h % 360) / 360, .5, .7)
print(f'{int(r*255)};{int(g*255)};{int(b*255)}')
PYEOF
)" 2>/dev/null
    echo "${result:-120;120;180}"
}

# ─── Timer (smart: only counts active time between prompts) ──────

_ct_fmt_duration() {
    local secs="${1:-0}" hrs mins
    hrs=$(( secs / 3600 ))
    mins=$(( (secs % 3600) / 60 ))
    if (( hrs > 0 )); then echo "${hrs}h ${mins}m"
    elif (( mins > 0 )); then echo "${mins}m"
    elif (( secs > 0 )); then echo "${secs}s"
    else echo "0s"; fi
}

_ct_tick() {
    [[ -z "$_CT_CURRENT" ]] && return
    local now
    if (( ${+EPOCHSECONDS} )); then
        now=$EPOCHSECONDS
    else
        now=$(date +%s)
    fi
    if (( _CT_LAST_PROMPT > 0 )); then
        local gap=$(( now - _CT_LAST_PROMPT ))
        (( gap > 0 && gap < _CT_IDLE )) && (( _CT_ACTIVE += gap ))
    fi
    _CT_LAST_PROMPT=$now
}

_ct_active_time() {
    (( _CT_ACTIVE > 0 )) || { echo "0s"; return; }
    _ct_fmt_duration "$_CT_ACTIVE"
}

# ─── Task log ────────────────────────────────────────────────────

_ct_log_entry() {
    mkdir -p "$_CT_DIR"
    echo "$(date '+%Y-%m-%d %H:%M')|$1|$2|$3" >> "${_CT_DIR}/log"
}

_ct_log_end_current() {
    [[ -z "$_CT_CURRENT" ]] && return
    _ct_tick
    _ct_log_entry "end" "$_CT_CURRENT" "$(_ct_active_time)"
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
    _ct_tick

    local badge="${(U)_CT_CURRENT}"
    badge+=$'\n'

    local short_path="${PWD/#$HOME/~}"
    if [[ "$short_path" == */*/* ]]; then
        short_path="…/${PWD:h:t}/${PWD:t}"
    fi
    badge+=$'\n'"$short_path"
    badge+=$'\n'"$(_ct_active_time)"

    _ct_badge "$badge"
    _ct_title "◈ $_CT_CURRENT"
}

# Register precmd hook (safe: no duplicates)
autoload -Uz add-zsh-hook 2>/dev/null
if (( $+functions[add-zsh-hook] )); then
    add-zsh-hook precmd _ct_precmd
elif [[ ! " ${precmd_functions[*]} " == *" _ct_precmd "* ]]; then
    precmd_functions+=(_ct_precmd)
fi

# ─── Icon generation ─────────────────────────────────────────────

_ct_ensure_icon() {
    local slug="$(_ct_slug "$1")"
    local icon_path="${_CT_ICON_DIR}/${slug}.png"

    [[ -f "$icon_path" ]] && echo "$icon_path" && return 0

    if ! command -v python3 &>/dev/null; then return 1; fi
    if ! python3 -c "from PIL import Image" 2>/dev/null; then
        if [[ ! -f "${_CT_DIR}/.pillow-warned" ]]; then
            echo -e "\033[33m  pip install Pillow for background images\033[0m" >&2
            touch "${_CT_DIR}/.pillow-warned" 2>/dev/null
        fi
        return 1
    fi

    mkdir -p "$_CT_ICON_DIR"
    local gen_script="${_CT_DIR}/gen-icons.py"
    if [[ -f "$gen_script" ]]; then
        python3 "$gen_script" --task "$1" --out "$icon_path" 2>/dev/null
    else
        python3 - "$1" "$icon_path" <<'PYEOF'
import sys, hashlib, colorsys, os
from PIL import Image, ImageDraw, ImageFont
name, out = sys.argv[1], sys.argv[2]
os.makedirs(os.path.dirname(out), exist_ok=True)
W, H, A = 1000, 800, 65
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
    local task="$1" label="$2" r="\033[0m"
    case "$task" in
        deploy) echo -e "\033[1;31m
           ╱╲
          ╱  ╲
         │ ◈◈ │
         │    │
        ╱└────┘╲
       ╱   ▓▓   ╲
     D E P L O Y${r}" ;;
        api) echo -e "\033[1;34m
          ●
         ╱│╲
        ╱ │ ╲
       ●──●──●
        ╲ │ ╱
         ╲│╱
          ●${r}" ;;
        web|site|frontend) echo -e "\033[1;32m
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
        security) echo -e "\033[1;31m
         ╱────╲
        ╱╱    ╲╲
       ╱╱  ◈◈  ╲╲
       ║   ██   ║
       ╲╲  ▼▼  ╱╱
        ╲╲    ╱╱
         ╲────╱${r}" ;;
        data) echo -e "\033[38;5;208m
              ┃
           ┃  ┃
        ┃  ┃  ┃  ┃
     ┃  ┃  ┃  ┃  ┃
     ┻──┻──┻──┻──┻──
       D A T A   ▲${r}" ;;
        docs) echo -e "\033[1;35m
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
    # No args — show current task or brief help
    if [[ -z "$1" || "$1" =~ ^[[:space:]]+$ ]]; then
        if [[ -n "$_CT_CURRENT" ]]; then
            _ct_tick
            local branch="$(git branch --show-current 2>/dev/null)"
            echo ""
            echo -e "  \033[1;37m◈ $_CT_CURRENT\033[0m"
            echo ""
            [[ -n "$branch" ]] && echo -e "  \033[34m  $branch\033[0m"
            echo -e "  \033[2m  ${PWD/#$HOME/~}\033[0m"
            echo -e "  \033[33m  $(_ct_active_time) active\033[0m"
            echo ""
        else
            echo ""
            echo "  ct <name>     Tag terminal"
            echo "  ct help       Full help"
            echo ""
        fi
        return 0
    fi

    local task="${1:l}"

    # ── Help
    if [[ "$task" == "help" || "$task" == "-h" || "$task" == "--help" ]]; then
        cat <<HELPEOF

  ct — context tag (v${CT_VERSION})
  Tag terminals, not tabs.

  USAGE
    ct <name>           Tag this terminal (icon auto-generated)
    ct                  Show current task + branch + path + timer
    ct clear            Reset (remove background, badge, tab color)
    ct list             Show all tasks (pre-built + custom)
    ct delete <name>    Delete a cached custom icon
    ct log [N]          Task history (last N entries, default 20)
    ct log clear        Clear history
    ct help             This help
    ct version          Version

  HOW IT WORKS
    Any name works. First use generates an icon automatically.
    Custom tasks get semantic icons (deploy → rocket, debug → bug,
    docker → whale, meeting → headset, etc.) or unique geometric shapes.
    Icons are cached in ~/.ct/icons/ — instant after first use.

  SMART TIMER
    Only counts active focus time. Idle gaps are excluded.
    Gap > 10 min between prompts = you were away (not counted).
    Threshold: export CT_IDLE=300  (5 min, default: 600)

  BADGE (iTerm2 / WezTerm)
    Updates every prompt:  task · path · active time

  CONFIG
    ~/.ct/config.zsh — add custom tasks with fixed colors:
      _CT_TASKS+=( myapp "My App;80;140;220;myapp" )

  UNINSTALL
    rm -rf ~/.ct
    Remove the source line from ~/.zshrc

HELPEOF
        return 0
    fi

    # ── Version
    if [[ "$task" == "version" || "$task" == "-v" || "$task" == "--version" ]]; then
        echo "  ct $CT_VERSION"
        return 0
    fi

    # ── List (dynamic from _CT_TASKS)
    if [[ "$task" == "list" || "$task" == "ls" ]]; then
        echo ""
        echo -e "  \033[1mTasks:\033[0m"
        # Collect unique tasks (prefer shortest key per icon)
        local -A icon_to_key icon_to_def
        local key def icon
        for key in ${(k)_CT_TASKS}; do
            def="${_CT_TASKS[$key]}"
            icon="${def##*;}"
            if [[ -z "${icon_to_key[$icon]}" ]] || (( ${#key} < ${#${icon_to_key[$icon]}} )); then
                icon_to_key[$icon]="$key"
                icon_to_def[$icon]="$def"
            fi
        done
        for icon in ${(ko)icon_to_key}; do
            key="${icon_to_key[$icon]}"
            def="${icon_to_def[$icon]}"
            local label="${def%%;*}"
            local rest="${def#*;}"
            local r="${rest%%;*}"; rest="${rest#*;}"
            local g="${rest%%;*}"; rest="${rest#*;}"
            local b="${rest%%;*}"
            printf "    %-12s %-20s \033[38;2;%d;%d;%dm████\033[0m\n" "$key" "$label" "$r" "$g" "$b"
        done
        if [[ -d "$_CT_ICON_DIR" ]]; then
            local -a customs
            local f name
            for f in "${_CT_ICON_DIR}"/*.png(N); do
                name="${f:t:r}"
                [[ -n "${icon_to_key[$name]}" ]] && continue
                customs+=("$name")
            done
            if (( ${#customs} > 0 )); then
                echo ""
                echo -e "  \033[1mCustom (cached):\033[0m"
                local c
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
        # ct log clear
        if [[ "$2" == "clear" ]]; then
            rm -f "${_CT_DIR}/log"
            echo -e "\n  \033[2mLog cleared.\033[0m\n"
            return 0
        fi
        if [[ ! -f "${_CT_DIR}/log" ]]; then
            echo -e "\n  \033[2mNo task history yet.\033[0m\n"
            return 0
        fi
        local n="${2:-20}"
        echo ""
        echo -e "  \033[1mTask History:\033[0m"
        echo ""
        tail -"$n" "${_CT_DIR}/log" | while IFS='|' read -r ts action label duration; do
            if [[ "$action" == "start" ]]; then
                echo -e "  \033[32m▶\033[0m $ts  \033[1m$label\033[0m"
            elif [[ "$action" == "end" ]]; then
                echo -e "  \033[31m■\033[0m $ts  \033[2m$label\033[0m  ($duration)"
            fi
        done
        if [[ -n "$_CT_CURRENT" ]]; then
            _ct_tick
            echo ""
            echo -e "  \033[33m●\033[0m now       \033[1m$_CT_CURRENT\033[0m  ($(_ct_active_time) active)"
        fi
        echo ""
        return 0
    fi

    # ── Delete cached icon
    if [[ "$task" == "delete" || "$task" == "rm" ]]; then
        if [[ -z "$2" ]]; then
            echo -e "\n  Usage: ct delete <name>\n"
            return 1
        fi
        local del_slug="$(_ct_slug "${2:l}")"
        local del_path="${_CT_ICON_DIR}/${del_slug}.png"
        if [[ -f "$del_path" ]]; then
            rm -f "$del_path"
            echo -e "\n  \033[2mDeleted: $del_slug\033[0m\n"
        else
            echo -e "\n  \033[2mNot found: $del_slug\033[0m\n"
        fi
        return 0
    fi

    # ── Clear / Reset
    if [[ "$task" == "clear" || "$task" == "reset" ]]; then
        if [[ -n "$_CT_CURRENT" ]]; then
            _ct_log_end_current
        fi
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

    # ── Validate task name
    local slug="$(_ct_slug "$task")"

    # ── Same task? Skip re-logging but reset timer
    if [[ -n "$_CT_CURRENT" ]] && {
       [[ "$_CT_CURRENT" == "${_CT_TASKS[$task]%%;*}" ]] ||
       [[ "$_CT_CURRENT" == "$1" ]]
    }; then
        _CT_ACTIVE=0
        if (( ${+EPOCHSECONDS} )); then _CT_LAST_PROMPT=$EPOCHSECONDS; else _CT_LAST_PROMPT=$(date +%s); fi
        echo -e "\n  \033[1;37m◈ $_CT_CURRENT\033[0m  (timer reset)\n"
        return 0
    fi

    # ── Log end of previous task
    _ct_log_end_current

    # ── Resolve task
    local label rgb_r rgb_g rgb_b icon_file
    if _ct_parse "$task"; then
        label="$_p_label"
        rgb_r="$_p_r"; rgb_g="$_p_g"; rgb_b="$_p_b"
        icon_file="$_p_icon"
    else
        label="$1"
        local rgb="$(_ct_hash_rgb "$slug")"
        local rest
        rgb_r="${rgb%%;*}"; rest="${rgb#*;}"
        rgb_g="${rest%%;*}"; rgb_b="${rest#*;}"
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
    if (( ${+EPOCHSECONDS} )); then _CT_LAST_PROMPT=$EPOCHSECONDS; else _CT_LAST_PROMPT=$(date +%s); fi
    _ct_log_entry "start" "$label" ""

    echo ""
    echo -e "  \033[1;37m◈ $label\033[0m"
    echo ""
}

# ─── Tab completion ──────────────────────────────────────────────

_ct_complete() {
    local -a tasks
    # All keys from _CT_TASKS
    tasks=(${(k)_CT_TASKS})
    # Subcommands
    tasks+=(clear reset list log help version delete)
    # Cached custom icons
    if [[ -d "$_CT_ICON_DIR" ]]; then
        local f name
        for f in "${_CT_ICON_DIR}"/*.png(N); do
            name="${f:t:r}"
            [[ -z "${_CT_TASKS[$name]}" ]] && tasks+=("$name")
        done
    fi
    _describe 'task' tasks
}
compdef _ct_complete ct 2>/dev/null
