#!/usr/bin/env bash
set -e

CT_DIR="$HOME/.ct"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ct — Terminal Task Tagger"
echo "  ─────────────────────────"
echo ""

# ── Check zsh
if ! command -v zsh &>/dev/null; then
    echo "  error: ct requires zsh"
    exit 1
fi

# ── Install files
mkdir -p "$CT_DIR/icons"
cp "$SCRIPT_DIR/ct.zsh" "$CT_DIR/ct.zsh"
cp "$SCRIPT_DIR/gen-icons.py" "$CT_DIR/gen-icons.py"
chmod +x "$CT_DIR/gen-icons.py"

echo "  Installed → $CT_DIR"

# ── Generate pre-built icons
if python3 -c "from PIL import Image" 2>/dev/null; then
    echo "  Generating icons..."
    python3 "$CT_DIR/gen-icons.py" --all --dir "$CT_DIR/icons"
else
    echo ""
    echo "  Background images need Pillow:"
    echo "    pip install Pillow"
    echo ""
    echo "  Without it: badge + tab color + ASCII art still work."
fi

# ── Shell config
SOURCE_LINE='[[ -f "$HOME/.ct/ct.zsh" ]] && source "$HOME/.ct/ct.zsh"'

if [[ -f "$HOME/.zshrc" ]]; then
    if grep -qF ".ct/ct.zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo "  .zshrc already configured."
    else
        echo "" >> "$HOME/.zshrc"
        echo "# ct — Terminal Task Tagger (https://github.com/Lang-Julian/ct)" >> "$HOME/.zshrc"
        echo "$SOURCE_LINE" >> "$HOME/.zshrc"
        echo "  Added to .zshrc"
    fi
else
    echo ""
    echo "  Add to your .zshrc:"
    echo "    $SOURCE_LINE"
fi

echo ""
echo "  Done. Usage:"
echo ""
echo "    source ~/.ct/ct.zsh   # activate now"
echo "    ct box                # tag terminal"
echo "    ct my-project         # any name works"
echo "    ct clear              # reset"
echo ""
