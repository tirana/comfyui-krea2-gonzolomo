# syntax=docker/dockerfile:1
FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

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

# 2. Clone ComfyUI from main / HEAD
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI

# 3. Install PyTorch from official index + ComfyUI dependencies
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu128 && \
    pip install --no-cache-dir -r /workspace/ComfyUI/requirements.txt && \
    pip install --no-cache-dir runpod websocket-client

# 4. Download Qwen3-VL CLIP text encoder
RUN mkdir -p /workspace/ComfyUI/models/clip && \
    curl -L -f "https://huggingface.co/Comfy-Org/Qwen3-VL/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors?download=true" \
    -o /workspace/ComfyUI/models/clip/qwen3vl_4b_fp8_scaled.safetensors

# 5. Download Krea-2 VAE
RUN mkdir -p /workspace/ComfyUI/models/vae && \
    curl -L -f "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors?download=true" \
    -o /workspace/ComfyUI/models/vae/qwen_image_vae.safetensors

# 6. Download GonzaLomo Krea 2 UNET
RUN --mount=type=secret,id=CIVITAI_TOKEN \
    mkdir -p /workspace/ComfyUI/models/unet && \
    curl -L -f \
    -H "Authorization: Bearer $(cat /run/secrets/CIVITAI_TOKEN)" \
    "https://civitai.com/api/download/models/3204838?fileId=3088379" \
    -o /workspace/ComfyUI/models/unet/gonzalomoKrea2_v30.safetensors

# 7. Copy Serverless Handler
COPY rpc_handler.py /workspace/rpc_handler.py

WORKDIR /workspace
CMD ["python3", "-u", "rpc_handler.py"]
