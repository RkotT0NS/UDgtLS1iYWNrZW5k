#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
# set -e

CHECK_PROJECT() {
    MAVEN_PROJECT=false;
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

    if [ -f "pom.xml" ]; then
        MAVEN_PROJECT=true
        echo "MAVEN";
    fi

    echo $GRADLE_PROJECT
    echo $NPM_PROJECT
    echo $MAVEN_PROJECT

    if [[ ! ( $GRADLE_PROJECT == "true"  || $NPM_PROJECT == "true"  ||  $MAVEN_PROJECT == "true" ) ]]; then
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
    START_TIME=$(date +%s%6N)
    echo -e "${BLUE}===> Building Docker test image (target: test)...${NC}"
    docker build --target test -t "${IMAGE_NAME}" .

    echo -e "${BLUE}===> Running project tests inside Docker container...${NC}"
    docker run --rm --volume "$(pwd)/test-results:/app/test-results" "${IMAGE_NAME}"

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
