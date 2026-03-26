# ct — context tag

**Tag terminals, not tabs.**

You have 6 terminals open. You switch to one. Which project was this again?

`ct` solves this in one command — a persistent visual watermark that stays visible while you scroll, type, and forget which terminal is which.

```
ct deploy
```

A rocket icon fades into your terminal background. The tab turns red. A badge tracks your task name, directory, and active focus time. All persistent. All automatic.

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

Three visual layers, all persistent:

| Layer | Survives scrolling | Where | Requires |
|-------|-------------------|-------|----------|
| **Background image** | Yes | Terminal pane | iTerm2 or WezTerm |
| **Badge** | Yes | Semi-transparent overlay | iTerm2 or WezTerm |
| **Tab color** | Yes | Tab bar | iTerm2 or WezTerm |
| **Terminal title** | Yes | Title bar / tab | Any terminal |
| **ASCII art** | No (one-time) | Terminal output | Any terminal |

> **Note:** Full visual features (background, badge, tab color) require [iTerm2](https://iterm2.com/) or [WezTerm](https://wezfurlong.org/wezterm/). Other terminals get the title, timer, task log, and ASCII art fallback.

## Install

```bash
git clone https://github.com/Lang-Julian/ct.git
cd ct && ./install.sh
```

**Requirements:** zsh, Python 3, [Pillow](https://pypi.org/project/Pillow/) (`pip install Pillow`)

Without Pillow everything still works — just no background images.

## Usage

```bash
ct deploy              # tag this terminal
ct                     # show current task + git branch + path + timer
ct clear               # reset everything
ct list                # show all tasks (pre-built + cached custom)
ct delete <name>       # remove a cached icon
ct log                 # task history with durations
ct log 50              # last 50 entries
ct log clear           # clear history
ct help                # full reference
```

## Smart icons

Any name works. `ct` generates an icon automatically on first use and caches it.

### Semantic matching

Your task name is analyzed against **160+ keywords** mapped to **25 icon shapes**:

```
ct deploy       → 🚀 rocket
ct fix-login    → 🐛 bug
ct docker-setup → 🐋 container
ct api-review   → 🔗 connected nodes
ct db-migration → 🗄️  database cylinder
ct auth-flow    → 🔒 padlock
ct k8s-debug    → 🐋 container
ct perf-audit   → ⚡ lightning bolt
ct email-thing  → ✉️  envelope
ct git-rebase   → 🌿 branch
```

Three-pass matching:

```
ct "deploy-to-prod"
     ↓
  Split: ["deploy", "to", "prod"]
     ↓
  Pass 1: exact word match     → "deploy" hits → 🚀
  Pass 2: substring match      → "deploying" contains "deploy"
  Pass 3: joined-string match  → "mydb" contains "db"
     ↓
  No match? → deterministic geometric shape (SHA-256 hash → color + shape)
```

Same name always produces the same icon. Deterministic, no randomness.

### Pre-built (hand-crafted)

Seven tasks ship with high-quality hand-crafted icons:

```
ct deploy       Rocket              (red)
ct api          Connected nodes     (blue)
ct web          Browser + globe     (green)
ct infra        Server rack         (yellow)
ct security     Shield              (crimson)
ct data         Bar chart           (orange)
ct docs         Document + pen      (purple)
```

Aliases: `site` and `frontend` → web

## Smart timer

The timer only counts **active focus time** — not wall clock time.

```
22:00  ct deploy            timer starts
22:05  git push             +5m  (5m gap < 10m threshold → counted)
22:05  ... go to sleep ...
10:00  ls                   +0m  (12h gap > 10m threshold → skipped)
10:03  npm test             +3m  (3m gap → counted)

ct                          shows: 8m active (not 12h 3m)
```

The timer ticks on each shell prompt. If the gap between two prompts exceeds the idle threshold, that gap is not counted — you were away.

```bash
export CT_IDLE=300    # 5 min (stricter)
export CT_IDLE=900    # 15 min (relaxed)
# default: 600 (10 min)
```

## Dynamic badge

In iTerm2/WezTerm, the badge updates on every prompt:

```
┌─────────────────┐
│     DEPLOY      │  ← task (uppercased)
│                 │
│  …/my-project   │  ← current directory
│  47m            │  ← active focus time
└─────────────────┘
```

Automatically reflects directory changes as you `cd` around. No manual refresh needed.

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

### Background blending (iTerm2)

If the background watermark is too subtle or too strong:

**Preferences → Profiles → Window → Background Image → Blending slider**

## Terminal support

| Terminal | Background | Badge | Tab color | Title | Timer | Log |
|----------|-----------|-------|-----------|-------|-------|-----|
| **iTerm2** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **WezTerm** | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ |
| **Terminal.app** | — | — | — | ✓ | ✓ | ✓ |
| **Alacritty** | — | — | — | ✓ | ✓ | ✓ |
| **Kitty** | — | — | — | ✓ | ✓ | ✓ |

Core features (timer, task tracking, log, title) work in any terminal. Visual features (background image, badge overlay, tab color) use iTerm2/WezTerm proprietary escape sequences.

## Architecture

```
ct.zsh         ~580 lines    Shell integration, timer, badge, CLI
gen-icons.py   ~560 lines    Icon generation (Pillow), semantic matching
install.sh      ~80 lines    One-command setup
```

Design decisions:

- **Single file, zero runtime dependencies** — `ct.zsh` needs only zsh. Python + Pillow are optional (for background images only).
- **precmd hook** ticks the timer and refreshes the badge on every prompt — no polling, no background process.
- **SHA-256 hash** of task name → deterministic HSL color + geometric shape. Same input, same output, always.
- **Three-pass semantic matching** — exact word → substring → joined string → geometric fallback. Covers natural naming patterns ("deploying" matches "deploy", "mydb" matches "db").
- **Injection-safe** — task names are slugified before hitting the filesystem. Colors are computed via `sys.argv`, not string interpolation.
- **Graceful degradation** — missing Pillow? Badge + tab color + ASCII art still work. Not iTerm2? Title + timer + log still work.
- **No subshell overhead in hot paths** — slug computation, state updates, and timer ticks are pure zsh builtins.

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
