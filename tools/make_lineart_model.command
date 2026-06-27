#!/bin/bash
# One-shot builder for PhotoLineArt.mlpackage (the AI photo->coloring model).
# Run on a Mac with internet:  bash make_lineart_model.command
# It sets up everything and saves PhotoLineArt.mlpackage to your Desktop.
set -e

echo "▶ Building the photo→coloring AI model. First run takes a few minutes…"
WORK="$HOME/lineart_build"
mkdir -p "$WORK"; cd "$WORK"

# 1) Python virtual environment (fixes the 'pip: command not found' problem).
python3 -m venv venv
source venv/bin/activate
python -m pip install --upgrade pip >/dev/null
echo "▶ Installing PyTorch + Core ML tools (large download, one time)…"
python -m pip install torch torchvision coremltools gdown pillow >/dev/null

# 2) Model source code.
[ -d informative-drawings ] || git clone --depth 1 https://github.com/carolineec/informative-drawings
cd informative-drawings

# 3) Pre-trained weights from Google Drive.
mkdir -p checkpoints
if ! find checkpoints -name 'netG_A_latest.pth' | grep -q .; then
  echo "▶ Downloading model weights…"
  gdown 1MIdHzecxz-z0uY3ARL_R40DlKcuQxiDk -O checkpoints/model.zip
  ( cd checkpoints && unzip -o model.zip >/dev/null )
fi
WEIGHTS="$(find "$PWD/checkpoints" -name 'netG_A_latest.pth' | head -1)"
echo "▶ Using weights: $WEIGHTS"

# 4) Convert to Core ML.
echo "▶ Converting to Core ML…"
REPO="$PWD" OUT="$HOME/Desktop/PhotoLineArt.mlpackage" SIZE=512 WEIGHTS="$WEIGHTS" \
python - <<'PY'
import os, sys, torch, coremltools as ct
sys.path.insert(0, os.environ["REPO"])
from model import Generator
size = int(os.environ.get("SIZE", "512"))
net = Generator(3, 1, 3)
net.load_state_dict(torch.load(os.environ["WEIGHTS"], map_location="cpu"))
net.eval()

class Wrap(torch.nn.Module):
    def __init__(self, g):
        super().__init__(); self.g = g
    def forward(self, x):
        y = self.g(x).clamp(0, 1)
        return y.repeat(1, 3, 1, 1) * 255.0   # 1ch [0,1] -> 3ch 0..255 image output

ex = torch.rand(1, 3, size, size)
tr = torch.jit.trace(Wrap(net).eval(), ex)
ml = ct.convert(
    tr,
    inputs=[ct.ImageType(name="image", shape=ex.shape, scale=1/255.0, bias=[0, 0, 0],
                         color_layout=ct.colorlayout.RGB)],
    outputs=[ct.ImageType(name="lineArt", color_layout=ct.colorlayout.RGB)],
    minimum_deployment_target=ct.target.iOS16,
    convert_to="mlprogram",
)
ml.short_description = "Photo to line-art outline for coloring."
ml.save(os.environ["OUT"])
print("SAVED", os.environ["OUT"])
PY

echo ""
echo "✅ Done!  Model saved to your Desktop:  PhotoLineArt.mlpackage"
echo "   Next: drag PhotoLineArt.mlpackage into the ColoringFun/ColoringFun folder"
echo "   in Xcode (make sure the ColoringFun target is checked), then build & run."
