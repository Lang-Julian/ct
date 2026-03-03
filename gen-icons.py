#!/usr/bin/env python3
"""
ct icon generator — semi-transparent PNG watermarks for terminal backgrounds.

Usage:
    gen-icons.py --all                          Generate all pre-built icons
    gen-icons.py --task <name> --out <path>     Generate single icon (pre-built or custom)
"""

import argparse
import colorsys
import hashlib
import math
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("error: Pillow required — pip install Pillow", file=sys.stderr)
    sys.exit(1)

W, H = 1000, 800
ALPHA = 38

# ─── Font handling ───────────────────────────────────────────────

_FONT_PATHS = [
    os.path.expanduser("~/Library/Fonts/JetBrainsMonoNerdFontPropo-Bold.ttf"),
    os.path.expanduser("~/Library/Fonts/JetBrainsMono-Bold.ttf"),
    "/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Bold.ttf",
    "/System/Library/Fonts/Menlo.ttc",
    "/System/Library/Fonts/Monaco.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
    "C:/Windows/Fonts/consola.ttf",
]

_font_cache = {}


def _find_font_path():
    for p in _FONT_PATHS:
        if os.path.isfile(p):
            return p
    return None


def _font(size):
    if size in _font_cache:
        return _font_cache[size]
    path = _find_font_path()
    f = ImageFont.truetype(path, size) if path else ImageFont.load_default()
    _font_cache[size] = f
    return f


# ─── Helpers ─────────────────────────────────────────────────────

def _rgba(r, g, b, a=ALPHA):
    return (r, g, b, a)


def _img():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def _center_text(draw, text, y, color, size=42):
    f = _font(size)
    bb = draw.textbbox((0, 0), text, font=f)
    draw.text(((W - (bb[2] - bb[0])) // 2, y), text, fill=color, font=f)


def _hash_color(name):
    """Deterministic color from task name. Same name → same color, always."""
    h = int(hashlib.sha256(name.encode()).hexdigest()[:8], 16)
    hue = (h % 360) / 360.0
    r, g, b = colorsys.hls_to_rgb(hue, 0.5, 0.7)
    return int(r * 255), int(g * 255), int(b * 255)


# ─── Pre-built icons ────────────────────────────────────────────

def gen_box():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(30, 100, 220)
    cx, cy, s = W // 2, H // 2 - 30, 140
    off = s // 2
    d.polygon([(cx-s,cy-s//3),(cx+s,cy-s//3),(cx+s,cy+s),(cx-s,cy+s)], outline=c, width=5)
    d.polygon([(cx-s,cy-s//3),(cx-s+off,cy-s),(cx+s+off,cy-s),(cx+s,cy-s//3)], outline=c, width=5)
    d.polygon([(cx+s,cy-s//3),(cx+s+off,cy-s),(cx+s+off,cy+s-s//3),(cx+s,cy+s)], outline=c, width=5)
    d.polygon([(cx,cy+s//4-25),(cx+25,cy+s//4),(cx,cy+s//4+25),(cx-25,cy+s//4)], fill=c)
    _center_text(d, "AI IN THE BOX", cy + s + 50, c, 48)
    return img


def gen_li():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(0, 119, 181)
    cx, cy, bw, bh = W//2, H//2-20, 200, 220
    d.rounded_rectangle([cx-bw,cy-bh,cx+bw,cy+bh], radius=30, outline=c, width=4)
    d.ellipse([cx-120,cy-160,cx-70,cy-120], fill=c)
    d.rectangle([cx-120,cy-90,cx-70,cy+100], fill=c)
    d.rectangle([cx-20,cy-90,cx+30,cy+100], fill=c)
    d.arc([cx-20,cy-130,cx+130,cy], start=180, end=0, fill=c, width=50)
    d.rectangle([cx+80,cy-65,cx+130,cy+100], fill=c)
    _center_text(d, "LINKEDIN", cy + bh + 40, c, 48)
    return img


def gen_web():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(40, 180, 70)
    cx, cy = W//2, H//2
    d.rounded_rectangle([cx-220,cy-220,cx+220,cy+180], radius=15, outline=c, width=4)
    d.line([cx-220,cy-170,cx+220,cy-170], fill=c, width=4)
    for o in [-185,-160,-135]:
        d.ellipse([cx+o,cy-205,cx+o+20,cy-185], outline=c, width=3)
    r = 100
    d.ellipse([cx-r,cy+10-r,cx+r,cy+10+r], outline=c, width=4)
    d.ellipse([cx-r//2,cy+10-r,cx+r//2,cy+10+r], outline=c, width=3)
    d.line([cx-r,cy+10,cx+r,cy+10], fill=c, width=3)
    d.line([cx-r+15,cy+10-r//2,cx+r-15,cy+10-r//2], fill=c, width=2)
    d.line([cx-r+15,cy+10+r//2,cx+r-15,cy+10+r//2], fill=c, width=2)
    _center_text(d, "WEBSITE", cy + 10 + r + 80, c, 48)
    return img


def gen_infra():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(220, 170, 30)
    cx, cy, rw, rh = W//2, H//2-40, 200, 70
    for i in range(4):
        y = cy - 150 + i * (rh + 8)
        d.rounded_rectangle([cx-rw,y,cx+rw,y+rh], radius=8, outline=c, width=4)
        for j in range(3):
            bx = cx - rw + 25 + j * 30
            d.rectangle([bx,y+18,bx+20,y+52], fill=c)
        d.rectangle([cx-20,y+25,cx+100,y+45], outline=c, width=3)
        d.ellipse([cx+140,y+25,cx+160,y+45], fill=c)
    by = cy - 150 + 4 * (rh + 8)
    d.line([cx-100,by+10,cx+100,by+10], fill=c, width=6)
    d.line([cx,by+10,cx,by+35], fill=c, width=6)
    d.line([cx-80,by+35,cx+80,by+35], fill=c, width=4)
    _center_text(d, "INFRASTRUCTURE", by + 55, c, 44)
    return img


def gen_brane():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(200, 40, 70)
    cx, cy = W//2, H//2-20
    outer = [(cx,cy-200),(cx+170,cy-130),(cx+170,cy+20),(cx+100,cy+120),
             (cx,cy+190),(cx-100,cy+120),(cx-170,cy+20),(cx-170,cy-130)]
    inner = [(cx,cy-150),(cx+120,cy-95),(cx+120,cy+15),(cx+70,cy+90),
             (cx,cy+140),(cx-70,cy+90),(cx-120,cy+15),(cx-120,cy-95)]
    d.polygon(outer, outline=c, width=5)
    d.polygon(inner, outline=c, width=3)
    d.ellipse([cx-30,cy-55,cx+30,cy+5], outline=c, width=4)
    d.polygon([(cx-18,cy+5),(cx+18,cy+5),(cx+8,cy+65),(cx-8,cy+65)], fill=c)
    _center_text(d, "BRANE AIF", cy + 220, c, 48)
    return img


def gen_sales():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(240, 130, 20)
    cx, cy, bw, gap = W//2, H//2, 50, 20
    base_y = cy + 130
    bars = [80, 130, 100, 180, 150, 250, 220, 300]
    total = len(bars) * (bw + gap)
    ax_l, ax_r = cx - total//2 - 20, cx + total//2 + 20
    d.line([ax_l,base_y,ax_r,base_y], fill=c, width=4)
    d.line([ax_l,base_y,ax_l,base_y-350], fill=c, width=4)
    d.polygon([(ax_l-10,base_y-340),(ax_l,base_y-360),(ax_l+10,base_y-340)], fill=c)
    sx, pts = cx - total//2, []
    for i, h in enumerate(bars):
        x = sx + i * (bw + gap)
        d.rectangle([x,base_y-h,x+bw,base_y], fill=c)
        pts.append((x + bw//2, base_y - h - 15))
    d.line(pts, fill=_rgba(240, 130, 20, ALPHA + 15), width=4)
    _center_text(d, "SALES", base_y + 40, c, 48)
    return img


def gen_content():
    img, d = _img(), None
    d = ImageDraw.Draw(img)
    c = _rgba(140, 60, 200)
    cx, cy = W//2, H//2-20
    pl, pt, pr, pb, fold = cx-160, cy-200, cx+160, cy+200, 50
    d.polygon([(pl,pt),(pr-fold,pt),(pr,pt+fold),(pr,pb),(pl,pb)], outline=c, width=4)
    d.line([(pr-fold,pt),(pr-fold,pt+fold),(pr,pt+fold)], fill=c, width=3)
    for i in range(7):
        y = pt + 80 + i * 45
        d.line([cx-110, y, cx-110 + (220 if i%3!=2 else 150), y], fill=c, width=6)
    d.line([pr+30,pb-30,pr+80,pb-110], fill=c, width=6)
    d.polygon([(pr+27,pb-25),(pr+33,pb-25),(pr+30,pb-10)], fill=c)
    _center_text(d, "CONTENT", pb + 30, c, 48)
    return img


# ─── Custom icon generator (hash-based unique visuals) ──────────

# Shape generators for variety — deterministic from name hash
def _shape_concentric_rings(d, cx, cy, c, seed):
    """Concentric circles with gaps."""
    for i in range(4, 0, -1):
        r = i * 45
        lw = 4 if i % 2 == 0 else 3
        d.ellipse([cx-r, cy-r, cx+r, cy+r], outline=c, width=lw)


def _shape_hexagon(d, cx, cy, c, seed):
    """Nested hexagons."""
    for scale in [1.0, 0.6]:
        r = int(150 * scale)
        pts = [(cx + int(r * math.cos(math.radians(60*i - 30))),
                cy + int(r * math.sin(math.radians(60*i - 30)))) for i in range(6)]
        d.polygon(pts, outline=c, width=5 if scale == 1.0 else 3)


def _shape_diamond_grid(d, cx, cy, c, seed):
    """Diamond/rhombus pattern."""
    s = 80
    for dx in [-1, 0, 1]:
        for dy in [-1, 0, 1]:
            if abs(dx) + abs(dy) > 1:
                continue
            ox, oy = cx + dx * s, cy + dy * s
            d.polygon([(ox,oy-s//2),(ox+s//2,oy),(ox,oy+s//2),(ox-s//2,oy)],
                      outline=c, width=4)


def _shape_crosshair(d, cx, cy, c, seed):
    """Targeting crosshair."""
    for r in [120, 80, 40]:
        d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=c, width=3)
    d.line([cx-140,cy,cx-20,cy], fill=c, width=4)
    d.line([cx+20,cy,cx+140,cy], fill=c, width=4)
    d.line([cx,cy-140,cx,cy-20], fill=c, width=4)
    d.line([cx,cy+20,cx,cy+140], fill=c, width=4)


def _shape_brackets(d, cx, cy, c, seed):
    """Code brackets < >."""
    s = 100
    # Left bracket
    d.line([(cx-60,cy-s),(cx-140,cy),(cx-60,cy+s)], fill=c, width=6)
    # Right bracket
    d.line([(cx+60,cy-s),(cx+140,cy),(cx+60,cy+s)], fill=c, width=6)
    # Slash
    d.line([(cx+20,cy-s+20),(cx-20,cy+s-20)], fill=c, width=5)


def _shape_pulse(d, cx, cy, c, seed):
    """Heartbeat/pulse line."""
    pts = [
        (cx-200,cy), (cx-120,cy), (cx-80,cy-100), (cx-40,cy+80),
        (cx,cy-120), (cx+40,cy+60), (cx+80,cy-40), (cx+120,cy), (cx+200,cy)
    ]
    d.line(pts, fill=c, width=5)
    d.ellipse([cx-8,cy-8,cx+8,cy+8], fill=c)


def _shape_layers(d, cx, cy, c, seed):
    """Stacked layers/cards."""
    for i in range(3):
        off = i * 25
        d.rounded_rectangle(
            [cx-160+off, cy-100+off, cx+160+off, cy+60+off],
            radius=12, outline=c, width=4
        )


_SHAPES = [
    _shape_concentric_rings, _shape_hexagon, _shape_diamond_grid,
    _shape_crosshair, _shape_brackets, _shape_pulse, _shape_layers,
]


def gen_custom(task_name):
    """Generate unique icon from task name — deterministic color + shape."""
    img = _img()
    d = ImageDraw.Draw(img)

    r, g, b = _hash_color(task_name)
    c = _rgba(r, g, b)
    cx, cy = W // 2, H // 2 - 40

    # Pick shape from hash
    seed = int(hashlib.sha256(task_name.encode()).hexdigest()[:8], 16)
    shape_fn = _SHAPES[seed % len(_SHAPES)]
    shape_fn(d, cx, cy, c, seed)

    # Label below shape
    display = task_name.upper().replace("-", " ").replace("_", " ")
    size = min(56, max(32, 700 // max(len(display), 1)))
    _center_text(d, display, cy + 180, c, size)

    return img


# ─── Registry + entry points ────────────────────────────────────

PREBUILT = {
    "box": gen_box, "li": gen_li, "web": gen_web, "infra": gen_infra,
    "brane": gen_brane, "sales": gen_sales, "content": gen_content,
}


def generate(task, out_path):
    os.makedirs(os.path.dirname(out_path) or ".", exist_ok=True)
    fn = PREBUILT.get(task)
    img = fn() if fn else gen_custom(task)
    img.save(out_path)


def main():
    ap = argparse.ArgumentParser(description="ct icon generator")
    ap.add_argument("--all", action="store_true", help="Generate all pre-built icons")
    ap.add_argument("--task", help="Task name")
    ap.add_argument("--out", help="Output path")
    ap.add_argument("--dir", help="Output directory (with --all)")
    args = ap.parse_args()

    if args.all:
        d = args.dir or os.path.expanduser("~/.ct/icons")
        os.makedirs(d, exist_ok=True)
        for name, fn in PREBUILT.items():
            fn().save(os.path.join(d, f"{name}.png"))
            print(f"  {name}.png")
        print(f"\n  Icons → {d}")
    elif args.task and args.out:
        generate(args.task, args.out)
    else:
        ap.print_help()


if __name__ == "__main__":
    main()
