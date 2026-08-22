FROM pytorch/pytorch:2.4.0-cuda12.4-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_PREFER_BINARY=1

# 1. System packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    libgl1 \
    libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# 2. Clone ComfyUI and install requirements
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /workspace/ComfyUI
WORKDIR /workspace/ComfyUI
RUN pip install --no-cache-dir -r requirements.txt

# 3. Download CLIP Text Encoder
RUN mkdir -p models/clip && \
    curl -L -f "https://huggingface.co/Comfy-Org/Qwen3-VL/resolve/main/text_encoders/qwen3vl_4b_fp8_scaled.safetensors?download=true" \
    -o models/clip/qwen3vl_4b_fp8_scaled.safetensors

# 4. Download VAE
RUN mkdir -p models/vae && \
    curl -L -f "https://huggingface.co/Comfy-Org/Krea-2/resolve/main/vae/qwen_image_vae.safetensors?download=true" \
    -o models/vae/qwen_image_vae.safetensors

# 5. Download UNET (Civitai API)
ARG CIVITAI_TOKEN
RUN mkdir -p models/unet && \
    curl -L -f \
    -H "Authorization: Bearer ${CIVITAI_TOKEN}" \
    "https://civitai.com/api/download/models/3204838?fileId=3088379" \
    -o models/unet/gonzalomoKrea2_v30.safetensors

EXPOSE 8188

CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188", "--highvram"]