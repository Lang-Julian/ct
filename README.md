# ct — context tag

**Tag terminals, not tabs.**

You have 5 terminals open. You switch to one. Which project was this?
`ct` solves this in one command — a persistent visual tag that stays visible while you scroll, work, and forget.

```
ct deploy
```

That's it. A rocket icon appears as a watermark in your terminal background. The tab turns colored. A badge shows your task, directory, and how long you've been focused. All persistent. All automatic.

---

## How it works

```
┌─────────────────────────────────────────────────┐
│                                                 │
│  $ ct deploy                                    │
│                                                 │
│  ◈ deploy                                       │
│                                                 │
│  $ git status                    ╱╲              │
│  $ npm run build                ╱  ╲             │
│  $ npm test                    ╱    ╲            │
│                               ╱ 🚀  ╲           │
│  Everything still visible     ╲      ╱           │
│  while you work.               ╲    ╱            │
│  Even after scrolling.          ╲  ╱             │
│                                  ╲╱              │
│                               DEPLOY             │
│                                                 │
│  $ ...                                          │
│                                                 │
├─────────────────────────────────────────────────┤
│ ◈ deploy │ tab 2 │ tab 3 │        (colored tab) │
└─────────────────────────────────────────────────┘
```

Three layers, all persistent:

| Layer | Survives scrolling | Where | Terminal support |
|-------|-------------------|-------|-----------------|
| **Background image** | Yes | Terminal pane | iTerm2, WezTerm |
| **Badge** | Yes | Semi-transparent overlay | iTerm2, WezTerm |
| **Tab color + title** | Yes | Tab bar | iTerm2, WezTerm |
| **ASCII art** | No (one-time) | Terminal output | Any terminal |
| **Terminal title** | Yes | Title bar / tab | Any terminal |

## Install

```bash
git clone https://github.com/Lang-Julian/ct.git
cd ct
./install.sh
```

Requirements: **zsh** + **Python 3** + **Pillow** (`pip install Pillow`)

Without Pillow, badge + tab color + ASCII art still work — just no background images.

## Quick start

```bash
source ~/.ct/ct.zsh    # activate (auto-loaded on next shell start)

ct deploy              # tag this terminal
ct                     # show current task + branch + path + timer
ct clear               # reset everything
```

## Commands

| Command | What it does |
|---------|-------------|
| `ct <name>` | Tag terminal — any name works, icon auto-generated |
| `ct` | Show current task, git branch, path, active time |
| `ct clear` | Reset (remove background, badge, tab color) |
| `ct list` | Show all tasks (pre-built + cached custom) |
| `ct delete <name>` | Delete a cached custom icon |
| `ct log` | Task history with durations |
| `ct log 50` | Last 50 log entries |
| `ct log clear` | Clear history |
| `ct help` | Full help |
| `ct version` | Version |

## Smart icons

### Pre-built (hand-crafted)

```
ct box          3D cube             (blue)
ct li           LinkedIn "in" logo  (cyan)
ct web          Browser + globe     (green)
ct infra        Server rack         (yellow)
ct brane        Shield + lock       (red)
ct sales        Bar chart           (orange)
ct content      Document + pen      (purple)
```

Aliases: `aitb` → box, `linkedin` → li, `site` → web

### Custom — semantic matching

`ct` recognizes what your task is about and picks a matching icon:

```
ct deploy       → 🚀 rocket
ct fix-login    → 🐛 bug
ct docker-setup → 🐋 container + whale
ct api-review   → 🔗 connected nodes
ct meeting-prep → 📞 headset
ct db-migration → 🗄️  database cylinder
ct auth-flow    → 🔒 padlock
ct git-rebase   → 🌿 branch
ct k8s-debug    → 🐋 container
ct perf-audit   → ⚡ lightning bolt
ct email-thing  → ✉️  envelope
```

**160+ keywords** mapped to **25 icon shapes** — deploy, debug, database, api, test, build, design, email, chat, security, cloud, docker, git, monitor, docs, meeting, search, finance, network, and more.

No match? Falls back to a unique geometric shape with hash-based color. Same name → same visual, always.

### How matching works

```
ct "deploy-to-prod"
     ↓
  Split: ["deploy", "to", "prod"]
     ↓
  Pass 1: exact word match → "deploy" → 🚀 rocket
     ↓
  Done. (also tries substring + joined-string matching as fallback)
```

## Smart timer

The timer only counts **active focus time**, not wall clock time.

```
22:00  ct box              timer starts
22:05  git push            +5m (gap 5m < 10m → active)
22:05  ... sleep ...
10:00  ls                  +0m (gap 12h > 10m → idle, skipped)
10:03  npm test            +3m (gap 3m < 10m → active)

ct                         shows: 8m active (not 12h)
```

The threshold is configurable:

```bash
export CT_IDLE=300    # 5 min (stricter)
export CT_IDLE=900    # 15 min (more relaxed)
# default: 600 (10 min)
```

## Dynamic badge

In iTerm2/WezTerm, the badge updates on every prompt:

```
┌─────────────────┐
│  AI IN THE BOX  │  ← task
│                 │
│  …/ai-in-the-box│ ← directory
│  47m            │  ← active focus time
└─────────────────┘
```

Automatically reflects directory changes. No manual refresh needed.

## Configuration

### Custom tasks with fixed colors

Create `~/.ct/config.zsh`:

```zsh
_CT_TASKS+=(
    myapp     "My App;80;140;220;myapp"
    staging   "Staging;220;160;40;staging"
)
```

Format: `key "Label;R;G;B;icon_file"`

See [`config.example.zsh`](config.example.zsh) for a template.

### iTerm2 background blending

If the background image is too subtle or too strong:

**Preferences → Profiles → Window → Background Image → Blending slider**

Right = more visible. One-time setting.

## Terminal support

| Terminal | Background | Badge | Tab color | Timer | ASCII art |
|----------|-----------|-------|-----------|-------|-----------|
| **iTerm2** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **WezTerm** | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Terminal.app** | — | — | — | ✓ | ✓ |
| **Alacritty** | — | — | — | ✓ | ✓ |
| **Kitty** | — | — | — | ✓ | ✓ |

Timer and task tracking (`ct`, `ct log`) work everywhere. Visual features (background, badge, tab color) require iTerm2 or WezTerm.

## How it's built

- **~580 lines of zsh** — single file, no dependencies beyond zsh
- **~560 lines of Python** — icon generator (Pillow), only needed for background images
- **iTerm2 proprietary escape sequences** for badge, tab color, background image
- **Standard OSC sequences** for terminal title (universal)
- **PIL/Pillow** generates semi-transparent PNGs (alpha ~15%) that don't interfere with text
- **SHA-256 hash** of task name → deterministic color (HSL color space) + shape selection
- **precmd hook** updates badge on every prompt and ticks the smart timer

## Uninstall

```bash
rm -rf ~/.ct
```

Then remove this line from `~/.zshrc`:

```
[[ -f "$HOME/.ct/ct.zsh" ]] && source "$HOME/.ct/ct.zsh"
```

## License

MIT
