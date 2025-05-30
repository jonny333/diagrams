#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
PROJECT_ID="mmaksimov-sandbox"
# Use the REGIONAL part for Artifact Registry and Cloud Functions region
REGION_FOR_SERVICES="europe-central2"
BUCKET_NAME="diagrams-mmaksimov" # Used as default in Python script

# Artifact Registry settings
REPO_NAME="diagram-generator-repo" # Your chosen repository name
IMAGE_NAME="diagram-generator"
IMAGE_TAG="latest"

# Cloud Function settings
FUNCTION_NAME="generate-real-estate-diagram"
FUNCTION_MEMORY="512MiB" # Adjust as needed, start small
FUNCTION_TIMEOUT="120s"  # Max 9 minutes (540s) for HTTP functions

# Construct the full image path for Artifact Registry
FULL_IMAGE_PATH="${REGION_FOR_SERVICES}-docker.pkg.dev/${PROJECT_ID}/${REPO_NAME}/${IMAGE_NAME}:${IMAGE_TAG}"

# --- Steps ---

echo "Step 1: Authenticate Docker with Artifact Registry (${REGION_FOR_SERVICES})"
gcloud auth configure-docker "${REGION_FOR_SERVICES}-docker.pkg.dev" -q

echo "Step 2: Create Artifact Registry repository (if it doesn't exist)"
gcloud artifacts repositories create "${REPO_NAME}" \
    --project="${PROJECT_ID}" \
    --repository-format=docker \
    --location="${REGION_FOR_SERVICES}" \
    --description="Repository for diagram generator images" \
    || echo "Repository ${REPO_NAME} already exists or failed to create."

echo "Step 3: Build the Docker image"
docker build -t "${FULL_IMAGE_PATH}" .

echo "Step 4: Push the Docker image to Artifact Registry"
docker push "${FULL_IMAGE_PATH}"

echo "Step 5: Deploy Cloud Function (Gen2)"
gcloud functions deploy "${FUNCTION_NAME}" \
    --project="${PROJECT_ID}" \
    --gen2 \
    --region="${REGION_FOR_SERVICES}" \
    --runtime=python310 # Specify a runtime even for container; helps with buildpack selection if not fully custom
    --container-image="${FULL_IMAGE_PATH}" \
    --entry-point=main_http_entrypoint \
    --trigger-http \
    --allow-unauthenticated \
    --memory="${FUNCTION_MEMORY}" \
    --timeout="${FUNCTION_TIMEOUT}" \
    --set-env-vars="BUCKET_NAME=${BUCKET_NAME},BLOB_NAME=default_diagram.png" # Set default env vars

echo "--- Deployment Complete ---"
echo "Function Name: ${FUNCTION_NAME}"
echo "Trigger URL will be shown above by gcloud command output."
echo "Make sure the GCS bucket '${BUCKET_NAME}' exists and the function's service account has 'Storage Object Creator' or 'Storage Object Admin' role on it."

# To test after deployment:
# 1. Get the HTTPS trigger URL from the `gcloud functions deploy` output.
# 2. curl -X POST -H "Content-Type: application/json" YOUR_FUNCTION_TRIGGER_URL
# 3. Or, send a POST request with custom bucket/blob names:
#    curl -X POST -H "Content-Type: application/json" -d '{"bucket_name": "diagrams-mmaksimov", "blob_name": "my_custom_diagram.svg", "outformat": "svg"}' YOUR_FUNCTION_TRIGGER_URL