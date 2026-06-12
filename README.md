# Coloring Fun 🎨

A colorful, kid-friendly coloring app for iPhone & iPad, built in **SwiftUI**.
Inspired by tap-to-fill coloring books like *Coloring Games: Painting, Glow*.

## What kids can do

- **Browse themed categories** — 🐾 Animals, 🐦 Birds, 🧚 Fairy, 👸 Princess —
  each holding many pictures (dinos, puppies, owls, penguins, fairies with
  sparkly wings, princesses in flowing gowns, and more).
- **Pick a picture** from the category's gallery.
- **Tap any part to fill it.** Every picture is split into small fillable
  regions, so touching a region instantly paints it with the chosen color.
- **Drag to paint** across several parts in one smooth motion.
- **Four tools** in the toolbar:
  - 💧 **Paint** — clean solid bucket fill.
  - ✏️ **Crayon** — soft waxy crayon texture.
  - ✨ **Glitter** — sparkly shimmering fill.
  - 🧽 **Eraser** — wipe a part back to white.
- **12 bright colors** in a scrolling palette.
- **Undo** the last fill and **Clear** the whole page to start over.
- Gentle **haptic feedback** every time a part is colored.

## How it works

The pictures are not bitmap images — each one is drawn as **vector regions**
(SwiftUI `Path`s) in a 1000×1000 design space. This means:

- Every part is independently tappable and fills crisply at any screen size.
- Hit-testing uses `Path.contains`, picking the top-most region under the
  finger, so overlapping details (spots, eyes…) fill correctly.
- Crayon and glitter textures are rendered with `Canvas` + `drawLayer`
  clipping, with **seeded randomness** so glitter sparkles stay stable
  (no flicker) on every redraw.

## Project layout

```
ColoringFun/
├─ ColoringFun.xcodeproj            # Xcode project (file-system synchronized)
└─ ColoringFun/
   ├─ ColoringFunApp.swift          # App entry point
   ├─ Models.swift                  # Tool, Region, Fill, Palette, RNG
   ├─ ColoringPages.swift           # The 6 vector pictures
   ├─ GalleryView.swift             # Home grid of pictures
   ├─ ColoringScreen.swift          # Canvas + toolbar + color palette
   ├─ ColoringCanvasView.swift      # Drawing, textures & touch-to-fill
   └─ Assets.xcassets               # App icon / accent color
```

## Running it

1. Open `ColoringFun/ColoringFun.xcodeproj` in **Xcode 16** or newer.
2. Select an iPhone simulator (or your device).
3. Press **Run** ▶️.

Requires iOS 17+.

## Adding more pictures

Add a new `ColoringPage` to `Pages.all` in `ColoringPages.swift`. Build it
from the small helpers (`circle`, `ellipse`, `rect`, `poly`, `leaf`) — order
regions back-to-front, and the rest (gallery card, tap-to-fill, tools) works
automatically.
