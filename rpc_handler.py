import os
import json
import time
import base64
import urllib.request
import subprocess
import runpod

# Start ComfyUI headlessly in the background
subprocess.Popen(
    [
        "python3", "main.py",
        "--listen", "127.0.0.1",
        "--port", "8188",
        "--highvram",
        "--disable-auto-launch"
    ],
    cwd="/workspace/ComfyUI"
)

def wait_for_comfyui(url="http://127.0.0.1:8188/system_stats", timeout=30):
    start = time.time()
    while time.time() - start < timeout:
        try:
            with urllib.request.urlopen(url) as res:
                if res.status == 200:
                    return True
        except Exception:
            time.sleep(0.5)
    return False

# Block until ComfyUI is up and responding
wait_for_comfyui()

def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request("http://127.0.0.1:8188/prompt", data=data)
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

def get_history(prompt_id):
    req = urllib.request.Request(f"http://127.0.0.1:8188/history/{prompt_id}")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

def handler(job):
    workflow = job["input"].get("workflow")
    if not workflow:
        return {"error": "Missing 'workflow' JSON graph in input payload"}

    res = queue_prompt(workflow)
    prompt_id = res.get("prompt_id")

    # Poll execution status
    for _ in range(180):
        time.sleep(1)
        history = get_history(prompt_id)
        if prompt_id in history:
            break

    # Extract generated image outputs
    output_dir = "/workspace/ComfyUI/output"
    images = []
    if os.path.exists(output_dir):
        for root, _, files in os.walk(output_dir):
            for file in sorted(files):
                if file.endswith((".png", ".jpg", ".webp")):
                    path = os.path.join(root, file)
                    with open(path, "rb") as f:
                        images.append(base64.b64encode(f.read()).decode("utf-8"))
                    os.remove(path)

    return {"images": images}

runpod.serverless.start({"handler": handler})
