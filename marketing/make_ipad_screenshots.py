import os
from PIL import Image, ImageDraw, ImageFilter

UP = "/root/.claude/uploads/47d1bc20-d264-5089-9c88-5ef773e63f71"
MK = "/home/user/colouring-app-for-kids/marketing"
OUT = os.path.join(MK, "ipad")
os.makedirs(OUT, exist_ok=True)

IW, IH = 2048, 2732               # iPad 12.9" portrait
TOP, BOT = (255, 247, 219), (216, 240, 255)

sources = [
    (f"{UP}/7d00be3c-IMG_3009.png", "ipad_1_home.png"),
    (f"{UP}/468a732d-IMG_3010.png", "ipad_2_glitter_paint.png"),
    (f"{UP}/5dc2cef1-IMG_3018.png", "ipad_3_fairy.png"),
    (f"{UP}/56df7da6-IMG_3019.png", "ipad_4_drawing.png"),
    (f"{MK}/store_screenshot_1.png", "ipad_5_categories.png"),
    (f"{MK}/store_screenshot_2_colored.png", "ipad_6_colored.png"),
    (f"{MK}/store_screenshot_3_glitter.png", "ipad_7_glittermagic.png"),
]

def gradient():
    g = Image.new("RGB", (IW, IH)); d = ImageDraw.Draw(g)
    for y in range(IH):
        t = y/(IH-1)
        d.line([(0, y), (IW, y)], fill=tuple(int(TOP[i]*(1-t)+BOT[i]*t) for i in range(3)))
    return g.convert("RGBA")

def rounded(img, r):
    m = Image.new("L", img.size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, img.size[0], img.size[1]], r, fill=255)
    out = img.convert("RGBA"); out.putalpha(m); return out

for src, name in sources:
    if not os.path.exists(src):
        print("missing", src); continue
    shot = Image.open(src).convert("RGB")
    pad = 96
    target_h = IH - 2*pad
    s = target_h / shot.height
    nw, nh = int(shot.width*s), int(shot.height*s)
    if nw > IW - 120:                      # safety: fit by width if too wide
        s = (IW - 120)/shot.width; nw, nh = int(shot.width*s), int(shot.height*s)
    shot = shot.resize((nw, nh), Image.LANCZOS)
    shot = rounded(shot, 54)

    bg = gradient()
    x = (IW - nw)//2; y = (IH - nh)//2
    sh = Image.new("RGBA", (IW, IH), (0, 0, 0, 0))
    ImageDraw.Draw(sh).rounded_rectangle([x, y+18, x+nw, y+nh+18], 54, fill=(60, 40, 90, 70))
    bg.alpha_composite(sh.filter(ImageFilter.GaussianBlur(22)))
    # subtle white frame
    fr = Image.new("RGBA", (IW, IH), (0, 0, 0, 0))
    ImageDraw.Draw(fr).rounded_rectangle([x-6, y-6, x+nw+6, y+nh+6], 60,
                                         outline=(255, 255, 255, 235), width=10)
    bg.alpha_composite(fr)
    bg.alpha_composite(shot, (x, y))
    bg.convert("RGB").save(os.path.join(OUT, name))
    print("saved", name, bg.size)
