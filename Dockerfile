# syntax=docker/dockerfile:1
FROM nvidia/cuda:13.0.3-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_PREFER_BINARY=1 \
    TORCH_CUDA_ARCH_LIST="8.0;8.6;8.9;9.0;10.0;12.0"

# 1. System packages & Python
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    python3 \
    python3-pip \
    python3-dev \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 2. Clone ComfyUI at a pinned release. Keep this on the latest published
# release (https://github.com/Comfy-Org/ComfyUI/releases/latest — a release,
# not just a newer tag) and bump it when a new one ships: an unpinned clone is
# a cached build layer, so builds could silently keep an old ComfyUI or pick up
# an unreleased change. Qwen Image 2.1 needs v0.37.0 or newer. Override for a
# one-off build with --build-arg COMFYUI_VERSION=vX.Y.Z.
ARG COMFYUI_VERSION=v0.37.0
RUN git clone --depth 1 --branch "$COMFYUI_VERSION" https://github.com/Comfy-Org/ComfyUI.git /workspace/ComfyUI

# 3. Install PyTorch from official index + ComfyUI dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu130 && \
    pip install --no-cache-dir -r /workspace/ComfyUI/requirements.txt && \
    pip install --no-cache-dir runpod websocket-client

# 4. Download the variant's models. The workflow's build matrix passes the
# URLs and file names (UNETS is space-separated "file|url" pairs, so one image
# can carry several UNETs); the layers above are shared by every variant. Civitai
# downloads (civitai.com / civitai.red) need the CIVITAI_TOKEN secret.
ARG UNETS CLIP_URL CLIP_FILE VAE_URL VAE_FILE
RUN --mount=type=secret,id=CIVITAI_TOKEN,required=false \
    set -e; \
    for v in UNETS CLIP_URL CLIP_FILE VAE_URL VAE_FILE; do \
        eval "[ -n \"\$$v\" ]" || { echo "build arg $v is not set" >&2; exit 1; }; \
    done; \
    dl() { \
        mkdir -p "$(dirname "$2")"; \
        case "$1" in \
            *civitai.*) curl -L -f -H "Authorization: Bearer $(cat /run/secrets/CIVITAI_TOKEN)" "$1" -o "$2" ;; \
            *) curl -L -f "$1" -o "$2" ;; \
        esac; \
    }; \
    for u in $UNETS; do \
        dl "${u#*|}" "/workspace/ComfyUI/models/unet/${u%%|*}"; \
    done; \
    dl "$CLIP_URL" "/workspace/ComfyUI/models/clip/$CLIP_FILE"; \
    dl "$VAE_URL" "/workspace/ComfyUI/models/vae/$VAE_FILE"

# 5. Copy Serverless Handler
COPY rpc_handler.py /workspace/rpc_handler.py

WORKDIR /workspace
CMD ["python3", "-u", "rpc_handler.py"]
