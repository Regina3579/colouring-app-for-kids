#!/usr/bin/env python3
"""
Turn raw iPhone-simulator screenshots into polished App Store screenshots:
1290 x 2796 (6.7" — iPhone 15/16 Pro Max), each with a colourful gradient
background and a caption above the screenshot.

HOW TO USE (on your Mac):
  pip3 install pillow
  # 1) Capture screenshots on a 6.7" simulator (see the chat instructions).
  # 2) Put them in a folder ./raw  named 01.png, 02.png, 03.png ...
  # 3) Edit CAPTIONS below so each line matches each screenshot.
  python3 tools/make_screenshots.py
  # Finished images appear in ./appstore/  -> upload these to App Store Connect.

If a raw image is already exactly 1290x2796 you can also upload it directly
without this script; this just makes them look nicer with a caption.
"""
import glob
import os
from PIL import Image, ImageDraw, ImageFont

OUT_W, OUT_H = 1290, 2796
TOP_COLOR = (255, 247, 219)      # warm
BOTTOM_COLOR = (214, 240, 255)   # cool
INK = (60, 52, 96)

# One caption per screenshot, in order. Keep them short (1 line).
CAPTIONS = [
    "Hundreds of cute pictures to color!",
    "Just tap any part to fill it in",
    "Glitter & sparkle magic colors",
    "Create your very own drawings",
    "Add fun stickers — move & resize",
    "Save & share your masterpiece",
    "Color animals, unicorns, princesses & more",
    "Unlock everything with Pro",
]

RAW_DIR = "raw"
OUT_DIR = "appstore"


def load_font(size):
    candidates = [
        "/System/Library/Fonts/SFNSRounded.ttf",
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf",
        "/Library/Fonts/Arial.ttf",
        "/System/Library/Fonts/Supplemental/Arial.ttf",
    ]
    for path in candidates:
        if os.path.exists(path):
            try:
                return ImageFont.truetype(path, size)
            except Exception:
                pass
    return ImageFont.load_default()


def gradient(w, h, top, bottom):
    img = Image.new("RGB", (w, h))
    draw = ImageDraw.Draw(img)
    for y in range(h):
        t = y / (h - 1)
        draw.line([(0, y), (w, y)], fill=(
            int(top[0] * (1 - t) + bottom[0] * t),
            int(top[1] * (1 - t) + bottom[1] * t),
            int(top[2] * (1 - t) + bottom[2] * t),
        ))
    return img


def rounded(img, radius):
    mask = Image.new("L", img.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, img.size[0], img.size[1]], radius, fill=255)
    out = img.convert("RGBA")
    out.putalpha(mask)
    return out


def fit_text(draw, text, font_loader, max_width, start_size):
    size = start_size
    while size > 28:
        font = font_loader(size)
        w = draw.textbbox((0, 0), text, font=font)[2]
        if w <= max_width:
            return font
        size -= 4
    return font_loader(28)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    raws = sorted(glob.glob(os.path.join(RAW_DIR, "*.png")) + glob.glob(os.path.join(RAW_DIR, "*.jpg")))
    if not raws:
        print(f"No images found in ./{RAW_DIR}/  — add 01.png, 02.png, ... there.")
        return

    for i, path in enumerate(raws):
        bg = gradient(OUT_W, OUT_H, TOP_COLOR, BOTTOM_COLOR)
        draw = ImageDraw.Draw(bg)

        # Caption.
        caption = CAPTIONS[i] if i < len(CAPTIONS) else ""
        if caption:
            font = fit_text(draw, caption, load_font, OUT_W - 160, 86)
            tb = draw.textbbox((0, 0), caption, font=font)
            tx = (OUT_W - (tb[2] - tb[0])) // 2
            draw.text((tx, 150), caption, font=font, fill=INK)

        # Screenshot, scaled to ~84% width, placed below the caption.
        shot = Image.open(path).convert("RGB")
        target_w = int(OUT_W * 0.84)
        target_h = int(shot.size[1] * target_w / shot.size[0])
        shot = shot.resize((target_w, target_h))
        shot = rounded(shot, 56)

        x = (OUT_W - target_w) // 2
        y = 320
        # Soft shadow.
        shadow = Image.new("RGBA", bg.size, (0, 0, 0, 0))
        sd = ImageDraw.Draw(shadow)
        sd.rounded_rectangle([x, y + 14, x + target_w, y + target_h + 14], 56, fill=(0, 0, 0, 60))
        bg = Image.alpha_composite(bg.convert("RGBA"), shadow)
        bg.alpha_composite(shot, (x, y))

        out_path = os.path.join(OUT_DIR, f"appstore_{i + 1:02d}.png")
        bg.convert("RGB").save(out_path)
        print("Wrote", out_path)

    print(f"\nDone. Upload the images in ./{OUT_DIR}/ to App Store Connect (6.7\").")


if __name__ == "__main__":
    main()
