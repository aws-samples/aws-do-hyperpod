#!/bin/bash

# Direct C4 download script - exec into pod with FSx and download
set -e

echo "Starting direct C4 download to FSx..."

kubectl exec -it fsx-cleanup-pod -- bash -c '
set -e

echo "Installing git and git-lfs..."
apt-get update
apt-get install -y git git-lfs

echo "Creating datasets directory..."
mkdir -p /fsx/datasets
cd /fsx/datasets

echo "Cloning C4 repository (structure only)..."
GIT_LFS_SKIP_SMUDGE=1 git clone https://huggingface.co/datasets/allenai/c4
cd c4

echo "Downloading the en/ dataset (305GB)..."
echo "This will take a while but only downloads what you need"

# Download only en/ files
git lfs pull --include="en/*"

echo "Download complete!"
echo "Checking results:"
ls -la en/ | head -10
echo "Total files: $(find en/ -name "*.json.gz" | wc -l)"
echo "Total size: $(du -sh en/)"

echo "Dataset ready at /fsx/datasets/c4/en/"
'

echo "C4 download completed! Dataset is available at /fsx/datasets/c4/en/"
