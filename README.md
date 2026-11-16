# 딥러닝 Docker 실행 환경

Windows(온라인, GPU 없음)에서 Linux용 Docker 이미지를 빌드한 뒤, 오프라인 Ubuntu 22.04 PC(RTX 3080 Laptop GPU)로 복사해 실행하는 환경입니다.

- **주요 버전:** Python 3.8 / CUDA 11.3 / PyTorch 1.10.0 / MMCV-Full 1.4.0
- **이미지 이름:** `deeplearning-legacy:cu113`
- **사전 준비:** Windows는 Docker Desktop(Linux 컨테이너/WSL2), Ubuntu는 Docker 및 NVIDIA Container Toolkit 설치

## 1. Docker 이미지 빌드 (Windows PowerShell)

```powershell
git clone https://github.com/JaewonYe/deeplearning-docker.git
cd deeplearning-docker
docker compose --progress plain build
```

이미 저장소를 내려받았다면 `git pull origin main` 후 빌드합니다.

## 2. 인증서 오류 시 우회 빌드 (Windows PowerShell)

PyTorch/OpenMMLab 다운로드 과정에서 `CERTIFICATE_VERIFY_FAILED`가 발생할 때만 사용합니다.

```powershell
docker compose --progress plain build `
  --build-arg "PIP_TRUSTED_HOST=download.pytorch.org download.openmmlab.com"
```

> 이 옵션은 지정한 서버의 TLS 인증서 검증을 우회합니다. 신뢰할 수 있는 네트워크에서만 임시 사용하고, 가능하면 조직의 CA 인증서를 등록하세요.

## 3. 설치 정상 여부 확인 (Windows, GPU 없음)

```powershell
docker run --rm deeplearning-legacy:cu113 python3.8 /opt/verify_env.py
```

`Environment verification: PASS`가 출력되면 Python 라이브러리와 MMCV CPU 연산 검증에 성공한 것입니다. GPU 검사는 Ubuntu에서 수행합니다.

## 4. Docker 이미지 내보내기 (Windows PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\export-image.ps1
```

생성되는 `deeplearning-legacy-cu113.tar`와 `deeplearning-legacy-cu113.tar.sha256` 파일을 USB/외장 SSD를 통해 Ubuntu로 복사합니다. 4GB 초과 파일 전송을 위해 exFAT 또는 NTFS를 사용하세요.

## 5. Docker 이미지 불러오기 (오프라인 Ubuntu)

두 파일과 `scripts/import-image.sh`를 복사한 위치에서 실행합니다.

```bash
bash scripts/import-image.sh deeplearning-legacy-cu113.tar
```

스크립트가 없다면 다음 명령어를 사용합니다.

```bash
sha256sum -c deeplearning-legacy-cu113.tar.sha256
docker load -i deeplearning-legacy-cu113.tar
```

## 6. 이미지 등록 확인 (Ubuntu)

```bash
docker images deeplearning-legacy
```

`deeplearning-legacy`의 `cu113` 태그가 표시되면 등록된 것입니다.

## 7. GPU 테스트 (Ubuntu)

```bash
docker run --rm --gpus all deeplearning-legacy:cu113 \
  python3.8 /opt/verify_env.py --require-gpu
```

`CUDA available: True`와 `Environment verification: PASS`가 출력되면 GPU 기본 연산까지 통과한 것입니다.

## 8. 추론 코드 실행 (Ubuntu)

추론 소스, 모델 가중치, 입력 데이터를 하나의 작업 폴더(예: `~/inference`)에 준비합니다.

```bash
cd ~/inference
docker run --rm --gpus all \
  -v "$PWD:/workspace" -w /workspace \
  deeplearning-legacy:cu113 \
  python3.8 inference.py --input input.jpg --checkpoint model.pth
```

`inference.py`, `--input`, `--checkpoint`는 예시입니다. 실제 프로젝트의 실행 파일과 인자에 맞게 바꾸세요. 컨테이너의 `/workspace`에서 작업 폴더 파일을 그대로 읽고 결과를 저장할 수 있습니다.


## 9. 컨테이너 터미널에서 Python 실행 (Ubuntu)

현재 폴더를 `/workspace`에 연결하고 컨테이너의 Bash 터미널에 접속합니다.

```bash
cd ~/inference
docker run --rm -it --gpus all \
  -v "$PWD:/workspace" -w /workspace \
  deeplearning-legacy:cu113 bash
```

컨테이너 내부에서 일반 터미널처럼 실행합니다.

```bash
python3.8 inference.py
python3.8 inference.py --input input.jpg --checkpoint model.pth
exit
```

`exit`으로 종료하면 `--rm` 옵션에 따라 컨테이너는 삭제되지만, 연결된 호스트 폴더의 소스·모델·결과 파일은 유지됩니다.
