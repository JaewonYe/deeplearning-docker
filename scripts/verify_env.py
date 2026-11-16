"""Verify the legacy PyTorch/MMCV Docker runtime; fails on missing CUDA ops."""
import sys

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

import mmcv._ext  # noqa: F401  -- compiled C++ extension should import
print("MMCV native extension: OK")
try:
    from mmcv.ops import nms
    print("MMCV NMS: import OK")
except Exception as error:
    raise RuntimeError("MMCV ops import failed") from error

if not torch.cuda.is_available():
    raise RuntimeError("CUDA unavailable: run with NVIDIA GPU support enabled")

print("CUDA device:", torch.cuda.get_device_name(0))
tensor = torch.ones(4, device="cuda")
print("CUDA tensor test:", tensor.sum().item())
print("Environment verification: PASS")
