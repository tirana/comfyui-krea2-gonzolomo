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
| `krea2-gonzalomo-v4` | `gonzalomoKrea2_v40.safetensors` | `qwen3vl_4b_bf16.safetensors` (bf16 rather than fp8, for better image quality) | `qwen_image_vae.safetensors` | Krea 2 |
| `krea2-snofs-v14` | `snofsSexNudesAndOther_krea2TurboV14.safetensors` (SNOFS Krea 2 Turbo v1.4, int8, Civitai) | `qwen3vl_4b_bf16.safetensors` (bf16, as the SNOFS author uses) | `qwen_image_vae.safetensors` | euler, 8 steps, cfg 1 |
| `qwen-image-2.1` | `qwen_image_2.1_int8_convrot.safetensors` (official, Comfy-Org) | `qwen3vl_8b_int8_convrot.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | euler / simple, 40 steps, cfg 1 |
| `noct-q-v2` | `NoctQ_V2_base_int8_convrot.safetensors` (Base)<br>`NoctQ_V2_turbo_int8_convrot.safetensors` (Turbo) | `qwen3vl_8b_int8_convrot.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | Base: euler / simple, 25–50 steps, cfg 1<br>Turbo: euler, 5 steps, cfg 1, `ManualSigmas` schedule from the Noct-Q workflow |
| `moss-jib-mix-v2` | `Jib_Mix_Moss_V2_H_int8_00001_.safetensors` (Jib Mix Moss Realistic V2, int8, Civitai) | `qwen3.5_9b_int8_convrot.safetensors` (Comfy-Org MOSS-Image) | `flux2-vae.safetensors` (Comfy-Org MOSS-Image) | er_sde, 4–12 steps, cfg 1 (8-step LoRA merged in; the author's `bong_tangent` scheduler is a custom node, not core ComfyUI) |
| `moss-yogi-realism-v1.5` | `Realism_By_Stable_Yogi_Moss_V1.5_INT8_ConvRot.safetensors` (Realism by Stable Yogi Moss V1.5, int8, Civitai; renamed, the original name has spaces and `UNETS` is space-separated) | `qwen3.5_9b_int8_convrot.safetensors` (Comfy-Org MOSS-Image) | `flux2-vae.safetensors` (Comfy-Org MOSS-Image) | er_sde / beta, 10 steps, cfg 1, 1024×1536 |
| `gonzalomo-chroma-v3` | `gonzalomoChroma_v30_UNET_FP8.safetensors` (GonzaLomo Chroma v3.0, Chroma 1 HD blend, fp8, Civitai) | `t5xxl_fp8_e4m3fn_scaled.safetensors` (comfyanonymous flux_text_encoders; Chroma reads T5 only, CLIPLoader type `chroma`) | `ae.safetensors` (the Flux VAE, Comfy-Org z_image_turbo) | euler or dpmpp_2m / simple or beta, 8–14 steps, cfg 1.0–1.3 |
| `dirty-moss-v2` | `Dirty-MossV2.safetensors` (Dirty-Moss V2, bf16, Civitai) | `qwen3.5_9b_int8_convrot.safetensors` (Comfy-Org MOSS-Image) | `flux2-vae.safetensors` (Comfy-Org MOSS-Image) | er_sde / simple, 25 steps, cfg 2.5, shift 5, 1152×1440 |
| `lustify-raw` | `lustify-v10-krea-raw-int8_convrot.safetensors` (LUSTIFY! v10 Krea 2 Raw, the undistilled build, int8, Civitai) | `qwen3vl_4b_bf16.safetensors` | `qwen_image_vae.safetensors` | Krea 2 Raw: about 28 steps, cfg 4.5 |
| `zit-cyberrealistic-v10` | `CyberRealistic_zit_v10.0_int8_convrot.safetensors` (CyberRealistic Z-Image Turbo v10, int8, Civitai) | `qwen_3_4b.safetensors` (Comfy-Org z_image_turbo) | `ae.safetensors` (Comfy-Org z_image_turbo) | 8–9 steps, cfg 1 |
| `noct-q-v4-base-int8` | `NoctQ_V4_int8_convrot.safetensors` (Noct-Q V4.0 Base, the author's own int8, Civitai) | `qwen3vl_8b_int8_convrot.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | euler / simple, 25 steps, cfg 3 with the author's negative prompt |
| `flux3-klein-base-bf16` | `flux3-image-klein-base-bf16.safetensors` (FLUX 3 Image Klein Base, the undistilled 5.6B, official BFL, gated) | `qwen3vl_4b_bf16.safetensors` (BFL's flux-3-image-klein-comfy; CLIPLoader type `flux3`) | `flux2-vae.safetensors` (BFL's flux-3-image-klein-comfy) | euler / simple, 50 steps, cfg 3.5, 1024×1024, empty negative (ComfyUI's official template) |
| `minimax-h3-image-int8` | `minimax_h3_image_pruned_int8_convrot.safetensors` (MiniMax H3 Image, the pruned 33.1B, int8 ConvRot, Comfy-Org) | `qwen3vl_32b_minimax_h3_nvfp4_awq.safetensors` (Comfy-Org MiniMax-H3-Image; the same Qwen3-VL 32B encoder as H3 video) | `minimax_h3_image_vae_fp16.safetensors` (Comfy-Org MiniMax-H3-Image; the H3 video VAE does not work) | 6 steps, cfg 1, no negative prompt (step- and CFG-distilled) |

Qwen-Image 2.1 variants load the text encoder with `CLIPLoader` (type
`qwen_image`) and encode with `TextEncodeQwenImage21`; the same files cover
text-to-image and image edit.

FLUX 3 Image Klein (`flux3-klein-base-bf16`) needs ComfyUI v0.41.0 or newer.
The image leaves out the optional prompt upsampler
(`qwen3.5_9b_flux3_prompt_upsampler_*`, a Qwen 3.5 9B that rewrites the prompt
before rendering), since the prompt arrives fully written. Without it, the bf16
UNET (11.1 GB), the bf16 text encoder (8.9 GB) and the VAE fit a 24 GB GPU;
ComfyUI's template asks for more than 24 GB for bf16 only because it also
loads the upsampler.

MiniMax H3 Image (`minimax-h3-image-int8`) needs ComfyUI v0.45.0 or newer
(native support). One checkpoint does text-to-image and editing with up to 16
reference images. The image leaves out the optional prompt expander
(`qwen3.8_27b_minimax_h3_image_pe_*`). The int8 model (19.5 GiB), the nvfp4
text encoder (14.6 GiB) and the VAE (1.1 GiB) come to about 35 GiB; ComfyUI
can unload the encoder before sampling, so the peak is lower. H3 video, which has
the same model size, peaked at 27–32 GB on a 32 GB RTX 5090 in published tests.

The image uses PyTorch built for CUDA 13 (cu130), which ComfyUI's comfy_kitchen
CUDA/Triton kernels need (with cu128 they are disabled and int8/fp8 models run
on the slow eager path). CUDA 13 needs an NVIDIA driver 580 or newer, so set
each endpoint's allowed CUDA versions to 13.0 in RunPod.

ComfyUI is pinned by `COMFYUI_VERSION` in the Dockerfile. Keep it on the latest
published release (https://github.com/Comfy-Org/ComfyUI/releases/latest) and
bump it when a new one ships. MOSS Image needs v0.42.0 or newer, MiniMax H3
Image v0.45.0 or newer.

To add a variant, add an entry to `variants.json`; `unets` can list several
UNETs for one image, and the workflow JSON picks one by file name. Entries with
`"enabled": false` are skipped on push but can be built on their own from
Actions → Run workflow → `variant`. Civitai URLs (civitai.com or civitai.red)
are downloaded with the `CIVITAI_TOKEN` secret. Gated Hugging Face repos (the
official BFL Klein weights) need the `HF_TOKEN` secret: a read token from an
account that accepted the model's license on its Hugging Face page. FLUX 3
Image Klein is gated on its own: accept the license on
`black-forest-labs/flux-3-image-klein-comfy` as well.
