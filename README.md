# ct — Terminal Task Tagger

Tag terminals with persistent visual identifiers. Switch between windows and instantly know what's running where.

```
ct deploy       # generates unique icon, sets badge + tab color
ct box          # 3D cube background
ct clear        # reset
```

Every name works. First use generates an icon automatically — cached for next time.

## What happens when you run `ct`

| Layer | Persists while scrolling | Where |
|-------|--------------------------|-------|
| **Background image** | Yes | Terminal pane (iTerm2) |
| **Badge** | Yes | Semi-transparent overlay (iTerm2) |
| **Tab color + title** | Yes | Tab bar |

Non-iTerm2 terminals get ASCII art + title.

## Pre-built tasks

| Command | Icon | Color |
|---------|------|-------|
| `ct box` | 3D cube | Blue |
| `ct li` | LinkedIn logo | Cyan |
| `ct web` | Browser + globe | Green |
| `ct infra` | Server rack | Yellow |
| `ct brane` | Shield + lock | Red |
| `ct sales` | Bar chart | Orange |
| `ct content` | Document + pen | Purple |

## Custom tasks

Any name auto-generates a unique icon with deterministic color and shape:

```
ct deploy       # always same color/shape
ct debugging
ct review-pr
ct client-xyz
```

Custom tasks get hash-based colors — same name always produces the same visual. Tab completion includes cached custom tasks.

## Install

```bash
git clone https://github.com/Lang-Julian/ct.git
cd ct
./install.sh
```

**Requirements:**
- zsh
- Python 3 + Pillow for background images: `pip install Pillow`
- Without Pillow: badge + tab color + ASCII art still work

## Commands

```
ct <name>       Tag terminal (auto-generates icon if new)
ct              Show current task
ct list         Show all tasks + cached custom icons
ct clear        Reset terminal (remove background, badge, tab color)
```

## Configuration

Add custom tasks with fixed colors in `~/.ct/config.zsh`:

```zsh
_CT_TASKS+=(
    myapp     "My App;80;140;220;myapp"
    deploy    "Production;220;60;60;deploy"
)
```

Format: `key "Label;R;G;B;icon_file"`

See `config.example.zsh` for a template.

## iTerm2 blending

Adjust background image opacity:

**Preferences → Profiles → Window → Background Image → Blending**

## Uninstall

```bash
rm -rf ~/.ct
# Remove this line from ~/.zshrc:
# [[ -f "$HOME/.ct/ct.zsh" ]] && source "$HOME/.ct/ct.zsh"
```

## License

MIT
