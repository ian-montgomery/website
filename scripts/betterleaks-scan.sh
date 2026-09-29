#!/usr/bin/env bash
#
# Runs Betterleaks (secret scanner) in a container. The image is pinned by
# immutable digest and its Sigstore signature is verified (keyless) the first
# time a digest appears locally. Set BETTERLEAKS_FORCE_VERIFY=1 to re-verify.
#
# Usage: scripts/betterleaks-scan.sh [betterleaks git flags...]
set -euo pipefail

# Rotate by: podman pull <image>:latest && podman images --digests <image>
BETTERLEAKS_REF="ghcr.io/betterleaks/betterleaks@sha256:7a43a20d40be02a9c13801a6485f7bea9d9cdba512263440eae972103c5291f1"
COSIGN_REF="ghcr.io/sigstore/cosign/cosign@sha256:d91bc4e7e95e8d2f549c747a72dc174f90579e410a1695f57f686674f84ce849"

if [ -n "${CONTAINER_ENGINE:-}" ]; then
  CONTAINER="${CONTAINER_ENGINE}"
elif command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  CONTAINER=docker
elif command -v podman >/dev/null 2>&1; then
  CONTAINER=podman
elif command -v docker >/dev/null 2>&1; then
  CONTAINER=docker
else
  echo "ERROR: neither podman nor docker found; please install one to run betterleaks"
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"

# In a worktree, mount the common git dir so git works inside the container.
GIT_COMMON_DIR="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
MOUNT_ARGS=""
if [ "${GIT_COMMON_DIR}" != "${REPO_ROOT}/.git" ]; then
  if [ "$CONTAINER" = podman ]; then
    MOUNT_ARGS=" -v ${GIT_COMMON_DIR}:${GIT_COMMON_DIR}:z"
  else
    MOUNT_ARGS=" -v ${GIT_COMMON_DIR}:${GIT_COMMON_DIR}"
  fi
fi

image_exists() {
  if [ "$CONTAINER" = podman ]; then
    podman image exists "$1" >/dev/null 2>&1
  else
    docker image inspect "$1" >/dev/null 2>&1
  fi
}

if [[ "${BETTERLEAKS_FORCE_VERIFY:-}" == "1" ]] || ! image_exists "$BETTERLEAKS_REF"; then
  echo "==> Betterleaks image not yet verified locally — pulling and attesting signature (one-time per digest)"
  "$CONTAINER" pull "$BETTERLEAKS_REF"
  "$CONTAINER" run --rm "$COSIGN_REF" verify \
    --certificate-identity-regexp 'https://github.com/betterleaks/betterleaks/\.github/workflows/release\.yml@.*' \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    "$BETTERLEAKS_REF"
fi

# Any extra args (e.g. --pre-commit --staged) pass through to betterleaks.
if [ "$CONTAINER" = podman ]; then
  # shellcheck disable=SC2086  # intentional word-splitting for mount args
  exec podman run --rm ${MOUNT_ARGS} \
    -v "${REPO_ROOT}:/src:z" \
    -w /src \
    "$BETTERLEAKS_REF" \
    --config .betterleaks.toml \
    git --redact --verbose "$@" /src
else
  # shellcheck disable=SC2086
  exec docker run --rm ${MOUNT_ARGS} \
    -e GIT_CONFIG_COUNT=1 \
    -e GIT_CONFIG_KEY_0=safe.directory \
    -e GIT_CONFIG_VALUE_0=/src \
    -v "${REPO_ROOT}:/src" \
    -w /src \
    "$BETTERLEAKS_REF" \
    --config .betterleaks.toml \
    git --redact --verbose "$@" /src
fi
