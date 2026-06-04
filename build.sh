#!/usr/bin/env bash

set -e

source "scripts/project-detection.source"
source "scripts/color.source"

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

BUILD_PROJECT() {
    PROJECT_NAME="${1:-}"
    IMAGE_NAME="${2:-}"
    IMAGE_VERSION="${3:-}"
    echo -e "${BLUE}===> Building Docker production image (target: prod) for ${PROJECT_NAME}...${NC}"

    # Construct the build command with all tags
    docker build \
        ${DOCKER_BUILD_PARAMS:-} \
        --target prod \
        -t \
        "${IMAGE_NAME}:${IMAGE_VERSION}" .

    # Run the docker build command
    # "${BUILD_CMD}"

    echo -e "${GREEN}===> Build completed successfully!${NC}"
}

PROJECT_TYPE="$(CHECK_PROJECT)";
PROJECT_FOUND="$?";
if [ $PROJECT_FOUND -ne 0 ]; then
    exit $PROJECT_FOUND;
fi

if [[ "$PROJECT_TYPE" =~ (^|$'\n')GRADLE($|$'\n') ]]; then
    BUILD_PROJECT "wd34-backend" "${IMAGE_NAME}" "${IMAGE_VERSION}"
fi

if [[ "$PROJECT_TYPE" =~ (^|$'\n')NPM($|$'\n') ]]; then
    BUILD_PROJECT "wd34-frontend" "${IMAGE_NAME}" "${IMAGE_VERSION}"
fi
