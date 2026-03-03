# ct — Terminal Task Tagger

Visual task identification for fast terminal switching. Tag each terminal with a persistent icon so you instantly know which task runs where.

```
ct box          # 3D cube background + blue tab
ct linkedin     # "in" logo + cyan tab
ct my-project   # auto-generates icon on first use
ct clear        # reset
```

## What it does

When you run `ct <task>`, three things happen:

| Layer | Persists while scrolling? | Where |
|-------|--------------------------|-------|
| **Background image** | Yes | Terminal pane background |
| **Badge** | Yes | Semi-transparent text overlay |
| **Tab color + title** | Yes | Tab bar |

On non-iTerm2 terminals, it falls back to ASCII art + terminal title.

## Pre-built tasks

| Command | Icon | Color |
|---------|------|-------|
| `ct box` | 3D cube | Blue |
| `ct li` | LinkedIn "in" logo | Cyan |
| `ct web` | Browser with globe | Green |
| `ct infra` | Server rack | Yellow |
| `ct brane` | Shield with lock | Red |
| `ct sales` | Bar chart | Orange |
| `ct content` | Document with pen | Purple |

Any other name auto-generates an icon on first use:

```
ct deploy       # generates icon, cached for next time
ct debugging
ct review-pr
```

## Install

```bash
git clone https://github.com/AceAnt0ny/ct.git
cd ct
./install.sh
```

### Requirements

- **zsh** (bash support planned)
- **Pillow** for background images: `pip install Pillow`
  - Without Pillow: badge + tab color + ASCII art still work

### Manual install

```bash
mkdir -p ~/.ct/icons
cp ct.zsh gen-icons.py ~/.ct/
python3 gen-icons.py --all --dir ~/.ct/icons

# Add to ~/.zshrc:
[[ -f "$HOME/.ct/ct.zsh" ]] && source "$HOME/.ct/ct.zsh"
```

## iTerm2 tip

Adjust background image visibility:

**Preferences → Profiles → Window → Background Image → Blending**

Slide right = more visible. This is a one-time setting.

## How it works

- iTerm2 proprietary escape sequences for badge (`SetBadgeFormat`), tab color, and background image (`SetBackgroundImageFile`)
- Standard OSC escape sequence for terminal title (works in any terminal)
- PIL/Pillow generates semi-transparent PNG icons (alpha ~15%) that don't interfere with terminal text
- Custom icons are generated once and cached in `~/.ct/icons/`

## Configuration

Set `CT_DIR` to change the install location (default: `~/.ct`):

```bash
export CT_DIR="$HOME/.config/ct"
```

## License

MIT
