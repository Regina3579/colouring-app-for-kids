#!/usr/bin/env python3
"""
Convert the "Informative Drawings" photo->line-art model into a Core ML model
named PhotoLineArt.mlpackage, ready to drop into the ColoringFun app.

The app (PhotoColoring.swift / PhotoOutlineAI) auto-detects a bundled model
called `PhotoLineArt` and uses it for AI-quality outlines; until it's present it
falls back to the built-in image filter. So once you produce PhotoLineArt.mlpackage
with this script, just drag it into the ColoringFun/ColoringFun folder in Xcode.

------------------------------------------------------------------------------
ONE-TIME SETUP (run on a Mac or Linux box with internet):

    python3 -m venv venv && source venv/bin/activate
    pip install torch torchvision coremltools

    # Get the model code + weights (Caroline Chan, "Informative Drawings"):
    git clone https://github.com/carolineec/informative-drawings
    # Download a checkpoint into ./informative-drawings/checkpoints/<style>/netG_A_latest.pth
    # (the repo's README links the anime_style / contour_style / opensketch_style weights)

    python3 tools/convert_lineart_coreml.py \
        --repo ./informative-drawings \
        --weights ./informative-drawings/checkpoints/anime_style/netG_A_latest.pth \
        --size 512 \
        --out PhotoLineArt.mlpackage

Then in Xcode: drag PhotoLineArt.mlpackage into the ColoringFun/ColoringFun group
(make sure "ColoringFun" target is checked). Build & run — done.
------------------------------------------------------------------------------

Notes
- We import the Generator architecture directly from the cloned repo's model.py,
  so we don't risk reproducing it incorrectly.
- Output is an image-type model (RGB in, grayscale-ish line image out), which is
  exactly what the app's Vision pipeline (VNPixelBufferObservation) expects.
"""

import argparse
import os
import sys


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, help="Path to cloned informative-drawings repo")
    ap.add_argument("--weights", required=True, help="Path to the generator .pth checkpoint")
    ap.add_argument("--size", type=int, default=512, help="Square model input size (256 or 512)")
    ap.add_argument("--out", default="PhotoLineArt.mlpackage", help="Output Core ML package path")
    args = ap.parse_args()

    sys.path.insert(0, os.path.abspath(args.repo))

    try:
        import torch
        import coremltools as ct
    except ImportError:
        print("Please `pip install torch torchvision coremltools` first.", file=sys.stderr)
        return 1

    # The repo defines `Generator(input_nc, output_nc, n_residual_blocks)` in model.py.
    try:
        from model import Generator  # type: ignore
    except Exception as e:  # pragma: no cover
        print(f"Could not import Generator from {args.repo}/model.py: {e}", file=sys.stderr)
        print("Check the repo path; the file should be informative-drawings/model.py", file=sys.stderr)
        return 1

    net = Generator(3, 1, 3)
    state = torch.load(args.weights, map_location="cpu")
    net.load_state_dict(state)
    net.eval()

    # Wrap so the Core ML output is a 3-channel image (Vision returns it as a
    # pixel buffer we then clean up in the app).
    class Wrapper(torch.nn.Module):
        def __init__(self, g):
            super().__init__()
            self.g = g

        def forward(self, x):
            y = self.g(x)              # (1,1,H,W) line image in [0,1]
            y = y.clamp(0, 1)
            return y.repeat(1, 3, 1, 1)  # -> (1,3,H,W) so it exports as an image

    wrapped = Wrapper(net).eval()
    example = torch.rand(1, 3, args.size, args.size)
    traced = torch.jit.trace(wrapped, example)

    mlmodel = ct.convert(
        traced,
        inputs=[ct.ImageType(name="image", shape=example.shape,
                             scale=1 / 255.0, bias=[0, 0, 0], color_layout=ct.colorlayout.RGB)],
        outputs=[ct.ImageType(name="lineArt", color_layout=ct.colorlayout.RGB)],
        minimum_deployment_target=ct.target.iOS16,
        convert_to="mlprogram",
    )
    mlmodel.short_description = "Photo -> line-art outline for coloring (Informative Drawings)."
    mlmodel.save(args.out)
    print(f"Saved {args.out}")
    print("Now drag it into ColoringFun/ColoringFun in Xcode (target: ColoringFun).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
