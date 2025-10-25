#!/usr/bin/env bash
set -euo pipefail

# --- CONFIGURATION ---
IMAGE_NAME="go-hello"                  # Change this to your image name
REGISTRY="docker.io/allheil"         # Change to your registry (e.g., Docker Hub, GHCR, ECR)
CHART_PATH="./charts/$IMAGE_NAME"           # Path to Helm chart
RELEASE_NAME=$IMAGE_NAME                # Helm release name
NAMESPACE="default"                 # Kubernetes namespace

# --- STEP 1: Generate tag based on timestamp ---
TAG=$(date +"%Y%m%d%H%M%S")
FULL_IMAGE="${REGISTRY}/${IMAGE_NAME}:${TAG}"

echo "🕒 Generated tag: ${TAG}"
echo "📦 Full image: ${FULL_IMAGE}"

# --- STEP 2: Build Docker image ---
echo "🐳 Building and pushing multi-arch image..."
podman -r buildx build --platform linux/arm64,linux/amd64 -t "${FULL_IMAGE}" .

# --- STEP 3: Push Docker image ---
echo "🚀 Pushing Docker image..."
podman -r push "${FULL_IMAGE}"
echo "🚀 Image available remotely."

# --- STEP 3: Upgrade Helm release with new image tag ---
echo "🔧 Upgrading Helm release..."
helm upgrade "${RELEASE_NAME}" "${CHART_PATH}" \
  --namespace "${NAMESPACE}" \
  --set image.repository="${REGISTRY}/${IMAGE_NAME}" \
  --set image.tag="${TAG}" \
  --install

echo "✅ Deployment completed successfully!"
