import os
import json
import time
import base64
import urllib.request
import urllib.error
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

def save_input_images(images_payload):
    """Saves base64 input images to the ComfyUI input folder."""
    input_dir = "/workspace/ComfyUI/input"
    os.makedirs(input_dir, exist_ok=True)

    if not images_payload:
        return

    # Handle list of image objects: [{"name": "file.png", "image": "base64..."}]
    if isinstance(images_payload, list):
        for item in images_payload:
            name = item.get("name")
            data = item.get("image", "")
            if name and data:
                if "," in data:
                    data = data.split(",")[1]
                filepath = os.path.join(input_dir, name)
                with open(filepath, "wb") as f:
                    f.write(base64.b64decode(data))

    # Handle dictionary format: {"file.png": "base64..."}
    elif isinstance(images_payload, dict):
        for name, data in images_payload.items():
            if name and data:
                if "," in data:
                    data = data.split(",")[1]
                filepath = os.path.join(input_dir, name)
                with open(filepath, "wb") as f:
                    f.write(base64.b64decode(data))

def queue_prompt(workflow):
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request("http://127.0.0.1:8188/prompt", data=data)
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read()), None
    except urllib.error.HTTPError as e:
        error_body = e.read().decode("utf-8")
        try:
            return None, json.loads(error_body)
        except Exception:
            return None, {"error": error_body}

def get_history(prompt_id):
    req = urllib.request.Request(f"http://127.0.0.1:8188/history/{prompt_id}")
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read())

def handler(job):
    job_input = job.get("input", {})
    workflow = job_input.get("workflow")
    if not workflow:
        return {"error": "Missing 'workflow' JSON graph in input payload"}

    # Save uploaded input images before sending workflow to ComfyUI
    images_payload = job_input.get("images") or job_input.get("input_images")
    if images_payload:
        save_input_images(images_payload)

    res, error = queue_prompt(workflow)
    if error:
        return {"error": "ComfyUI prompt validation failed", "details": error}

    prompt_id = res.get("prompt_id")
    if not prompt_id:
        return {"error": "Failed to retrieve prompt_id", "response": res}

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
                        images.append({
                            "filename": file,
                            "type": "base64",
                            "data": base64.b64encode(f.read()).decode("utf-8"),
                        })
                    os.remove(path)

    return {"images": images}

runpod.serverless.start({"handler": handler})