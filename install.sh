#!/usr/bin/env bash
set -e

CT_DIR="$HOME/.ct"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Colors
R='\033[0m' B='\033[1;34m' G='\033[1;32m' Y='\033[1;33m' D='\033[2m' W='\033[1;37m'

echo ""
echo -e "${B}        ┌──────────────────────────────┐${R}"
echo -e "${B}        │                              │${R}"
echo -e "${B}        │    ${W}██████╗ ████████╗${B}         │${R}"
echo -e "${B}        │    ${W}██╔════╝ ╚══██╔══╝${B}         │${R}"
echo -e "${B}        │    ${W}██║        ██║${B}            │${R}"
echo -e "${B}        │    ${W}██║        ██║${B}            │${R}"
echo -e "${B}        │    ${W}╚██████╗   ██║${B}            │${R}"
echo -e "${B}        │     ${W}╚═════╝   ╚═╝${B}            │${R}"
echo -e "${B}        │                              │${R}"
echo -e "${B}        │  ${D}context tag ${R}${D}— tag terminals,${B}  │${R}"
echo -e "${B}        │  ${D}not tabs.${B}                    │${R}"
echo -e "${B}        │                              │${R}"
echo -e "${B}        └──────────────────────────────┘${R}"
echo ""

# ── Check zsh
if ! command -v zsh &>/dev/null; then
    echo -e "  ${Y}error: ct requires zsh${R}"
    exit 1
fi

# ── Install files
mkdir -p "$CT_DIR/icons"
cp "$SCRIPT_DIR/ct.zsh" "$CT_DIR/ct.zsh"
cp "$SCRIPT_DIR/gen-icons.py" "$CT_DIR/gen-icons.py"
chmod +x "$CT_DIR/gen-icons.py"
echo -e "  ${G}✓${R} Installed to ${D}$CT_DIR${R}"

# ── Generate pre-built icons
if python3 -c "from PIL import Image" 2>/dev/null; then
    echo -ne "  ${D}Generating icons${R}"
    for name in box li web infra brane sales content; do
        python3 "$CT_DIR/gen-icons.py" --task "$name" --out "$CT_DIR/icons/${name}.png" 2>/dev/null
        echo -ne "${G}.${R}"
    done
    echo -e " ${G}✓${R}"
else
    echo ""
    echo -e "  ${Y}Optional:${R} pip install Pillow"
    echo -e "  ${D}Enables background images in iTerm2/WezTerm.${R}"
    echo -e "  ${D}Without it: badge + tab color + ASCII art still work.${R}"
fi

# ── Shell config
SOURCE_LINE='[[ -f "$HOME/.ct/ct.zsh" ]] && source "$HOME/.ct/ct.zsh"'

if [[ -f "$HOME/.zshrc" ]]; then
    if grep -qF ".ct/ct.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo -e "  ${G}✓${R} .zshrc already configured"
    else
        echo "" >> "$HOME/.zshrc"
        echo "# ct — context tag (https://github.com/Lang-Julian/ct)" >> "$HOME/.zshrc"
        echo "$SOURCE_LINE" >> "$HOME/.zshrc"
        echo -e "  ${G}✓${R} Added to .zshrc"
    fi
else
    echo ""
    echo -e "  Add to your ${W}.zshrc${R}:"
    echo -e "    $SOURCE_LINE"
fi

echo ""
echo -e "  ${W}Ready.${R} Activate now:"
echo ""
echo -e "    ${G}source ~/.ct/ct.zsh${R}"
echo ""
echo -e "  Then:"
echo ""
echo -e "    ${W}ct deploy${R}       ${D}# tag this terminal${R}"
echo -e "    ${W}ct${R}              ${D}# show current task${R}"
echo -e "    ${W}ct clear${R}        ${D}# reset${R}"
echo -e "    ${W}ct help${R}         ${D}# full help${R}"
echo ""
