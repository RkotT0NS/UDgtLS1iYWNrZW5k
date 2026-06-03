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

TEST_PROJECT() {
    IMAGE_NAME="${1:-}"
    if [ -z "$IMAGE_NAME" ]; then
        echo "IMAGE_NAME is not set"
        exit 1
    fi

    # Color codes for pretty output
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    NC='\033[0m' # No Color

    echo -e "${BLUE}===> Building Docker test image (target: test)...${NC}"
    docker build ${DOCKER_BUILD_PARAMS:-} --target test -t "${IMAGE_NAME}" .

    echo -e "${BLUE}===> Running project tests inside Docker container...${NC}"
    CONTAINER_NAME="test-runner-${IMAGE_NAME}"

    # Run tests; do not exit immediately on failure so we can extract reports
    set +e
    docker run --rm  --volume "$(pwd)/test-results:/app/test-results" --name "${CONTAINER_NAME}" "${IMAGE_NAME}"
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

# cleanup test results
rm -rf test-results/*.xml

if [[ "$PROJECT_TYPE" =~ (^|$'\n')GRADLE($|$'\n') ]]; then
    TEST_PROJECT "p8-backend-test"
fi
if [[ "$PROJECT_TYPE" =~ (^|$'\n')NPM($|$'\n') ]]; then
    TEST_PROJECT "p8-frontend-test"
fi
