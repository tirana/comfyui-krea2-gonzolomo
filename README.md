# comfyui-krea2-gonzolomo

RunPod serverless ComfyUI worker for Krea 2 (`rpc_handler.py`). The image tag is
set by `IMAGE_TAG` in `.github/workflows/build-image.yml`; every build also
pushes `:latest`, so pin each endpoint to its own tag.

| Endpoint | Image tag              | UNET                              | LoRAs            |
|----------|------------------------|-----------------------------------|------------------|
| A        | `:krea2-gonzalomo`      | `gonzalomoKrea2_v40.safetensors`  | none             |
| B        | `:base-krea2-and-lora` | `krea2.safetensors` (Turbo, fp8 scaled) | face, m, n       |

## Test requests

`test_requests.py` sends the same prompt and seed through each variant:

| Variant        | Endpoint | LoRAs (strength)                                   |
|----------------|----------|----------------------------------------------------|
| `gonzalomo`    | A        | none                                               |
| `base`         | B        | none                                               |
| `lora_face`    | B        | face 1.0                                           |
| `lora_m1`..`4` | B        | m 2.0 / 0.8 / 1.0 / 1.2                            |
| `lora_n1`..`4` | B        | n 0.8 / 1.0 / 1.2 / 2.0                            |
| `lora_mix_3_1` | B        | face 0.85, m 0.8, n 0.6 (safe & balanced)          |
| `lora_mix_3_2` | B        | face 0.7, m 1.05, n 0.5 (stronger explicitness)    |
| `lora_mix_2_1` | B        | face 1.0, m 1.0                                    |
| `lora_mix_2_2` | B        | face 1.0, n 1.0                                    |

Strengths live in `VARIANTS` in `test_requests.py`. After changing one, run
`--dump` and `--chainlit ../chainlit/workflows` to regenerate both copies.

```sh
export RUNPOD_API_KEY=... ENDPOINT_A=... ENDPOINT_B=...
python3 test_requests.py                  # all variants -> out/<timestamp>/<variant>.png
python3 test_requests.py base lora_m3     # just these
python3 test_requests.py --prompt "..." --seed 42
python3 test_requests.py --dump           # rewrite requests/*.json (raw RunPod payloads)
```

`requests/*.json` can also be sent as-is:

```sh
curl -s -X POST "https://api.runpod.ai/v2/$ENDPOINT_B/runsync" \
  -H "Authorization: Bearer $RUNPOD_API_KEY" -H "Content-Type: application/json" \
  -d @requests/lora1.json
```
