# Legacy deep-learning Docker (CUDA 11.3)

Linux container image for the provided Windows Python 3.8 environment.

## Runtime
- Ubuntu 20.04, Python 3.8, CUDA 11.3 runtime, cuDNN 8
- PyTorch 1.10.0+cu113, torchvision 0.11.1+cu113, torchaudio 0.10.0+cu113
- Precompiled mmcv-full 1.4.0 for CUDA 11.3 / torch 1.10.0 / Python 3.8
- All remaining pins in `requirements.txt`, except Windows-only `pycocotools-windows==2.0.0.2` is replaced with Linux `pycocotools==2.0.7`

## Prerequisites

- Linux x86_64 host + NVIDIA GPU + NVIDIA driver compatible with CUDA 11.3
- Docker Engine and NVIDIA Container Toolkit, or Windows Docker Desktop with WSL2 GPU support
- GPU architecture supported by PyTorch 1.10 CUDA 11.3 binaries (modern GPUs may require a newer stack)

## Build

```bash
docker compose build --progress=plain
```

## Run

```bash
docker compose run --rm deeplearning
# Inside the container:
python3.8 /opt/verify_env.py
```

Or run a one-off check:

```bash
docker compose run --rm deeplearning python3.8 /opt/verify_env.py
```

The current repository is mounted to `/workspace` in the container. Use `docker compose run --rm deeplearning python3.8 your_script.py` to run project code.

## Notes / limitations

1. **GPU required for the provided verification script.** Docker image can be built without GPU; to run with GPU use an NVIDIA-enabled runtime. `gpus: all` requires Docker Compose with GPU support.
2. **Legacy stack:** CUDA 11.3 / PyTorch 1.10 can be incompatible with recent NVIDIA GPU architectures. Check GPU compute capability and driver compatibility.
3. **Linux-only package substitution:** `pycocotools-windows` is replaced by the upstream `pycocotools`; the package API is similar but this is not an identical binary reproduction.
4. **No insecure SSL bypass:** if corporate TLS interception blocks PyTorch/OpenMMLab, configure Docker's trusted corporate CA rather than using `--trusted-host`.
5. **Source build avoided:** MMCV is explicitly installed with `--only-binary mmcv-full` and the exact official wheel index; fail-fast is intentional if the binary cannot be found.
6. **Build not yet tested:** availability of pinned dependencies and GPU functionality must be verified on your target host. In particular, check NumPy/OpenCV compatibility and whether pip reports conflicts during the build.
7. **Storage:** the Torch CUDA wheel and Docker layers use several GB of disk space.
8. **Security:** versions are frozen to legacy releases for project compatibility and may contain known vulnerabilities. Avoid exposing this container to untrusted networks.

## Troubleshooting

- `docker compose ...` reports an unavailable GPU: check NVIDIA drivers, NVIDIA Container Toolkit/WSL2 GPU and Docker's GPU runtime.
- MMCV source build happens: the prebuilt wheel URL was not available or your platform is not Linux x86_64/Python 3.8.
- `CERTIFICATE_VERIFY_FAILED`: import the trusted internal CA certificate into the image's system certificate store; do not disable verification for routine builds.
- `No matching distribution` / `ResolutionImpossible`: identify the conflicting pin in the plain build logs; do not blindly remove the other version constraints.

Official binaries:
- https://download.pytorch.org/whl/torch_stable.html
- https://download.openmmlab.com/mmcv/dist/cu113/torch1.10.0/index.html

## Offline Ubuntu deployment (build on Windows, transfer by USB/SSD)

On an **online Windows** machine with Docker Desktop configured for Linux/WSL2 containers:

```powershell
docker compose build --progress=plain
docker compose run --rm deeplearning python3.8 /opt/verify_env.py
powershell -ExecutionPolicy Bypass -File .\scripts\export-image.ps1
```

The export script writes `deeplearning-legacy-cu113.tar` and `deeplearning-legacy-cu113.tar.sha256`. Transfer both files to the Ubuntu machine via removable storage. The checksum detects corruption during transfer. For a very large image, choose an exFAT/NTFS-formatted disk rather than FAT32.

On the **offline Ubuntu** machine (Docker Engine, NVIDIA driver, and NVIDIA Container Toolkit must already be installed):

```bash
bash scripts/import-image.sh deeplearning-legacy-cu113.tar
docker run --rm --gpus all deeplearning-legacy:cu113 python3.8 /opt/verify_env.py
docker run --rm -it --gpus all -v "$PWD:/workspace" -w /workspace deeplearning-legacy:cu113
```

If only the TAR files were transferred and the repository scripts were not copied, use `sha256sum -c deeplearning-legacy-cu113.tar.sha256` followed by `docker load -i deeplearning-legacy-cu113.tar`.

Use `docker load`, **not** `docker compose build` or `docker pull`, on the offline host. The image includes Python packages, CUDA runtime, and application libraries; it does **not** include the Ubuntu host's kernel NVIDIA driver, Docker Engine, or NVIDIA Container Toolkit. Host architecture must be Linux amd64, and the GPU architecture/driver must be compatible with the legacy CUDA 11.3 stack.

The image's `CMD` is `bash`. Mount your project/source and models separately, as these are not included in the image. The host must have sufficient disk space for the TAR and loaded image.

On Windows hosts without an NVIDIA GPU, image **build/export** is still possible; GPU verification must then be performed on an NVIDIA-equipped machine.
