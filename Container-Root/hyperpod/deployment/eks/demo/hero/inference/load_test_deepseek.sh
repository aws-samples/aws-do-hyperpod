#!/bin/bash
python3 inference/load_test.py \
  --endpoint deepseek15b-s3 \
  --requests 200 \
  --rps 10 \
  --duration 10 \
  --workers 15