#!/bin/bash
set -euo pipefail

# This script is called by the Justfile to handle image signing.
# It's moved to a separate script to avoid complex shell escaping issues within the Justfile.

# --- Dependency Check ---
for cmd in cosign skopeo sudo; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: Required command '$cmd' is not installed." >&2
        exit 1
    fi
done

# --- Arguments from Justfile ---
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <full_image_name> <architecture>" >&2
    exit 1
fi
FULL_IMAGE="$1"
ARCH="$2"

# --- Logic ---
echo "Signing ${FULL_IMAGE}:${ARCH}..."

# Determine the signing key argument
if [ -n "${COSIGN_PRIVATE_KEY-}" ]; then
    KEY_ARG="--key env://COSIGN_PRIVATE_KEY"
    echo "Using COSIGN_PRIVATE_KEY from environment."
elif [ -f "cosign.key" ]; then
    KEY_ARG="--key cosign.key"
    echo "Using local cosign.key file."
else
    echo "Error: COSIGN_PRIVATE_KEY environment variable is not set and cosign.key is missing." >&2
    exit 1
fi

# Fetch the exact remote digest directly from the registry to account for GHCR mutations
echo "Fetching remote digest from registry for ${FULL_IMAGE}:${ARCH}..."

# Use a temporary file for skopeo's stderr to provide better error messages
SKOPEO_ERROR_LOG=$(mktemp)
trap 'rm -f -- "$SKOPEO_ERROR_LOG"' EXIT

DIGEST=$(sudo skopeo inspect --format '{{.Digest}}' "docker://${FULL_IMAGE}:${ARCH}" 2> "$SKOPEO_ERROR_LOG")

if [ -z "$DIGEST" ]; then
    # If authenticated inspect fails, try unauthenticated to isolate the cause
    if skopeo inspect "docker://${FULL_IMAGE}:${ARCH}" &> /dev/null; then
        echo "Error: Authenticated inspect failed, but unauthenticated inspect succeeded." >&2
        echo "This confirms the issue is with the credentials in '/etc/containers/auth.json'. Please run 'sudo podman logout ghcr.io' and log back in with a PAT that has 'read:packages' scope." >&2
    else
        echo "Error: Both authenticated and unauthenticated inspects failed. This could be a network issue or the image tag may not exist." >&2
    fi
    echo -e "\nUnderlying error from skopeo:" >&2
    cat "$SKOPEO_ERROR_LOG" >&2; exit 1
fi

echo "Signing image with digest: $DIGEST"

cosign sign -y --new-bundle-format=false --use-signing-config=false $KEY_ARG "${FULL_IMAGE}:${ARCH}@${DIGEST}"