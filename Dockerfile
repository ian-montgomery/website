# syntax=docker/dockerfile:1
#
# resume-builder: Hugo + Typst + resvg + standalone Tailwind CLI (no Node.js).
# Versions are pinned by ARG; every download is verified against a hardcoded
# SHA-256. Bump a *_VERSION and its *_SHA256 together.

FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS tools

ARG HUGO_VERSION=0.167.0
ARG HUGO_SHA256=4d84519b9f619e6d4c3fb45a50157abeabeb724f859c60605f44c23def6e1169
ARG TYPST_VERSION=0.11.1
ARG TYPST_SHA256=bb637d1d65634b2ee4b4e101d0b2d541bf3f1e03ac5f51f9619941e48dd28bd0
ARG RESVG_VERSION=0.44.0
ARG RESVG_SHA256=450cfeaf8122f7389a8acf698888804e1ed46980b611d5253204049c51c87087
ARG TAILWIND_VERSION=4.3.3
ARG TAILWIND_SHA256=dc61b3ac6b8c9ca874c0cc4c57b2409791a64c5540404ca5f5367360babc313a

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl tar xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/hugo.tar.gz "https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_${HUGO_VERSION}_linux-amd64.tar.gz" \
    && echo "${HUGO_SHA256}  /tmp/hugo.tar.gz" | sha256sum -c - \
    && tar -xz -C /usr/local/bin -f /tmp/hugo.tar.gz hugo

RUN curl -fsSL -o /tmp/typst.tar.xz "https://github.com/typst/typst/releases/download/v${TYPST_VERSION}/typst-x86_64-unknown-linux-musl.tar.xz" \
    && echo "${TYPST_SHA256}  /tmp/typst.tar.xz" | sha256sum -c - \
    && tar -xJ --strip-components=1 -C /usr/local/bin -f /tmp/typst.tar.xz typst-x86_64-unknown-linux-musl/typst

RUN curl -fsSL -o /tmp/resvg.tar.gz "https://github.com/RazrFalcon/resvg/releases/download/v${RESVG_VERSION}/resvg-linux-x86_64.tar.gz" \
    && echo "${RESVG_SHA256}  /tmp/resvg.tar.gz" | sha256sum -c - \
    && tar -xz -C /usr/local/bin -f /tmp/resvg.tar.gz

RUN curl -fsSL -o /usr/local/bin/tailwindcss "https://github.com/tailwindlabs/tailwindcss/releases/download/v${TAILWIND_VERSION}/tailwindcss-linux-x64" \
    && echo "${TAILWIND_SHA256}  /usr/local/bin/tailwindcss" | sha256sum -c - \
    && chmod +x /usr/local/bin/tailwindcss

# Runtime: just the tools plus the fonts Typst/resvg need and the linters.
FROM debian:trixie-slim@sha256:a99cfc517144bc59b1978475ec53b46ecabec7e43635402ee5b77cc54cd1b20a AS runtime

RUN apt-get update && apt-get install -y --no-install-recommends \
      shellcheck \
      yamllint \
      fonts-dejavu-core \
      fonts-liberation \
    && rm -rf /var/lib/apt/lists/*

COPY --from=tools \
    /usr/local/bin/hugo \
    /usr/local/bin/typst \
    /usr/local/bin/resvg \
    /usr/local/bin/tailwindcss \
    /usr/local/bin/

WORKDIR /workspace

# 1313 = hugo server HTTP + live-reload websocket
EXPOSE 1313

CMD ["hugo", "server", "--bind", "0.0.0.0", "--port", "1313"]
