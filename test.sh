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

echo -e "${BLUE}===> Building Docker test image (target: test)...${NC}"
docker build ${DOCKER_BUILD_PARAMS:-} --target test -t "${IMAGE_NAME}:${IMAGE_VERSION}" .

echo -e "${BLUE}===> Running project tests inside Docker container...${NC}"
CONTAINER_NAME="test-runner-${IMAGE_NAME}"

# Run tests; do not exit immediately on failure so we can extract reports
set +e
docker run --rm  --volume "$(pwd)/test-results:/app/test-results" --name "${CONTAINER_NAME}" "${IMAGE_NAME}:${IMAGE_VERSION}"
TEST_EXIT_CODE=$?
set -e

# Exit with the test suite's exit code if they failed
if [ $TEST_EXIT_CODE -ne 0 ]; then
    echo -e "\033[0;31m===> Tests failed with exit code ${TEST_EXIT_CODE}!\033[0m"
    exit $TEST_EXIT_CODE
fi

echo -e "${GREEN}===> Tests completed successfully!${NC}"
