#!/usr/bin/env bash

set -e

IMAGE_NAME="${1:-}"
if [ -z "$IMAGE_NAME" ]; then
    echo "IMAGE_NAME is not set"
    exit 1
fi

IMAGE_VERSION="${2:-}"
if [ -z "$IMAGE_VERSION" ]; then
    echo "IMAGE_VERSION is not set"
    exit 2
fi

# Color codes for pretty output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===> Building Docker production image (target: prod) for ${IMAGE_NAME}...${NC}"

# Construct the build command with all tags
docker build ${DOCKER_BUILD_PARAMS:-} --target prod -t ${IMAGE_NAME}:${IMAGE_VERSION} .

# Run the docker build command
# "${BUILD_CMD}"

echo -e "${GREEN}===> Build completed successfully!${NC}"
