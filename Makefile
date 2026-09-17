IMAGE_NAME ?= resume-builder

# Detect available container engine at makefile parse time. Prefer Docker on
# GitHub-hosted runners, fall back to Podman on the VPS/workstation where
# rootless Podman is the default. CONTAINER_ENGINE is set to either 'docker'
# or 'podman' accordingly.
ifeq (,$(shell command -v docker 2>/dev/null))
CONTAINER_ENGINE := podman
else
CONTAINER_ENGINE := docker
endif

ifeq ($(CONTAINER_ENGINE),podman)
CONTAINER_CMD ?= podman run --rm -v $(PWD):/workspace:z -w /workspace $(IMAGE_NAME)
IMAGE_BUILD_CMD = podman build --platform linux/amd64 -f Dockerfile -t $(IMAGE_NAME) .
else
# Docker on GitHub runners lacks the :z relabel option; use a plain mount.
CONTAINER_CMD ?= docker run --rm --user $(shell id -u):$(shell id -g) -v $(PWD):/workspace -w /workspace $(IMAGE_NAME)
# Use buildx with --load so the built image is available to the local docker daemon
# for subsequent `docker run` steps in CI.
IMAGE_BUILD_CMD = docker buildx build --platform linux/amd64 -f Dockerfile -t $(IMAGE_NAME) --load .
endif


# CI runs inside the resume-builder image itself, so it calls `make site CONTAINER_CMD=`
# to execute the tools directly (no nested podman). The PDF is intentionally excluded
# from `site` — it is a workstation-local artifact and must never be built in CI/CD
# or uploaded to Cloudflare Pages.
.PHONY: help image dev build site css zola pdf og markdown clean lint lint-shell lint-json lint-yaml lint-semgrep lint-secrets

help:
	@echo "Available Makefile targets:"
	@echo "  make image    - Build the local $(IMAGE_NAME) Podman container image"
	@echo "  make dev      - Start Zola live-reloading dev server in Podman (http://localhost:4321)"
	@echo "  make build    - Full local build: site + PDF, via Podman containers"
	@echo "  make site     - Site only (CSS, HTML, OG, Markdown CV) — what CI/CD builds; no PDF"
	@echo "  make css      - Compile Tailwind CSS inside Podman container"
	@echo "  make zola     - Build static site inside Podman container"
	@echo "  make pdf      - Compile PDF resume inside Podman container (local only)"
	@echo "  make og       - Render OpenGraph PNG card inside Podman container"
	@echo "  make markdown - Flatten Markdown CV output into a .md file"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make lint     - Run all CI-safe linters (shell, json, yaml, semgrep)"
	@echo "  make lint-shell - ShellCheck on scripts/"
	@echo "  make lint-json  - Validate JSON in data/"
	@echo "  make lint-yaml  - Lint YAML in .github/workflows/ and lefthook.yml"
	@echo "  make lint-semgrep - Semgrep SAST on tracked source files"
	@echo "  make lint-secrets - Betterleaks secret scan (local only, not CI)"

image:
	# x86_64-only tool binaries — build for amd64 (native on the VPS, Rosetta on Apple Silicon)
	$(IMAGE_BUILD_CMD)

dev: image
	podman run --rm -it -p 4321:4321 -p 4322:4322 -v $(PWD):/workspace:z -w /workspace $(IMAGE_NAME) zola serve --interface 0.0.0.0 --port 4321 --base-url http://localhost

build: image site pdf

site: css zola og markdown

css:
	$(CONTAINER_CMD) tailwindcss -i styles/input.css -o static/styles.css --minify

zola:
	$(CONTAINER_CMD) zola build -o dist --force

pdf:
	mkdir -p dist/generated/pdf
	$(CONTAINER_CMD) typst compile --root . templates/pdf/resume.typ dist/generated/pdf/ian-montgomery-cv.pdf

og:
	mkdir -p dist/generated/og
	$(CONTAINER_CMD) resvg templates/og/card.svg dist/generated/og/index.png -w 1200 -h 630

# Zola always renders a page as <path>/index.html, so flatten the rendered
# Markdown CV into a real .md file served at /generated/markdown/ian-montgomery-cv.md
markdown:
	@if [ -f dist/generated/markdown/ian-montgomery-cv.md/index.html ]; then \
		mv dist/generated/markdown/ian-montgomery-cv.md/index.html dist/generated/markdown/.cv.md.tmp; \
		rm -rf dist/generated/markdown/ian-montgomery-cv.md; \
		mv dist/generated/markdown/.cv.md.tmp dist/generated/markdown/ian-montgomery-cv.md; \
	else \
		echo "error: Markdown CV page missing — run 'make zola' first" >&2; exit 1; \
	fi

clean:
	rm -rf dist static/styles.css

# --- Lint targets (run inside the container, except semgrep which uses its own image) ---

lint: lint-shell lint-json lint-yaml lint-semgrep

lint-shell:
	$(CONTAINER_CMD) shellcheck scripts/*.sh

lint-json:
	$(CONTAINER_CMD) jq empty data/*.json

lint-yaml:
	$(CONTAINER_CMD) yamllint .github/workflows/ lefthook.yml

lint-semgrep:
	$(CONTAINER_ENGINE) run --rm -v $(PWD):/src:z -w /src semgrep/semgrep:1.151.0 semgrep scan --config=auto --error

lint-secrets:
	CONTAINER_ENGINE=$(CONTAINER_ENGINE) ./scripts/betterleaks-scan.sh $(BETTERLEAKS_FLAGS)
