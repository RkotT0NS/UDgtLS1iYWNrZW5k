#!/usr/bin/env bash

set -e

source "scripts/project-detection.source"
source "scripts/color.source"

IMAGE_VERSION="${1:-}"
if [ -z "$IMAGE_VERSION" ]; then
    echo "IMAGE_VERSION is not set"
    exit 2
fi


TEST_PROJECT() {
    PROJECT_NAME="${1:-}"
    IMAGE_VERSION="${2:-}"

    echo -e "${BLUE}===> Building Docker test image (target: test) for ${PROJECT_NAME}...${NC}"
    docker build \
        ${DOCKER_BUILD_PARAMS:-} \
        --target test \
        -t \
        "${PROJECT_NAME}:${IMAGE_VERSION}" .

    echo -e "${BLUE}===> Running project tests inside Docker container...${NC}"
    CONTAINER_NAME="test-${PROJECT_NAME}"

    # Run tests; do not exit immediately on failure so we can extract reports
    set +e
    docker run \
        --rm  \
        --volume "$(pwd)/test-results:/app/test-results" \
        --name "${CONTAINER_NAME}" \
        "${PROJECT_NAME}:${IMAGE_VERSION}"

    TEST_EXIT_CODE=$?
    set -e

    # Exit with the test suite's exit code if they failed
    if [ $TEST_EXIT_CODE -ne 0 ]; then
        echo -e "\033[0;31m===> Tests failed with exit code ${TEST_EXIT_CODE}!\033[0m"
        exit $TEST_EXIT_CODE
    fi

    echo -e "${GREEN}===> Tests completed successfully!${NC}"
}


PROJECT_TYPE="$(CHECK_PROJECT)";
PROJECT_FOUND="$?";
if [ $PROJECT_FOUND -ne 0 ]; then
    exit $PROJECT_FOUND;
fi

if [[ "$PROJECT_TYPE" =~ (^|$'\n')GRADLE($|$'\n') ]]; then
    TEST_PROJECT "wd34-backend" "${IMAGE_VERSION}"
fi

if [[ "$PROJECT_TYPE" =~ (^|$'\n')NPM($|$'\n') ]]; then
    TEST_PROJECT "wd34-frontend" "${IMAGE_VERSION}"
fi
