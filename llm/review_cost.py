import json, sys

cost = json.load(open("cost.json"))
if cost["totalMonthlyCost"] > 5000:
    print("Cost threshold exceeded")
    sys.exit(1)
