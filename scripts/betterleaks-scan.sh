#!/usr/bin/env bash
#
# betterleaks-scan.sh
# --------------------
# Runs Betterleaks (https://github.com/betterleaks/betterleaks) as a secret scanner
# entirely inside Podman — nothing is installed on the host.
#
# Supply-chain hardening (the "ultimate" part):
#   * The Betterleaks image is referenced by IMMUTABLE digest, never a mutable tag —
#     the digest itself guarantees you always run exactly that image (tamper-evident).
#   * Its Sigstore signature is verified (keyless: Fulcio short-lived cert + Rekor
#     transparency log) against the upstream GitHub Actions release-workflow identity
#     the FIRST time a given digest appears locally. The verifier (cosign) also runs
#     containerised and is itself pinned by digest, so no trust is placed in the host.
#   Re-verifying on every commit would be redundant (digests are immutable) and adds a
#   fragile network round-trip that can block pushes, so we only verify when the pinned
#   image is not already present in the local Podman store. Set BETTERLEAKS_FORCE_VERIFY=1
#   to force a re-check (e.g. after a digest rotation you want to re-attest).
#
# Usage:
#   scripts/betterleaks-scan.sh [betterleaks git flags...]
#   e.g.  scripts/betterleaks-scan.sh --pre-commit --staged     # pre-commit (staged diff)
#         scripts/betterleaks-scan.sh                           # full-history scan (pre-push)
#
set -euo pipefail

# --- Pinned, immutable digests -------------------------------------------------
# Rotate by: podman pull <image>:latest && podman images --digests <image>
BETTERLEAKS_REF="ghcr.io/betterleaks/betterleaks@sha256:7a43a20d40be02a9c13801a6485f7bea9d9cdba512263440eae972103c5291f1"
COSIGN_REF="ghcr.io/sigstore/cosign/cosign@sha256:d91bc4e7e95e8d2f549c747a72dc174f90579e410a1695f57f686674f84ce849"

# Detect container engine. Honor CONTAINER_ENGINE if set, otherwise prefer running engine.
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

# If this repository is a worktree, GIT common dir points to the actual git dir
GIT_COMMON_DIR="$(cd "$(git rev-parse --git-common-dir)" && pwd)"
MOUNT_ARGS=""
if [ "${GIT_COMMON_DIR}" != "${REPO_ROOT}/.git" ]; then
  # Mount the common git dir into the container so git inside the container can access refs
  if [ "$CONTAINER" = podman ]; then
    MOUNT_ARGS=" -v ${GIT_COMMON_DIR}:${GIT_COMMON_DIR}:z"
  else
    MOUNT_ARGS=" -v ${GIT_COMMON_DIR}:${GIT_COMMON_DIR}"
  fi
fi

# Helper: check if image exists locally
image_exists() {
  if [ "$CONTAINER" = podman ]; then
    podman image exists "$1" >/dev/null 2>&1
  else
    docker image inspect "$1" >/dev/null 2>&1
  fi
}

# 1) Verify the signature only when this digest isn't already trusted locally.
if [[ "${BETTERLEAKS_FORCE_VERIFY:-}" == "1" ]] || ! image_exists "$BETTERLEAKS_REF"; then
  echo "==> Betterleaks image not yet verified locally — pulling and attesting signature (one-time per digest)"
  if [ "$CONTAINER" = podman ]; then
    podman pull "$BETTERLEAKS_REF"
    podman run --rm "$COSIGN_REF" verify \
      --certificate-identity-regexp 'https://github.com/betterleaks/betterleaks/\.github/workflows/release\.yml@.*' \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com \
      "$BETTERLEAKS_REF"
  else
    docker pull "$BETTERLEAKS_REF"
    docker run --rm "$COSIGN_REF" verify \
      --certificate-identity-regexp 'https://github.com/betterleaks/betterleaks/\.github/workflows/release\.yml@.*' \
      --certificate-oidc-issuer https://token.actions.githubusercontent.com \
      "$BETTERLEAKS_REF"
  fi
fi

# 2) Run the scan. Any extra args (e.g. --pre-commit --staged) pass through to betterleaks.
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
