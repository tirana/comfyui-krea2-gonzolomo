# comfyui-krea2-gonzolomo

RunPod serverless ComfyUI worker (`rpc_handler.py`). One Dockerfile builds one
image per model variant listed in `variants.json`; the workflow builds every
enabled variant one after another and pushes each as
`ghcr.io/<repo>:<tag>`. There is no `:latest`; pin each endpoint to its tag.

| Tag | UNET (`models/unet`) | Text encoder (`models/clip`) | VAE (`models/vae`) | Sampler |
|---|---|---|---|---|
| `krea2-gonzalomo-v4` | `gonzalomoKrea2_v40.safetensors` | `qwen3vl_4b_fp8_scaled.safetensors` | `qwen_image_vae.safetensors` | Krea 2 |
| `qwen-image-2.1-uc` | `qwen_image_2.1_uc_int8_convrot.safetensors` | `qwen3vl_8b_fp8_heretic.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | euler / simple, 25 steps, cfg 1 |
| `noct-q-v2` | `NoctQ_V2_base_int8_convrot.safetensors` (Base)<br>`NoctQ_V2_turbo_int8_convrot.safetensors` (Turbo) | `qwen3vl_8b_int8_convrot.safetensors` | `qwen_image_2.1_vae_bf16.safetensors` | Base: euler / simple, 25–50 steps, cfg 1<br>Turbo: euler, 5 steps, cfg 1, `ManualSigmas` schedule from the Noct-Q workflow |

Qwen-Image 2.1 variants load the text encoder with `CLIPLoader` (type
`qwen_image`) and encode with `TextEncodeQwenImage21`; the same files cover
text-to-image and image edit.

To add a variant, add an entry to `variants.json`; `unets` can list several
UNETs for one image, and the workflow JSON picks one by file name. Entries with
`"enabled": false` are skipped on push but can be built on their own from
Actions → Run workflow → `variant`. Civitai URLs (civitai.com or civitai.red)
are downloaded with the `CIVITAI_TOKEN` secret.
