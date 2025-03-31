#!/bin/bash

# Container startup script
echo "Container-Root/startup.sh executed"

. ./config.properties

if [ ! -d ${model_save_path} ]; then mkdir -p $model_save_path; fi

export HF_HOME=$model_save_path

echo -e "\nHF_HOME set to $model_save_path\n"

while true; do date; sleep 10; done &

uvicorn fastapi-server:app --host 0.0.0.0 --port 8080

