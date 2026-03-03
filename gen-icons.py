#!/usr/bin/env python3
"""
ct icon generator — creates semi-transparent PNG watermarks for terminal backgrounds.

Usage:
    gen-icons.py --all                          Generate all pre-built icons
    gen-icons.py --task <name> --out <path>     Generate a single icon
"""

import argparse
import os
import sys

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    print("Pillow required: pip install Pillow", file=sys.stderr)
    sys.exit(1)

W, H = 1000, 800
ALPHA = 38

# Font resolution — tries common paths, falls back to default
FONT_PATHS = [
    os.path.expanduser("~/Library/Fonts/JetBrainsMonoNerdFontPropo-Bold.ttf"),
    os.path.expanduser("~/Library/Fonts/JetBrainsMono-Bold.ttf"),
    "/usr/share/fonts/truetype/jetbrains-mono/JetBrainsMono-Bold.ttf",
    "/System/Library/Fonts/Menlo.ttc",
    "/System/Library/Fonts/Monaco.ttf",
    "/usr/share/fonts/truetype/dejavu/DejaVuSansMono-Bold.ttf",
    "/usr/share/fonts/truetype/liberation/LiberationMono-Bold.ttf",
    "C:/Windows/Fonts/consola.ttf",
]


def _find_font():
    for p in FONT_PATHS:
        if os.path.isfile(p):
            return p
    return None


def _font(size):
    path = _find_font()
    if path:
        return ImageFont.truetype(path, size)
    return ImageFont.load_default()


def _rgba(r, g, b, a=ALPHA):
    return (r, g, b, a)


def _img():
    return Image.new("RGBA", (W, H), (0, 0, 0, 0))


def _label(draw, text, y, color, size=42):
    f = _font(size)
    bbox = draw.textbbox((0, 0), text, font=f)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) // 2, y), text, fill=color, font=f)


# ─── Pre-built icon generators ───────────────────────────────────

def gen_box():
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(30, 100, 220)
    cx, cy, s, lw = W // 2, H // 2 - 30, 140, 5
    off = s // 2
    d.polygon([(cx-s,cy-s//3),(cx+s,cy-s//3),(cx+s,cy+s),(cx-s,cy+s)], outline=c, width=lw)
    d.polygon([(cx-s,cy-s//3),(cx-s+off,cy-s),(cx+s+off,cy-s),(cx+s,cy-s//3)], outline=c, width=lw)
    d.polygon([(cx+s,cy-s//3),(cx+s+off,cy-s),(cx+s+off,cy+s-s//3),(cx+s,cy+s)], outline=c, width=lw)
    ds = 25
    d.polygon([(cx,cy+s//4-ds),(cx+ds,cy+s//4),(cx,cy+s//4+ds),(cx-ds,cy+s//4)], fill=c)
    _label(d, "AI IN THE BOX", cy+s+50, c, 48)
    return img


def gen_li():
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(0, 119, 181)
    cx, cy, bw, bh = W//2, H//2-20, 200, 220
    d.rounded_rectangle([cx-bw,cy-bh,cx+bw,cy+bh], radius=30, outline=c, width=4)
    d.ellipse([cx-120,cy-160,cx-70,cy-120], fill=c)
    d.rectangle([cx-120,cy-90,cx-70,cy+100], fill=c)
    d.rectangle([cx-20,cy-90,cx+30,cy+100], fill=c)
    d.arc([cx-20,cy-130,cx+130,cy], start=180, end=0, fill=c, width=50)
    d.rectangle([cx+80,cy-65,cx+130,cy+100], fill=c)
    _label(d, "LINKEDIN", cy+bh+40, c, 48)
    return img


def gen_web():
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(40, 180, 70)
    cx, cy = W//2, H//2
    d.rounded_rectangle([cx-220,cy-220,cx+220,cy+180], radius=15, outline=c, width=4)
    d.line([cx-220,cy-170,cx+220,cy-170], fill=c, width=4)
    for off in [-185,-160,-135]:
        d.ellipse([cx+off,cy-205,cx+off+20,cy-185], outline=c, width=3)
    gcx, gcy, r = cx, cy+10, 100
    d.ellipse([gcx-r,gcy-r,gcx+r,gcy+r], outline=c, width=4)
    d.ellipse([gcx-r//2,gcy-r,gcx+r//2,gcy+r], outline=c, width=3)
    d.line([gcx-r,gcy,gcx+r,gcy], fill=c, width=3)
    d.line([gcx-r+15,gcy-r//2,gcx+r-15,gcy-r//2], fill=c, width=2)
    d.line([gcx-r+15,gcy+r//2,gcx+r-15,gcy+r//2], fill=c, width=2)
    _label(d, "WEBSITE", gcy+r+80, c, 48)
    return img


def gen_infra():
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(220, 170, 30)
    cx, cy, rw, rh = W//2, H//2-40, 200, 70
    for i in range(4):
        y = cy-150+i*(rh+8)
        d.rounded_rectangle([cx-rw,y,cx+rw,y+rh], radius=8, outline=c, width=4)
        for j in range(3):
            bx = cx-rw+25+j*30
            d.rectangle([bx,y+18,bx+20,y+52], fill=c)
        d.rectangle([cx-20,y+25,cx+100,y+45], outline=c, width=3)
        d.ellipse([cx+140,y+25,cx+160,y+45], fill=c)
    by = cy-150+4*(rh+8)
    d.line([cx-100,by+10,cx+100,by+10], fill=c, width=6)
    d.line([cx,by+10,cx,by+35], fill=c, width=6)
    d.line([cx-80,by+35,cx+80,by+35], fill=c, width=4)
    _label(d, "INFRASTRUCTURE", by+55, c, 44)
    return img


def gen_brane():
    img = _img()
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
    _label(d, "BRANE AIF", cy+220, c, 48)
    return img


def gen_sales():
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(240, 130, 20)
    cx, cy = W//2, H//2
    base_y, bar_w, gap = cy+130, 50, 20
    bars = [80, 130, 100, 180, 150, 250, 220, 300]
    ax_left = cx-(len(bars)*(bar_w+gap))//2-20
    ax_right = cx+(len(bars)*(bar_w+gap))//2+20
    d.line([ax_left,base_y,ax_right,base_y], fill=c, width=4)
    d.line([ax_left,base_y,ax_left,base_y-350], fill=c, width=4)
    d.polygon([(ax_left-10,base_y-340),(ax_left,base_y-360),(ax_left+10,base_y-340)], fill=c)
    sx = cx-(len(bars)*(bar_w+gap))//2
    pts = []
    for i, h in enumerate(bars):
        x = sx+i*(bar_w+gap)
        d.rectangle([x,base_y-h,x+bar_w,base_y], fill=c)
        pts.append((x+bar_w//2, base_y-h-15))
    if len(pts) > 1:
        d.line(pts, fill=_rgba(240,130,20,ALPHA+15), width=4)
    _label(d, "SALES", base_y+40, c, 48)
    return img


def gen_content():
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(140, 60, 200)
    cx, cy = W//2, H//2-20
    pl, pt, pr, pb, fold = cx-160, cy-200, cx+160, cy+200, 50
    d.polygon([(pl,pt),(pr-fold,pt),(pr,pt+fold),(pr,pb),(pl,pb)], outline=c, width=4)
    d.line([(pr-fold,pt),(pr-fold,pt+fold),(pr,pt+fold)], fill=c, width=3)
    for i in range(7):
        y = pt+80+i*45
        lw = 220 if i%3!=2 else 150
        d.line([cx-110,y,cx-110+lw,y], fill=c, width=6)
    d.line([pr+30,pb-30,pr+80,pb-110], fill=c, width=6)
    d.polygon([(pr+27,pb-25),(pr+33,pb-25),(pr+30,pb-10)], fill=c)
    _label(d, "CONTENT", pb+30, c, 48)
    return img


# ─── Custom icon generator ──────────────────────────────────────

def gen_custom(task_name):
    img = _img()
    d = ImageDraw.Draw(img)
    c = _rgba(100, 100, 100)
    cx, cy = W // 2, H // 2
    d.rounded_rectangle([cx-250, cy-180, cx+250, cy+120], radius=25, outline=c, width=5)
    upper = task_name.upper().replace("-", " - ").replace("_", " ")
    f = _font(min(72, max(36, 600 // max(len(upper), 1))))
    bb = d.textbbox((0, 0), upper, font=f)
    tw = bb[2] - bb[0]
    d.text(((W - tw) // 2, cy - 50), upper, fill=c, font=f)
    return img


# ─── Registry ───────────────────────────────────────────────────

PREBUILT = {
    "box": gen_box,
    "li": gen_li,
    "web": gen_web,
    "infra": gen_infra,
    "brane": gen_brane,
    "sales": gen_sales,
    "content": gen_content,
}


def generate(task, out_path):
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    gen_fn = PREBUILT.get(task)
    if gen_fn:
        img = gen_fn()
    else:
        img = gen_custom(task)
    img.save(out_path)


def main():
    parser = argparse.ArgumentParser(description="ct icon generator")
    parser.add_argument("--all", action="store_true", help="Generate all pre-built icons")
    parser.add_argument("--task", help="Task name to generate icon for")
    parser.add_argument("--out", help="Output file path")
    parser.add_argument("--dir", help="Output directory (used with --all)")
    args = parser.parse_args()

    if args.all:
        out_dir = args.dir or os.path.expanduser("~/.ct/icons")
        os.makedirs(out_dir, exist_ok=True)
        for name, fn in PREBUILT.items():
            path = os.path.join(out_dir, f"{name}.png")
            img = fn()
            img.save(path)
            print(f"  {name}.png")
        print(f"\nIcons generated in {out_dir}")
    elif args.task and args.out:
        generate(args.task, args.out)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
