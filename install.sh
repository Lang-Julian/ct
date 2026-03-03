#!/usr/bin/env bash
# ct installer — sets up ~/.ct and adds source line to shell config
set -e

CT_DIR="$HOME/.ct"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "  ct — Terminal Task Tagger"
echo "  ─────────────────────────"
echo ""

# ── Create ~/.ct
mkdir -p "$CT_DIR/icons"
cp "$SCRIPT_DIR/ct.zsh" "$CT_DIR/ct.zsh"
cp "$SCRIPT_DIR/gen-icons.py" "$CT_DIR/gen-icons.py"

echo "  Installed to $CT_DIR"

# ── Generate pre-built icons (if Pillow available)
if python3 -c "from PIL import Image" 2>/dev/null; then
    echo "  Generating icons..."
    python3 "$CT_DIR/gen-icons.py" --all --dir "$CT_DIR/icons"
else
    echo ""
    echo "  Optional: Install Pillow for background images (iTerm2):"
    echo "    pip install Pillow"
    echo ""
    echo "  ct works without it (badge + tab color + ASCII art fallback)."
fi

# ── Add to shell config
SHELL_RC=""
if [[ -f "$HOME/.zshrc" ]]; then
    SHELL_RC="$HOME/.zshrc"
elif [[ -f "$HOME/.bashrc" ]]; then
    SHELL_RC="$HOME/.bashrc"
fi

SOURCE_LINE='[[ -f "$HOME/.ct/ct.zsh" ]] && source "$HOME/.ct/ct.zsh"'

if [[ -n "$SHELL_RC" ]]; then
    if grep -qF ".ct/ct.zsh" "$SHELL_RC" 2>/dev/null; then
        echo "  Shell config already set up."
    else
        echo "" >> "$SHELL_RC"
        echo "# ct — Terminal Task Tagger" >> "$SHELL_RC"
        echo "$SOURCE_LINE" >> "$SHELL_RC"
        echo "  Added to $(basename "$SHELL_RC")"
    fi
else
    echo ""
    echo "  Add this to your shell config:"
    echo "    $SOURCE_LINE"
fi

echo ""
echo "  Done. Restart your shell or run:"
echo "    source $CT_DIR/ct.zsh"
echo ""
echo "  Usage:"
echo "    ct box        # set task tag"
echo "    ct my-thing   # any name works (auto-generates icon)"
echo "    ct clear      # reset"
echo ""
