import os
import sys
import yaml
import json
from openai import OpenAI

# API key loaded from environment
OPENAI_API_KEY = os.environ.get("OPENAI_API_KEY")

# Initialize OpenAI client
client = OpenAI(api_key=OPENAI_API_KEY)

# Input intent file
intent_file = sys.argv[1]
intent = yaml.safe_load(open(intent_file))

# Ensure required tags exist
required_tags = ["env", "owner", "cost-center"]
intent.setdefault("tags", {})
for t in required_tags:
    intent["tags"].setdefault(t, "unknown")

# Load system prompt
prompt = open("llm/prompts/generate.txt").read()

# Call LLM
resp = client.chat.completions.create(
    model="gpt-4.1",
    temperature=0,
    messages=[
        {"role": "system", "content": prompt},
        {"role": "user", "content": json.dumps(intent)}
    ]
)

# Write Terraform output
os.makedirs("terraform", exist_ok=True)
with open("terraform/main.tf", "w") as f:
    f.write(resp.choices[0].message.content)

print("Terraform generated")
