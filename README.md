# comfyui-krea2-gonzolomo

RunPod serverless ComfyUI worker for Krea 2 (`rpc_handler.py`). The image tag is
set by `IMAGE_TAG` in `.github/workflows/build-image.yml`; every build also
pushes `:latest`, so pin each endpoint to its own tag.

| Endpoint | Image tag              | UNET                              | LoRAs            |
|----------|------------------------|-----------------------------------|------------------|
| A        | `:krea2-gonzalomo`      | `gonzalomoKrea2_v40.safetensors`  | none             |
| B        | `:base-krea2-and-lora` | `krea2.safetensors` (Turbo, fp8 scaled) | n (image also has face, m; unused) |
| –        | `:krea2-into-realism`  | `into_realism.safetensors` (current Dockerfile) | none |

## Test requests

`test_requests.py` sends the same prompt and seed through each variant:

| Variant        | Endpoint | LoRAs (strength)                                   |
|----------------|----------|----------------------------------------------------|
| `gonzalomo`    | A        | none                                               |
| `lora_n1`..`4` | B        | n 0.8 / 1.0 / 1.2 / 2.0                            |

Sampler: euler/simple, 10 steps (gonzalomo's) for all.

Strengths live in `VARIANTS` in `test_requests.py`. After changing one, run
`--dump` and `--chainlit ../chainlit/workflows` to regenerate both copies.

```sh
export RUNPOD_API_KEY=... ENDPOINT_A=... ENDPOINT_B=...
python3 test_requests.py                  # all variants -> out/<timestamp>/<variant>.png
python3 test_requests.py lora_n1 lora_n2  # just these
python3 test_requests.py --prompt "..." --seed 42
python3 test_requests.py --dump           # rewrite requests/*.json (raw RunPod payloads)
```

`requests/*.json` can also be sent as-is:

```sh
curl -s -X POST "https://api.runpod.ai/v2/$ENDPOINT_B/runsync" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" -H "Content-Type: application/json" \
  -d @requests/lora_n2.json
```
