"""Verify legacy Python/PyTorch/MMCV environment on CPU-only or NVIDIA GPU hosts."""
import argparse
import sys

parser = argparse.ArgumentParser()
parser.add_argument("--require-gpu", action="store_true", help="Fail if CUDA GPU cannot execute")
args = parser.parse_args()

import cv2
import mmcv
import numpy
import torch
import torchaudio
import torchvision

print("Python:", sys.version.split()[0])
print("PyTorch:", torch.__version__, "compiled CUDA:", torch.version.cuda)
print("TorchVision:", torchvision.__version__)
print("TorchAudio:", torchaudio.__version__)
print("MMCV:", mmcv.__version__)
print("NumPy:", numpy.__version__)
print("OpenCV:", cv2.__version__)

import mmcv._ext  # noqa: F401 - compiled extension import
print("MMCV native extension: OK")
from mmcv.ops import nms
print("MMCV NMS import: OK")
from mmcv.ops import nms as _nms
boxes = torch.tensor([[0., 0., 10., 10.], [1., 1., 9., 9.]])
scores = torch.tensor([0.9, 0.8])
dets, indices = _nms(boxes, scores, 0.5)
assert len(indices) == 1, "Unexpected NMS result"
print("MMCV CPU NMS execution: OK")

print("CUDA available:", torch.cuda.is_available())
if torch.cuda.is_available():
    print("CUDA device:", torch.cuda.get_device_name(0))
    tensor = torch.ones(4, device="cuda")
    assert tensor.sum().item() == 4.0
    print("CUDA tensor test: OK")
elif args.require_gpu:
    raise RuntimeError("CUDA GPU is required but not available")
else:
    print("GPU execution skipped (CPU-only verification mode)")
print("Environment verification: PASS")
