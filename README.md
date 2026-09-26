# comfyui-krea2-gonzolomo

RunPod serverless ComfyUI worker (`rpc_handler.py`). One Dockerfile builds one
image per model variant listed in `variants.json`; the workflow builds every
enabled variant one after another and pushes each as
`ghcr.io/<repo>:<tag>`. There is no `:latest`; pin each endpoint to its tag.
Each build is also pushed as `<tag>-<commit>-<run>` (e.g.
`klein9b-true-v3-0e1dba9-42`), which never moves: pin an endpoint to that to
keep it on one build while `<tag>` follows the newest.
Which variants build on push is the `enabled` flag in `variants.json`; the
others stay listed with `"enabled": false`.
A variant's optional `loras` list is downloaded into `models/loras`; the three
Klein variants carry `klein_slider_anatomy.safetensors` (Klein Anatomy /
Quality Fixer v1.5, Civitai), which the Klein workflows load at 2.5.

| Tag | UNET (`models/unet`) | Text encoder (`models/clip`) | VAE (`models/vae`) | Sampler |
|---|---|---|---|---|
| `klein9b-bfl-fp8` | `flux-2-klein-9b-fp8.safetensors` (official, BFL) | `qwen_3_8b_fp8mixed.safetensors` | `flux2-vae.safetensors` | euler, Flux2Scheduler, 4 steps, cfg 1 |
| `klein9b-gonzalomo-v1` | `gonzalomoKlein_v10_fp8.safetensors` | `qwen_3_8b_fp8mixed.safetensors` | `flux2-vae.safetensors` | euler / beta, 8 steps, cfg 1 |
| `klein9b-true-v3` | `Flux2-Klein-9B-True-V3-fp8mixed.safetensors` (wikeeyang, Hugging Face) | `qwen_3_8b_fp8mixed.safetensors` | `flux2-vae.safetensors` | euler, Flux2Scheduler, 25 steps, cfg 1 |
| `krea2-gonzalomo-v4` | `gonzalomoKrea2_v40.safetensors` | `qwen3vl_4b_fp8_scaled.safetensors` | `qwen_image_vae.safetensors` | Krea 2 |
| `qwen-image-2.1` | `qwen_image_2.1_int8_convrot.safetensors` (official, Comfy-Org) | `qwen3vl_8b_int8_convrot.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | euler / simple, 40 steps, cfg 1 |
| `noct-q-v2` | `NoctQ_V2_base_int8_convrot.safetensors` (Base)<br>`NoctQ_V2_turbo_int8_convrot.safetensors` (Turbo) | `qwen3vl_8b_int8_convrot.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | Base: euler / simple, 25–50 steps, cfg 1<br>Turbo: euler, 5 steps, cfg 1, `ManualSigmas` schedule from the Noct-Q workflow |

Qwen-Image 2.1 variants load the text encoder with `CLIPLoader` (type
`qwen_image`) and encode with `TextEncodeQwenImage21`; the same files cover
text-to-image and image edit.

The image uses PyTorch built for CUDA 13 (cu130), which ComfyUI's comfy_kitchen
CUDA/Triton kernels need (with cu128 they are disabled and int8/fp8 models run
on the slow eager path). CUDA 13 needs an NVIDIA driver 580 or newer, so set
each endpoint's allowed CUDA versions to 13.0 in RunPod.

ComfyUI is pinned by `COMFYUI_VERSION` in the Dockerfile. Keep it on the latest
published release (https://github.com/Comfy-Org/ComfyUI/releases/latest) and
bump it when a new one ships.

To add a variant, add an entry to `variants.json`; `unets` can list several
UNETs for one image, and the workflow JSON picks one by file name. Entries with
`"enabled": false` are skipped on push but can be built on their own from
Actions → Run workflow → `variant`. Civitai URLs (civitai.com or civitai.red)
are downloaded with the `CIVITAI_TOKEN` secret. Gated Hugging Face repos (the
official BFL Klein weights) need the `HF_TOKEN` secret: a read token from an
account that accepted the model's license on its Hugging Face page.
