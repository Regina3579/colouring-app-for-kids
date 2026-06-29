import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

SRC = "/root/.claude/uploads/47d1bc20-d264-5089-9c88-5ef773e63f71/56df7da6-IMG_3019.png"
OUT = "/home/user/colouring-app-for-kids/marketing/iphone_create_drawing.png"
FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
W, H = 1290, 2796
TOP, BOT = (255, 247, 219), (216, 240, 255)
INK = (60, 52, 96)

def font(sz): return ImageFont.truetype(FONT, sz)

bg = Image.new("RGB", (W, H)); d = ImageDraw.Draw(bg)
for y in range(H):
    t = y/(H-1); d.line([(0, y), (W, y)], fill=tuple(int(TOP[i]*(1-t)+BOT[i]*t) for i in range(3)))
bg = bg.convert("RGBA"); dr = ImageDraw.Draw(bg)

def center(y, txt, f, fill):
    w = dr.textbbox((0, 0), txt, font=f)[2]; dr.text(((W-w)//2, y), txt, font=f, fill=fill)

def fit(txt, maxw, start):
    sz = start
    while sz > 40:
        if dr.textbbox((0, 0), txt, font=font(sz))[2] <= maxw: return font(sz)
        sz -= 4
    return font(40)

# Title + subtitle pill
title = "Create Your Own Drawing"
tf = fit(title, W-120, 92)
center(140, title, tf, INK)
sub = "Draw, fill, add glitter & stickers"
sf = font(50); sw = dr.textbbox((0,0), sub, font=sf)[2]
px = (W-sw)//2 - 36
dr.rounded_rectangle([px, 280, px+sw+72, 372], 46, fill=(255,255,255,235))
dr.text(((W-sw)//2, 298), sub, font=sf, fill=(120,90,200))

# Screenshot below
shot = Image.open(SRC).convert("RGB")
top_area = 430; bottom_margin = 60
target_h = H - top_area - bottom_margin
s = target_h/shot.height
nw, nh = int(shot.width*s), int(shot.height*s)
shot = shot.resize((nw, nh), Image.LANCZOS)
m = Image.new("L", (nw, nh), 0)
ImageDraw.Draw(m).rounded_rectangle([0, 0, nw, nh], 50, fill=255)
shot = shot.convert("RGBA"); shot.putalpha(m)
x = (W-nw)//2; y = top_area
sh = Image.new("RGBA", (W, H), (0,0,0,0))
ImageDraw.Draw(sh).rounded_rectangle([x, y+16, x+nw, y+nh+16], 50, fill=(60,40,90,70))
bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(18)))
bg.alpha_composite(shot, (x, y))
bg.convert("RGB").save(OUT)
print("saved", OUT)
