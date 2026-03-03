#!/usr/bin/env zsh
# ct — Claude Terminal Task Tagger
# Visual task identification for fast terminal switching.
# Supports iTerm2 (background image + badge + tab color) with fallback for other terminals.
#
# Usage:  ct <task>     Set task tag (any name works, icons auto-generated)
#         ct clear      Reset everything
#         ct list       Show available pre-built icons
#         ct            Show help

_CT_DIR="${CT_DIR:-$HOME/.ct}"
_CT_ICON_DIR="${_CT_DIR}/icons"

# ─── Pre-built task definitions ──────────────────────────────────

typeset -gA _CT_LABELS _CT_TAB_RGB _CT_ICON_FILE _CT_ANSI

_CT_LABELS=(
    box       "AI in the Box"
    aitb      "AI in the Box"
    li        "LinkedIn"
    linkedin  "LinkedIn"
    web       "Website"
    site      "Website"
    infra     "Infrastruktur"
    brane     "Brane AIF"
    sales     "Sales"
    content   "Content"
)

_CT_TAB_RGB=(
    box       "30;100;220"
    aitb      "30;100;220"
    li        "0;119;181"
    linkedin  "0;119;181"
    web       "40;180;70"
    site      "40;180;70"
    infra     "220;170;30"
    brane     "200;40;70"
    sales     "240;130;20"
    content   "140;60;200"
)

_CT_ICON_FILE=(
    box       "box"
    aitb      "box"
    li        "li"
    linkedin  "li"
    web       "web"
    site      "web"
    infra     "infra"
    brane     "brane"
    sales     "sales"
    content   "content"
)

_CT_ANSI=(
    box       "\033[1;34m"
    aitb      "\033[1;34m"
    li        "\033[1;36m"
    linkedin  "\033[1;36m"
    web       "\033[1;32m"
    site      "\033[1;32m"
    infra     "\033[1;33m"
    brane     "\033[1;31m"
    sales     "\033[38;5;208m"
    content   "\033[1;35m"
)

# ─── iTerm2 escape sequences ────────────────────────────────────

_ct_is_iterm() { [[ "$TERM_PROGRAM" == "iTerm.app" ]] }

_ct_badge() {
    _ct_is_iterm || return
    printf "\e]1337;SetBadgeFormat=%s\a" "$(echo -n "$1" | base64)"
}

_ct_tab_color() {
    _ct_is_iterm || return
    local r="${1%%;*}" rest="${1#*;}"
    local g="${rest%%;*}" b="${rest#*;}"
    printf "\e]6;1;bg;red;brightness;%s\a" "$r"
    printf "\e]6;1;bg;green;brightness;%s\a" "$g"
    printf "\e]6;1;bg;blue;brightness;%s\a" "$b"
}

_ct_tab_color_reset() {
    _ct_is_iterm || return
    printf "\e]6;1;bg;*;default\a"
}

_ct_bg_image() {
    _ct_is_iterm || return
    if [[ -n "$1" && -f "$1" ]]; then
        printf "\e]1337;SetBackgroundImageFile=%s\a" "$(echo -n "$1" | base64)"
    else
        printf "\e]1337;SetBackgroundImageFile=\a"
    fi
}

_ct_title() {
    printf "\033]0;%s\007" "$1"
}

# ─── Icon generation ─────────────────────────────────────────────

_ct_gen_icon() {
    local task="$1"
    local out_path="${_CT_ICON_DIR}/${task}.png"

    # Already exists — skip
    [[ -f "$out_path" ]] && echo "$out_path" && return 0

    # Need python3 + PIL
    if ! python3 -c "from PIL import Image" 2>/dev/null; then
        echo "" && return 1
    fi

    mkdir -p "$_CT_ICON_DIR"

    python3 "${_CT_DIR}/gen-icons.py" --task "$task" --out "$out_path" 2>/dev/null

    if [[ -f "$out_path" ]]; then
        echo "$out_path"
    else
        echo ""
        return 1
    fi
}

# ─── ASCII fallback (non-iTerm2 terminals) ───────────────────────

_ct_ascii_fallback() {
    local task="$1" label="$2"
    local c="${_CT_ANSI[$task]:-\033[1;37m}"
    local r="\033[0m"

    case "$task" in
        box|aitb)
            cat <<EOF
$(echo -e "${c}")
        ╭───────────────╮
       ╱│              ╱│
      ╱ │   ◈  A I   ╱ │
     ╭───────────────╮  │
     │  │            │  │
     │  │   I N      │  │
     │  │     T H E  │  │
     │  ╰────────────│──╯
     │ ╱    B O X    │ ╱
     │╱              │╱
     ╰───────────────╯
$(echo -e "${r}")
EOF
            ;;
        li|linkedin)
            cat <<EOF
$(echo -e "${c}")
     ╔═════════════════╗
     ║                 ║
     ║   ██            ║
     ║   ██            ║
     ║                 ║
     ║   ██  ███████   ║
     ║   ██  ██   ██   ║
     ║   ██  ██   ██   ║
     ║   ██  ██   ██   ║
     ║                 ║
     ╚═════════════════╝
$(echo -e "${r}")
EOF
            ;;
        web|site)
            cat <<EOF
$(echo -e "${c}")
     ┌─── ● ● ● ───────────┐
     │  ┌───────────────┐  │
     │  │    ╱ ─── ╲    │  │
     │  │   ╱ ╱   ╲ ╲   │  │
     │  │──●───────●──│  │
     │  │   ╲ ╲   ╱ ╱   │  │
     │  │    ╲ ─── ╱    │  │
     │  └───────────────┘  │
     └─────────────────────┘
$(echo -e "${r}")
EOF
            ;;
        infra)
            cat <<EOF
$(echo -e "${c}")
     ┌─────────────────────┐
     │ ▪▪▪  ════════  ◉ ◉ │
     ├─────────────────────┤
     │ ▪▪▪  ════════  ◉ ◉ │
     ├─────────────────────┤
     │ ▪▪▪  ════════  ◉ ◉ │
     ├─────────────────────┤
     │ ▪▪▪  ════════  ◉ ◉ │
     └──────────┬──────────┘
          ══════╧══════
$(echo -e "${r}")
EOF
            ;;
        brane)
            cat <<EOF
$(echo -e "${c}")
            ╱╲
           ╱  ╲
          ╱ ╱╲ ╲
         ╱ ╱  ╲ ╲
        ╱ ╱ ◈◈ ╲ ╲
       ╱ ╱      ╲ ╲
      ╱  ╱ BRANE  ╲ ╲
     ╱  ╱   AIF    ╲ ╲
     ╲  ╲──────────╱ ╱
      ╲  ╲────────╱ ╱
       ╲──────────╱
$(echo -e "${r}")
EOF
            ;;
        sales)
            cat <<EOF
$(echo -e "${c}")
                   ┃
                ┃  ┃
             ┃  ┃  ┃
             ┃  ┃  ┃  ┃
          ┃  ┃  ┃  ┃  ┃
       ┃  ┃  ┃  ┃  ┃  ┃
       ┃  ┃  ┃  ┃  ┃  ┃
       ┻──┻──┻──┻──┻──┻───
        S  A  L  E  S   ▲
$(echo -e "${r}")
EOF
            ;;
        content)
            cat <<EOF
$(echo -e "${c}")
     ┌────────────────────┐
     │ ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡  │
     │ ≡≡≡≡≡≡≡≡≡≡≡      │
     │                    │
     │ ≡≡≡≡≡≡≡≡≡≡≡≡≡≡≡  │
     │ ≡≡≡≡≡≡≡≡≡≡≡≡     │
     │ ≡≡≡≡≡≡≡≡         │╲
     │ ≡≡≡≡≡            │ ╲
     └────────────────────┘✎
$(echo -e "${r}")
EOF
            ;;
        *)
            local upper="${(U)task}"
            cat <<EOF
$(echo -e "${c}")
     ╔════════════════════╗
     ║                    ║
     ║   $(printf '%-16s' "$upper")║
     ║                    ║
     ╚════════════════════╝
$(echo -e "${r}")
EOF
            ;;
    esac
}

# ─── Main function ───────────────────────────────────────────────

ct() {
    if [[ -z "$1" ]]; then
        echo ""
        echo "  ct <task>     Set task (any name — icons auto-generated)"
        echo "  ct clear      Reset terminal"
        echo "  ct list       Show pre-built tasks"
        echo ""
        echo "  Pre-built:  box  li  web  infra  brane  sales  content"
        echo "  Custom:     ct my-project  ct debug  ct whatever"
        echo ""
        return 0
    fi

    local task="${1:l}"

    # ── List
    if [[ "$task" == "list" || "$task" == "ls" ]]; then
        echo ""
        echo "  Pre-built tasks:"
        echo "    box / aitb      AI in the Box       (blue)"
        echo "    li / linkedin   LinkedIn             (cyan)"
        echo "    web / site      Website              (green)"
        echo "    infra           Infrastruktur        (yellow)"
        echo "    brane           Brane AIF            (red)"
        echo "    sales           Sales                (orange)"
        echo "    content         Content              (purple)"
        echo ""
        echo "  Custom icons in: $_CT_ICON_DIR/"
        if [[ -d "$_CT_ICON_DIR" ]]; then
            local customs=("${_CT_ICON_DIR}"/*.png(N))
            if (( ${#customs} > 0 )); then
                echo "  Generated: $(ls "$_CT_ICON_DIR"/*.png | xargs -I{} basename {} .png | tr '\n' ' ')"
            fi
        fi
        echo ""
        return 0
    fi

    # ── Clear / Reset
    if [[ "$task" == "clear" || "$task" == "reset" ]]; then
        _ct_badge ""
        _ct_tab_color_reset
        _ct_bg_image ""
        _ct_title "Terminal"
        echo -e "\n  \033[2mTerminal reset.\033[0m\n"
        return 0
    fi

    local label="${_CT_LABELS[$task]:-$1}"
    local rgb="${_CT_TAB_RGB[$task]:-100;100;100}"

    # ── Resolve icon
    local icon_key="${_CT_ICON_FILE[$task]}"
    local icon_path=""

    if [[ -n "$icon_key" ]]; then
        icon_path="${_CT_ICON_DIR}/${icon_key}.png"
        # Generate pre-built icon if missing
        if [[ ! -f "$icon_path" ]]; then
            icon_path="$(_ct_gen_icon "$icon_key")"
        fi
    else
        # Custom task — auto-generate
        icon_path="$(_ct_gen_icon "$task")"
    fi

    # ── Apply
    if _ct_is_iterm; then
        [[ -n "$icon_path" && -f "$icon_path" ]] && _ct_bg_image "$icon_path"
        _ct_badge "$label"
        _ct_tab_color "$rgb"
    else
        _ct_ascii_fallback "$task" "$label"
    fi

    _ct_title "◈ $label"

    echo ""
    echo -e "  \033[1;37m◈ $label\033[0m"
    if _ct_is_iterm; then
        echo -e "  \033[2mBackground + Badge + Tab gesetzt.\033[0m"
    else
        echo -e "  \033[2mTitle gesetzt.\033[0m"
    fi
    echo ""
}
