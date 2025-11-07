#!/bin/bash
python3 inference/load_test.py \
  --endpoint mistral-autoscale-endpoint \
  --requests 200 \
  --rps 10 \
  --duration 10 \
  --workers 15