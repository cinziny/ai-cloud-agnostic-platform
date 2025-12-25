from fastapi import FastAPI
import subprocess
import yaml

app = FastAPI()

@app.post("/env")
def create_environment(payload: dict):
    env = payload["environment"]
    intent_file = f"intents/{env}.yaml"

    with open(intent_file) as f:
        yaml.safe_load(f)

    subprocess.run(
        ["python", "llm/generate_tf.py", intent_file],
        check=True
    )

    subprocess.run(
        ["terragrunt", "run-all", "apply"],
        check=True
    )

    return {"status": "provisioning-started", "environment": env}
