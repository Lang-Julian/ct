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
ALPHA = 65

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


# ─── Semantic icon shapes (keyword-matched) ─────────────────────

def _icon_rocket(d, cx, cy, c, _):
    d.polygon([(cx,cy-160),(cx-40,cy+40),(cx+40,cy+40)], outline=c, width=4)
    d.ellipse([cx-40,cy-80,cx+40,cy+40], outline=c, width=4)
    d.arc([cx-40,cy-160,cx+40,cy-80], start=180, end=0, fill=c, width=4)
    d.polygon([(cx-40,cy+10),(cx-80,cy+80),(cx-40,cy+40)], outline=c, width=4)
    d.polygon([(cx+40,cy+10),(cx+80,cy+80),(cx+40,cy+40)], outline=c, width=4)
    d.polygon([(cx-20,cy+40),(cx,cy+100),(cx+20,cy+40)], fill=c)

def _icon_bug(d, cx, cy, c, _):
    d.ellipse([cx-60,cy-40,cx+60,cy+80], outline=c, width=4)
    d.ellipse([cx-35,cy-80,cx+35,cy-30], outline=c, width=4)
    d.ellipse([cx-20,cy-68,cx-8,cy-52], fill=c)
    d.ellipse([cx+8,cy-68,cx+20,cy-52], fill=c)
    d.line([(cx-20,cy-80),(cx-50,cy-120)], fill=c, width=4)
    d.line([(cx+20,cy-80),(cx+50,cy-120)], fill=c, width=4)
    d.ellipse([cx-55,cy-128,cx-45,cy-118], fill=c)
    d.ellipse([cx+45,cy-128,cx+55,cy-118], fill=c)
    for yoff in [-10, 20, 50]:
        d.line([(cx-60,cy+yoff),(cx-100,cy+yoff-20)], fill=c, width=3)
        d.line([(cx+60,cy+yoff),(cx+100,cy+yoff-20)], fill=c, width=3)

def _icon_database(d, cx, cy, c, _):
    w, h, eh = 120, 160, 35
    d.ellipse([cx-w,cy-h-eh,cx+w,cy-h+eh], outline=c, width=4)
    d.arc([cx-w,cy+h-eh,cx+w,cy+h+eh], start=0, end=180, fill=c, width=4)
    d.line([(cx-w,cy-h),(cx-w,cy+h)], fill=c, width=4)
    d.line([(cx+w,cy-h),(cx+w,cy+h)], fill=c, width=4)
    d.arc([cx-w,cy-60-eh,cx+w,cy-60+eh], start=0, end=180, fill=c, width=3)
    d.arc([cx-w,cy+30-eh,cx+w,cy+30+eh], start=0, end=180, fill=c, width=3)

def _icon_api(d, cx, cy, c, _):
    nodes = [(cx,cy-120),(cx-120,cy),(cx+120,cy),(cx-70,cy+110),(cx+70,cy+110)]
    for i, a in enumerate(nodes):
        for b in nodes[i+1:]:
            d.line([a, b], fill=c, width=3)
    for x, y in nodes:
        d.ellipse([x-18,y-18,x+18,y+18], fill=c)

def _icon_checkmark(d, cx, cy, c, _):
    r = 120
    d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=c, width=5)
    d.line([(cx-55,cy),(cx-15,cy+50),(cx+60,cy-55)], fill=c, width=8)

def _icon_gear(d, cx, cy, c, _):
    r_o, r_i, teeth = 130, 85, 8
    pts = []
    for i in range(teeth * 2):
        a = math.radians(i * 360 / (teeth * 2) - 90)
        r = r_o if i % 2 == 0 else r_i
        pts.append((cx + int(r * math.cos(a)), cy + int(r * math.sin(a))))
    d.polygon(pts, outline=c, width=4)
    d.ellipse([cx-35,cy-35,cx+35,cy+35], outline=c, width=4)

def _icon_envelope(d, cx, cy, c, _):
    w, h = 160, 110
    d.rectangle([cx-w,cy-h,cx+w,cy+h], outline=c, width=4)
    d.line([(cx-w,cy-h),(cx,cy+20),(cx+w,cy-h)], fill=c, width=4)
    d.line([(cx-w,cy+h),(cx-50,cy+10)], fill=c, width=3)
    d.line([(cx+w,cy+h),(cx+50,cy+10)], fill=c, width=3)

def _icon_chat(d, cx, cy, c, _):
    d.rounded_rectangle([cx-140,cy-120,cx+140,cy+60], radius=30, outline=c, width=4)
    d.polygon([(cx-40,cy+60),(cx-80,cy+130),(cx+10,cy+60)], fill=c)
    for dx in [-40, 0, 40]:
        d.ellipse([cx+dx-10,cy-40,cx+dx+10,cy-20], fill=c)

def _icon_lock(d, cx, cy, c, _):
    d.arc([cx-55,cy-160,cx+55,cy-40], start=180, end=0, fill=c, width=5)
    d.line([(cx-55,cy-100),(cx-55,cy-40)], fill=c, width=5)
    d.line([(cx+55,cy-100),(cx+55,cy-40)], fill=c, width=5)
    d.rounded_rectangle([cx-80,cy-50,cx+80,cy+100], radius=10, outline=c, width=4)
    d.ellipse([cx-15,cy-5,cx+15,cy+25], fill=c)
    d.polygon([(cx-8,cy+20),(cx+8,cy+20),(cx+5,cy+60),(cx-5,cy+60)], fill=c)

def _icon_cloud(d, cx, cy, c, _):
    d.ellipse([cx-50,cy-100,cx+80,cy+10], outline=c, width=4)
    d.ellipse([cx-130,cy-60,cx,cy+60], outline=c, width=4)
    d.ellipse([cx+10,cy-50,cx+140,cy+50], outline=c, width=4)
    d.line([(cx-130,cy+50),(cx+140,cy+50)], fill=c, width=5)

def _icon_container(d, cx, cy, c, _):
    d.arc([cx-120,cy-40,cx+120,cy+120], start=180, end=0, fill=c, width=4)
    d.line([(cx-120,cy+40),(cx+120,cy+40)], fill=c, width=4)
    pts = [(x, cy+70+int(12*math.sin((x-cx)*0.05))) for x in range(cx-160,cx+161,20)]
    d.line(pts, fill=c, width=3)
    bw, bh = 30, 22
    for row in range(3):
        for col in range(4-row):
            bx = cx-60+col*(bw+4)+row*17
            by = cy-30-row*(bh+3)
            d.rectangle([bx,by,bx+bw,by+bh], outline=c, width=3)

def _icon_branch(d, cx, cy, c, _):
    d.line([(cx,cy-140),(cx,cy+140)], fill=c, width=5)
    d.line([(cx,cy-40),(cx+90,cy-110)], fill=c, width=4)
    d.line([(cx,cy+30),(cx-90,cy-30)], fill=c, width=4)
    for p in [(cx,cy-140),(cx,cy+140),(cx+90,cy-110),(cx-90,cy-30),(cx,cy-40),(cx,cy+30)]:
        d.ellipse([p[0]-12,p[1]-12,p[0]+12,p[1]+12], fill=c)

def _icon_monitor(d, cx, cy, c, _):
    d.rounded_rectangle([cx-150,cy-130,cx+150,cy+70], radius=8, outline=c, width=4)
    d.line([(cx-40,cy+70),(cx-60,cy+120)], fill=c, width=4)
    d.line([(cx+40,cy+70),(cx+60,cy+120)], fill=c, width=4)
    d.line([(cx-80,cy+120),(cx+80,cy+120)], fill=c, width=4)
    g = [(cx-120,cy+20),(cx-70,cy-10),(cx-20,cy+30),(cx+30,cy-60),(cx+80,cy-30),(cx+120,cy-80)]
    d.line(g, fill=c, width=4)
    d.ellipse([cx+116,cy-86,cx+128,cy-74], fill=c)

def _icon_document(d, cx, cy, c, _):
    fold = 40
    d.polygon([(cx-100,cy-150),(cx+60,cy-150),(cx+100,cy-110),(cx+100,cy+150),(cx-100,cy+150)], outline=c, width=4)
    d.line([(cx+60,cy-150),(cx+60,cy-110),(cx+100,cy-110)], fill=c, width=3)
    for i in range(5):
        y = cy-80+i*40
        d.line([(cx-70,y),(cx-70+(140 if i%3!=2 else 100),y)], fill=c, width=4)

def _icon_phone(d, cx, cy, c, _):
    d.arc([cx-100,cy-100,cx+100,cy+100], start=220, end=320, fill=c, width=8)
    d.rounded_rectangle([cx-120,cy-30,cx-70,cy+40], radius=10, fill=c)
    d.rounded_rectangle([cx+70,cy-30,cx+120,cy+40], radius=10, fill=c)
    for r in [60, 90, 120]:
        d.arc([cx-r,cy-140-r,cx+r,cy-140+r], start=220, end=320, fill=c, width=3)

def _icon_search(d, cx, cy, c, _):
    r = 80
    d.ellipse([cx-r-20,cy-r-60,cx+r-20,cy+r-60], outline=c, width=5)
    d.line([(cx+40,cy+10),(cx+120,cy+110)], fill=c, width=8)
    d.arc([cx-r+10,cy-r-30,cx-20,cy-20], start=200, end=280, fill=c, width=3)

def _icon_money(d, cx, cy, c, _):
    r = 110
    d.arc([cx-r+20,cy-r,cx+r+20,cy+r], start=30, end=330, fill=c, width=6)
    d.line([(cx-r-10,cy-20),(cx+40,cy-20)], fill=c, width=5)
    d.line([(cx-r-10,cy+20),(cx+40,cy+20)], fill=c, width=5)

def _icon_network(d, cx, cy, c, _):
    pos = [(cx,cy-120),(cx-120,cy-40),(cx+120,cy-40),(cx-80,cy+80),(cx+80,cy+80),(cx,cy)]
    for a, b in [(0,1),(0,2),(0,5),(1,3),(1,5),(2,4),(2,5),(3,5),(4,5),(3,4)]:
        d.line([pos[a], pos[b]], fill=c, width=3)
    for x, y in pos:
        d.ellipse([x-14,y-14,x+14,y+14], outline=c, width=4)
        d.ellipse([x-6,y-6,x+6,y+6], fill=c)

def _icon_shield(d, cx, cy, c, _):
    d.polygon([(cx,cy-150),(cx+120,cy-100),(cx+120,cy+20),(cx,cy+150),(cx-120,cy+20),(cx-120,cy-100)], outline=c, width=5)
    d.line([(cx-40,cy-10),(cx-10,cy+30),(cx+50,cy-50)], fill=c, width=6)

def _icon_clock(d, cx, cy, c, _):
    r = 120
    d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=c, width=5)
    d.line([(cx,cy),(cx-30,cy-60)], fill=c, width=5)
    d.line([(cx,cy),(cx+50,cy-70)], fill=c, width=4)
    d.ellipse([cx-8,cy-8,cx+8,cy+8], fill=c)
    for i in range(12):
        a = math.radians(i*30-90)
        x1, y1 = cx+int((r-20)*math.cos(a)), cy+int((r-20)*math.sin(a))
        x2, y2 = cx+int((r-8)*math.cos(a)), cy+int((r-8)*math.sin(a))
        d.line([(x1,y1),(x2,y2)], fill=c, width=3)

def _icon_download(d, cx, cy, c, _):
    d.line([(cx,cy-130),(cx,cy+30)], fill=c, width=6)
    d.polygon([(cx-50,cy+10),(cx,cy+70),(cx+50,cy+10)], fill=c)
    d.line([(cx-100,cy+50),(cx-100,cy+100),(cx+100,cy+100),(cx+100,cy+50)], fill=c, width=5)

def _icon_lightning(d, cx, cy, c, _):
    d.polygon([(cx+10,cy-160),(cx-60,cy-10),(cx-5,cy-10),(cx-30,cy+160),(cx+70,cy-20),(cx+10,cy-20)], outline=c, width=4)

def _icon_link(d, cx, cy, c, _):
    d.rounded_rectangle([cx-130,cy-40,cx-10,cy+40], radius=40, outline=c, width=5)
    d.rounded_rectangle([cx+10,cy-40,cx+130,cy+40], radius=40, outline=c, width=5)
    d.line([(cx-40,cy),(cx+40,cy)], fill=c, width=5)

def _icon_brush(d, cx, cy, c, _):
    d.line([(cx+60,cy-120),(cx-40,cy+40)], fill=c, width=8)
    d.polygon([(cx-50,cy+20),(cx-30,cy+20),(cx-60,cy+70),(cx-80,cy+70)], outline=c, width=4)
    d.polygon([(cx-60,cy+70),(cx-80,cy+70),(cx-90,cy+120),(cx-50,cy+120)], fill=c)

def _icon_server(d, cx, cy, c, _):
    rw, rh = 140, 55
    for i in range(3):
        y = cy-100+i*(rh+10)
        d.rounded_rectangle([cx-rw,y,cx+rw,y+rh], radius=6, outline=c, width=4)
        d.ellipse([cx+rw-30,y+18,cx+rw-12,y+36], fill=c)
        d.line([(cx-rw+15,y+28),(cx-rw+60,y+28)], fill=c, width=4)


# ─── Keyword → icon mapping ─────────────────────────────────────

_KEYWORD_ICONS = {
    ("deploy","release","ship","launch","publish"): _icon_rocket,
    ("debug","bug","fix","patch","hotfix","issue","error"): _icon_bug,
    ("database","db","sql","postgres","mysql","sqlite","supabase","mongo","redis","migration"): _icon_database,
    ("api","endpoint","rest","graphql","grpc","webhook"): _icon_api,
    ("test","qa","spec","jest","pytest","cypress","playwright","vitest","lint","check"): _icon_checkmark,
    ("build","compile","bundle","webpack","vite","config","settings","setup","init"): _icon_gear,
    ("design","ui","ux","css","style","theme","layout","figma","tailwind"): _icon_brush,
    ("email","mail","outlook","smtp","inbox","newsletter"): _icon_envelope,
    ("chat","message","slack","teams","discord","telegram","whatsapp","notify"): _icon_chat,
    ("security","auth","login","oauth","jwt","token","password","encrypt","ssl","cert"): _icon_lock,
    ("cloud","aws","gcp","azure","s3","lambda","vercel","netlify","heroku","cloudflare"): _icon_cloud,
    ("docker","container","kubernetes","k8s","pod","helm","compose"): _icon_container,
    ("git","branch","merge","rebase","commit","pr","pullrequest","github","gitlab"): _icon_branch,
    ("monitor","dashboard","metric","grafana","log","trace","alert","analytics"): _icon_monitor,
    ("write","blog","docs","documentation","readme","article","draft"): _icon_document,
    ("meeting","call","zoom","standup","retro","sync","interview","demo","presentation"): _icon_phone,
    ("research","search","explore","investigate","analyze","audit","review","discovery"): _icon_search,
    ("money","finance","invoice","billing","payment","pricing","budget","revenue","stripe"): _icon_money,
    ("network","dns","proxy","nginx","cdn","tunnel","vpn","firewall","routing"): _icon_network,
    ("backup","protect","guard","waf"): _icon_shield,
    ("schedule","timer","cron","reminder","deadline","calendar"): _icon_clock,
    ("download","install","update","upgrade","import","fetch"): _icon_download,
    ("fast","perf","performance","speed","optimize","cache","benchmark"): _icon_lightning,
    ("url","link","redirect","route","sitemap"): _icon_link,
    ("server","host","rack","vm","instance","compute"): _icon_server,
}

# Build fast lookup: word → draw function
_KW_LOOKUP = {}
for _kws, _fn in _KEYWORD_ICONS.items():
    for _kw in _kws:
        _KW_LOOKUP[_kw] = _fn


def _match_icon(task_name):
    """Find semantic icon for task name. 3-pass: exact word → substring → joined."""
    clean = task_name.lower().replace("-", " ").replace("_", " ")
    words = clean.split()
    # Pass 1: exact word
    for w in words:
        if w in _KW_LOOKUP:
            return _KW_LOOKUP[w]
    # Pass 2: substring match (e.g. "deploying" contains "deploy")
    for w in words:
        for kw, fn in _KW_LOOKUP.items():
            if kw in w or w in kw:
                return fn
    # Pass 3: joined string (e.g. "mydb" contains "db")
    joined = clean.replace(" ", "")
    for kw, fn in _KW_LOOKUP.items():
        if kw in joined:
            return fn
    return None


# ─── Hash-based geometric fallbacks ─────────────────────────────

def _shape_rings(d, cx, cy, c, _):
    for i in range(4, 0, -1):
        r = i * 45
        d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=c, width=4 if i%2==0 else 3)

def _shape_hexagon(d, cx, cy, c, _):
    for s in [1.0, 0.6]:
        r = int(150*s)
        pts = [(cx+int(r*math.cos(math.radians(60*i-30))),cy+int(r*math.sin(math.radians(60*i-30)))) for i in range(6)]
        d.polygon(pts, outline=c, width=5 if s==1.0 else 3)

def _shape_diamonds(d, cx, cy, c, _):
    s = 80
    for dx in [-1,0,1]:
        for dy in [-1,0,1]:
            if abs(dx)+abs(dy)>1: continue
            ox, oy = cx+dx*s, cy+dy*s
            d.polygon([(ox,oy-s//2),(ox+s//2,oy),(ox,oy+s//2),(ox-s//2,oy)], outline=c, width=4)

def _shape_crosshair(d, cx, cy, c, _):
    for r in [120,80,40]:
        d.ellipse([cx-r,cy-r,cx+r,cy+r], outline=c, width=3)
    d.line([cx-140,cy,cx-20,cy], fill=c, width=4)
    d.line([cx+20,cy,cx+140,cy], fill=c, width=4)
    d.line([cx,cy-140,cx,cy-20], fill=c, width=4)
    d.line([cx,cy+20,cx,cy+140], fill=c, width=4)

def _shape_brackets(d, cx, cy, c, _):
    s = 100
    d.line([(cx-60,cy-s),(cx-140,cy),(cx-60,cy+s)], fill=c, width=6)
    d.line([(cx+60,cy-s),(cx+140,cy),(cx+60,cy+s)], fill=c, width=6)
    d.line([(cx+20,cy-s+20),(cx-20,cy+s-20)], fill=c, width=5)

def _shape_pulse(d, cx, cy, c, _):
    pts = [(cx-200,cy),(cx-120,cy),(cx-80,cy-100),(cx-40,cy+80),(cx,cy-120),(cx+40,cy+60),(cx+80,cy-40),(cx+120,cy),(cx+200,cy)]
    d.line(pts, fill=c, width=5)
    d.ellipse([cx-8,cy-8,cx+8,cy+8], fill=c)

def _shape_layers(d, cx, cy, c, _):
    for i in range(3):
        off = i*25
        d.rounded_rectangle([cx-160+off,cy-100+off,cx+160+off,cy+60+off], radius=12, outline=c, width=4)

_SHAPES = [_shape_rings, _shape_hexagon, _shape_diamonds, _shape_crosshair, _shape_brackets, _shape_pulse, _shape_layers]


# ─── Custom icon generator ──────────────────────────────────────

def gen_custom(task_name):
    """Semantic match first → hash-based geometric fallback."""
    img = _img()
    d = ImageDraw.Draw(img)
    r, g, b = _hash_color(task_name)
    c = _rgba(r, g, b)
    cx, cy = W // 2, H // 2 - 40

    icon_fn = _match_icon(task_name)
    if icon_fn:
        icon_fn(d, cx, cy, c, None)
    else:
        seed = int(hashlib.sha256(task_name.encode()).hexdigest()[:8], 16)
        _SHAPES[seed % len(_SHAPES)](d, cx, cy, c, None)

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
