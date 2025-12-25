import yaml, time, subprocess

intent = yaml.safe_load(open("intents/dev.yaml"))
ttl = intent["lifecycle"]["ttlHours"]

time.sleep(ttl * 3600)
subprocess.run(["terragrunt", "run-all", "destroy", "-auto-approve"])
