from fastapi import FastAPI
import yaml, subprocess

app = FastAPI()

@app.post("/env")
def create_env(payload: dict):
    env = payload["environment"]
    intent_file = f"intents/{env}.yaml"

    with open(intent_file) as f:
        intent = yaml.safe_load(f)

    subprocess.run(["python", "llm/generate_tf.py", intent_file], check=True)
    subprocess.run(["terragrunt", "run-all", "apply"], check=True)

    return {"status": "Provisioning started", "environment": env}
