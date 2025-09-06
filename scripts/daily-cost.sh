#!/usr/bin/env bash
# Daily cost monitoring script for QuantTrader-K8s-Simulator

set -euo pipefail

PROFILE="quanttrader-dev"
# Cost Explorer only operates in us-east-1
CE_REGION="us-east-1"

# Get yesterday's date
YESTERDAY=$(date -v-1d +%Y-%m-%d)
TODAY=$(date +%Y-%m-%d)

echo "=== QuantTrader-K8s Daily Cost Report ==="
echo "Date: $YESTERDAY"
echo "========================================"

# Get cost and usage data
aws ce get-cost-and-usage \
  --time-period Start=$YESTERDAY,End=$TODAY \
  --granularity DAILY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --filter '{"Tags":{"Key":"Project","Values":["quanttrader-k8s"]}}' \
  --profile $PROFILE \
  --region $CE_REGION \
  --output table

echo ""
echo "=== Monthly Cost Summary ==="
MONTH_START=$(date -v1d +%Y-%m-%d)
aws ce get-cost-and-usage \
  --time-period Start=$MONTH_START,End=$TODAY \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --profile $PROFILE \
  --region $CE_REGION \
  --output table
