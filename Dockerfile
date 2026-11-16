FROM nvidia/cuda:11.3.1-cudnn8-runtime-ubuntu20.04

# Optional: use only on trusted, TLS-inspecting networks when CA setup is unavailable.
# Example: docker compose build --build-arg "PIP_TRUSTED_HOST=download.pytorch.org download.openmmlab.com"
# Default is empty, preserving normal TLS verification.
ARG PIP_TRUSTED_HOST=""

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# CUDA/cuDNN are preinstalled in the base image. No NVIDIA APT packages are
# needed here; bypass its optional repository, which may fail TLS verification
# on networks with HTTPS interception, without weakening certificate checks.
RUN rm -f /etc/apt/sources.list.d/cuda.list \
          /etc/apt/sources.list.d/nvidia-ml.list \
    && apt-get update && apt-get install -y --no-install-recommends \
    python3.8 python3-pip python3.8-dev python3-setuptools \
    ca-certificates git \
    libgl1 libglib2.0-0 libsm6 libxext6 libxrender1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# pip 24.0 supports Python 3.8. Avoid unsupported pip 25+ on this legacy runtime.
RUN python3.8 -m pip install --upgrade "pip==24.0" "setuptools<70" wheel

COPY requirements.txt /tmp/requirements.txt

# Use prebuilt CUDA wheels: never compile mmcv-full from source.
# The wheel repositories correspond to torch 1.10.0 / CUDA 11.3.
RUN python3.8 -m pip install \
    --find-links https://download.pytorch.org/whl/torch_stable.html \
    "torch==1.10.0+cu113" \
    "torchvision==0.11.1+cu113" \
    "torchaudio==0.10.0+cu113"

RUN python3.8 -m pip install \
    --find-links https://download.openmmlab.com/mmcv/dist/cu113/torch1.10.0/index.html \
    --only-binary mmcv-full \
    "mmcv-full==1.4.0"

RUN python3.8 -m pip install \
    --find-links https://download.pytorch.org/whl/torch_stable.html \
    --find-links https://download.openmmlab.com/mmcv/dist/cu113/torch1.10.0/index.html \
    --only-binary mmcv-full \
    -r /tmp/requirements.txt \
    && python3.8 -m pip check

COPY scripts/verify_env.py /opt/verify_env.py
CMD ["bash"]
