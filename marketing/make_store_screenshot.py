import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = "/home/user/colouring-app-for-kids/ColoringFun/ColoringFun/Assets.xcassets"
OUT = "/home/user/colouring-app-for-kids/store_screenshot_1.png"
FONT = "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"

W, H = 1290, 2796
TOP, BOT = (255, 247, 219), (216, 240, 255)
INK = (60, 52, 96)

def font(sz): return ImageFont.truetype(FONT, sz)

def asset(name):
    p = os.path.join(ROOT, f"{name}.imageset", f"{name}.png")
    return p if os.path.exists(p) else None

picks = [
    ("princess_royal", "Princess", (255, 219, 199)),
    ("fairy_rainbow",  "Fairy",    (204, 230, 255)),
    ("unicorn_rainbow","Unicorn",  (255, 217, 235)),
    ("lion",           "Animals",  (255, 222, 168)),
    ("trex",           "Dinosaurs",(205, 234, 205)),
    ("car_race",       "Cars",     (255, 214, 204)),
]
picks = [(a, l, t) for (a, l, t) in picks if asset(a)]

# Background gradient
bg = Image.new("RGB", (W, H))
d = ImageDraw.Draw(bg)
for y in range(H):
    t = y / (H - 1)
    d.line([(0, y), (W, y)], fill=tuple(int(TOP[i]*(1-t)+BOT[i]*t) for i in range(3)))
bg = bg.convert("RGBA")

dr = ImageDraw.Draw(bg)

def center_text(y, text, f, fill):
    w = dr.textbbox((0, 0), text, font=f)[2]
    dr.text(((W - w)//2, y), text, font=f, fill=fill)

# Title + caption
center_text(150, "Coloring Fun", font(110), INK)
# caption pill
cap = "Color hundreds of cute pictures!"
cf = font(52)
cw = dr.textbbox((0,0), cap, font=cf)[2]
px, py = (W-cw)//2 - 36, 300
dr.rounded_rectangle([px, py, px+cw+72, py+92], 46, fill=(255,255,255,235))
dr.text(((W-cw)//2, py+18), cap, font=cf, fill=(120,90,200))

def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0,0,size[0],size[1]], radius, fill=255)
    return m

# Grid of cards
cols, rows = 2, 3
margin_x, gap = 70, 46
cw_card = (W - 2*margin_x - gap*(cols-1)) // cols
ch_img = cw_card
label_h = 70
start_y = 455
row_gap = 58

for idx, (a, label, tint) in enumerate(picks):
    r, c = divmod(idx, cols)
    x = margin_x + c*(cw_card + gap)
    y = start_y + r*(ch_img + label_h + row_gap)

    # shadow
    sh = Image.new("RGBA", (W, H), (0,0,0,0))
    ImageDraw.Draw(sh).rounded_rectangle([x, y+12, x+cw_card, y+ch_img+12], 46, fill=(60,40,90,55))
    sh = sh.filter(ImageFilter.GaussianBlur(8))
    bg.alpha_composite(sh)

    # card tint
    card = Image.new("RGBA", (cw_card, ch_img), (0,0,0,0))
    cd = ImageDraw.Draw(card)
    cd.rounded_rectangle([0,0,cw_card,ch_img], 46, fill=tint+(255,))

    # outline image (flatten on white), pasted with padding, rounded
    img = Image.open(asset(a)).convert("RGBA")
    white = Image.new("RGBA", img.size, (255,255,255,255))
    white.alpha_composite(img)
    img = white.convert("RGB")
    pad = 26
    iw = cw_card - 2*pad
    ih = ch_img - 2*pad
    s = min(iw/img.width, ih/img.height)
    nw, nh = int(img.width*s), int(img.height*s)
    img = img.resize((nw, nh))
    inner = Image.new("RGBA", (nw, nh), (255,255,255,255))
    inner.paste(img, (0,0))
    inner.putalpha(rounded_mask((nw,nh), 30))
    card.alpha_composite(inner, ((cw_card-nw)//2, (ch_img-nh)//2))

    # white border
    cd.rounded_rectangle([4,4,cw_card-4,ch_img-4], 44, outline=(255,255,255,255), width=10)
    bg.alpha_composite(card, (x, y))

    # label
    lf = font(46)
    lw = dr.textbbox((0,0), label, font=lf)[2]
    dr.text((x + (cw_card-lw)//2, y+ch_img+10), label, font=lf, fill=INK)

# Footer feature line
foot = "Glitter & sparkle colors  -  Fun stickers  -  Draw your own"
ff = font(44)
fw = dr.textbbox((0,0), foot, font=ff)[2]
fx, fy = (W-fw)//2 - 40, 2540
dr.rounded_rectangle([fx, fy, fx+fw+80, fy+96], 48, fill=(255,255,255,235))
dr.text(((W-fw)//2, fy+24), foot, font=ff, fill=INK)

bg.convert("RGB").save(OUT)
print("Saved", OUT, bg.size, "cards:", len(picks))
