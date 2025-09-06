#!/usr/bin/env bash
# Cost alert script for QuantTrader-K8s-Simulator

set -euo pipefail

PROFILE="quanttrader-dev"
REGION="us-west-2"
THRESHOLD=25  # Alert if daily cost exceeds $25

# Get yesterday's cost
YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

COST=$(aws ce get-cost-and-usage \
  --time-period Start=$YESTERDAY,End=$TODAY \
  --granularity DAILY \
  --metrics BlendedCost \
  --filter '{"Tags":{"Key":"Project","Values":["quanttrader-k8s"]}}' \
  --profile $PROFILE \
  --region $REGION \
  --query 'ResultsByTime[0].Total.BlendedCost.Amount' \
  --output text)

if (( $(echo "$COST > $THRESHOLD" | bc -l) )); then
    echo "ALERT: Daily cost $COST exceeds threshold $THRESHOLD"
    # Add notification logic here (email, Slack, etc.)
else
    echo "Cost OK: $COST (threshold: $THRESHOLD)"
fi
