#!/usr/bin/env bash

set -e

CHECK_PROJECT() {
    GRADLE_PROJECT=false
    NPM_PROJECT=false

    if [ -f "settings.gradle" ]; then
        GRADLE_PROJECT=true
        echo "GRADLE";
    fi

    if [ -f "package.json" ]; then
        NPM_PROJECT=true
        echo "NPM";
    fi

    if [[ ! ( $GRADLE_PROJECT == "true"  || $NPM_PROJECT == "true") ]]; then
        echo "Neither Gradle, NPM, nor Maven project found";
        exit 1;
    fi
}

BUILD_PROJECT() {
    IMAGE_NAME="${1:-}"
    if [ -z "$IMAGE_NAME" ]; then
        echo "IMAGE_NAME is not set"
        exit 1
    fi

    # Shift the first argument to get any additional tags
    shift
    ADDITIONAL_TAGS=("$@")

    # Color codes for pretty output
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    echo -e "${BLUE}===> Building Docker production image (target: prod) for ${IMAGE_NAME}...${NC}"

    # Construct the build command with all tags
    BUILD_CMD=("docker" "build" "--target" "prod" "-t" "${IMAGE_NAME}" ".")
    for TAG in "${ADDITIONAL_TAGS[@]}"; do
        BUILD_CMD+=("-t" "${TAG}")
    done

    # Run the docker build command
    "${BUILD_CMD[@]}"

    echo -e "${GREEN}===> Build completed successfully!${NC}"
}

PROJECT_TYPE="$(CHECK_PROJECT)";
PROJECT_FOUND="$?";
if [ $PROJECT_FOUND -ne 0 ]; then
    exit $PROJECT_FOUND;
fi

# The script accepts tags passed as arguments
# e.g., ./build.sh tag1 tag2 ...
# If no arguments are passed, it will use default names
if [[ "$PROJECT_TYPE" =~ (^|$'\n')GRADLE($|$'\n') ]]; then
    echo "Gradle project detected"
    if [ $# -gt 0 ]; then
        BUILD_PROJECT "$@"
    else
        BUILD_PROJECT "p8-backend"
    fi
fi

if [[ "$PROJECT_TYPE" =~ (^|$'\n')NPM($|$'\n') ]]; then
    if [ $# -gt 0 ]; then
        BUILD_PROJECT "$@"
    else
        BUILD_PROJECT "p8-frontend"
    fi
fi
