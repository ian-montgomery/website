# syntax=docker/dockerfile:1
#
# resume-builder — Node-free toolchain image: Zola + Typst + resvg + standalone Tailwind CLI.
# Base image is pinned by immutable manifest-list digest; tool versions are pinned by
# ARG and every download is verified against a hardcoded SHA-256 checksum.
#
# When bumping a *_VERSION, update the matching *_SHA256 (compute with:
#   curl -sL <url> | shasum -a 256
# ) — Renovate opens the version PR, the checksum update is a documented manual step.

FROM debian:bookworm-slim@sha256:88200866dfff7ea7f5cbcb6ec7c8a701889efe6fe859fe64d6990e4b07ea4171

# NOTE: binaries below are linux/x86_64. The Makefile builds with
# --platform linux/amd64; on Apple Silicon this runs via Podman's Rosetta
# translation, on the amd64 VPS it runs natively.

ARG ZOLA_VERSION=0.19.2
ARG ZOLA_SHA256=0798e69b86c628ddcb264ebd86c8cc8dce7670b9049060bf94faa73f6857cd9c
ARG TYPST_VERSION=0.11.1
ARG TYPST_SHA256=bb637d1d65634b2ee4b4e101d0b2d541bf3f1e03ac5f51f9619941e48dd28bd0
ARG RESVG_VERSION=0.44.0
ARG RESVG_SHA256=450cfeaf8122f7389a8acf698888804e1ed46980b611d5253204049c51c87087
ARG TAILWIND_VERSION=3.4.17
ARG TAILWIND_SHA256=7d24f7fa191d2193b78cd5f5a42a6093e14409521908529f42d80b11fde1f1d4

# Install system dependencies & standard fonts for resvg / Typst rendering
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    make \
    shellcheck \
    tar \
    xz-utils \
    yamllint \
    fonts-dejavu-core \
    fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

# Install Zola (checksum-verified)
RUN curl -fsSL -o /tmp/zola.tar.gz "https://github.com/getzola/zola/releases/download/v${ZOLA_VERSION}/zola-v${ZOLA_VERSION}-x86_64-unknown-linux-gnu.tar.gz" \
    && echo "${ZOLA_SHA256}  /tmp/zola.tar.gz" | sha256sum -c - \
    && tar -xz -C /usr/local/bin -f /tmp/zola.tar.gz \
    && rm /tmp/zola.tar.gz

# Install Typst (checksum-verified; extract only the binary)
RUN curl -fsSL -o /tmp/typst.tar.xz "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz" \
    && echo "${TYPST_SHA256}  /tmp/typst.tar.xz" | sha256sum -c - \
    && tar -xJ --strip-components=1 -C /usr/local/bin -f /tmp/typst.tar.xz typst-x86_64-unknown-linux-musl/typst \
    && rm /tmp/typst.tar.xz

# Install resvg (checksum-verified)
RUN curl -fsSL -o /tmp/resvg.tar.gz "https://github.com/RazrFalcon/resvg/releases/download/v${RESVG_VERSION}/resvg-linux-x86_64.tar.gz" \
    && echo "${RESVG_SHA256}  /tmp/resvg.tar.gz" | sha256sum -c - \
    && tar -xz -C /usr/local/bin -f /tmp/resvg.tar.gz \
    && rm /tmp/resvg.tar.gz

# Install standalone Tailwind CSS CLI (checksum-verified; zero Node.js dependency)
RUN curl -fsSL -o /usr/local/bin/tailwindcss "https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWIND_VERSION}/tailwindcss-linux-x64" \
    && echo "${TAILWIND_SHA256}  /usr/local/bin/tailwindcss" | sha256sum -c - \
    && chmod +x /usr/local/bin/tailwindcss

WORKDIR /workspace

# 4321 = zola serve HTTP, 4322 = zola serve live-reload websocket (serve port + 1)
EXPOSE 4321 4322

CMD ["zola", "serve", "--interface", "0.0.0.0", "--port", "4321"]
