IMAGE_NAME ?= resume-builder

# Local-only secrets (gitignored). Provides RESUME_PHONE for the local PDF and
# Markdown CV; absent in CI, where the value is simply empty.
-include .env

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
# to execute the tools directly (no nested podman). The PDF and the Markdown CV are
# intentionally excluded from `site` — both are workstation-local artifacts and must
# never be built in CI/CD or uploaded to Cloudflare Pages.
.PHONY: help image dev build site css zola pdf og markdown private-data clean lint lint-shell lint-yaml lint-semgrep lint-secrets

help:
	@echo "Available Makefile targets:"
	@echo "  make image    - Build the local $(IMAGE_NAME) Podman container image"
	@echo "  make dev      - Start Zola live-reloading dev server in Podman (http://localhost:4321)"
	@echo "  make build    - Full local build: site + PDF + Markdown CV, via Podman containers"
	@echo "  make site     - Site only (CSS, HTML, OG) — what CI/CD builds; no PDF/Markdown CV"
	@echo "  make css      - Compile Tailwind CSS inside Podman container"
	@echo "  make zola     - Build static site inside Podman container"
	@echo "  make pdf      - Compile PDF resume inside Podman container (local only)"
	@echo "  make og       - Render OpenGraph PNG card inside Podman container"
	@echo "  make markdown - Generate Markdown CV locally into generated/ (not deployed)"
	@echo "  make private-data - Write local/private.json from RESUME_PHONE in .env"
	@echo "  make clean    - Remove build artifacts"
	@echo "  make lint     - Run all CI-safe linters (shell, yaml, semgrep)"
	@echo "  make lint-shell - ShellCheck on scripts/"
	@echo "  make lint-yaml  - Lint YAML in data/, .github/workflows/ and lefthook.yml"
	@echo "  make lint-semgrep - Semgrep SAST on tracked source files"
	@echo "  make lint-secrets - Betterleaks secret scan (local only, not CI)"

image:
	# x86_64-only tool binaries — build for amd64 (native on the VPS, Rosetta on Apple Silicon)
	$(IMAGE_BUILD_CMD)

dev: image private-data
	podman run --rm -it -p 4321:4321 -p 4322:4322 -v $(PWD):/workspace:z -w /workspace $(IMAGE_NAME) zola serve --interface 0.0.0.0 --port 4321 --base-url http://localhost

build: image site pdf markdown

site: css zola og

# Write the gitignored local data file consumed by the CV templates. It is empty
# when RESUME_PHONE is unset (e.g. in CI), so no secret is ever required to build.
private-data:
	@printf '{"phone":"%s"}\n' '$(RESUME_PHONE)' > local/private.json

css:
	$(CONTAINER_CMD) tailwindcss -i styles/input.css -o static/styles.css --minify

zola: private-data
	@if [ -e content/cv.md ]; then \
		echo "error: content/cv.md is a local-only staged file; remove it before building the site" >&2; \
		exit 1; \
	fi
	$(CONTAINER_CMD) zola build -o dist --force

pdf: private-data
	mkdir -p generated/pdf
	$(CONTAINER_CMD) typst compile --root . templates/pdf/resume.typ generated/pdf/ian-montgomery-cv.pdf

og:
	mkdir -p dist/generated/og
	$(CONTAINER_CMD) resvg templates/og/card.svg dist/generated/og/index.png -w 1200 -h 630

# Local-only Markdown CV. The page source lives at local/cv.md and is staged into
# content/cv.md only for this build, so `make site` (what CI/CD builds) can never
# include the route. Zola renders a page as <path>/index.html, so flatten it into
# a real .md file under the gitignored generated/ directory.
markdown: private-data
	@mkdir -p generated/markdown
	@cp local/cv.md content/cv.md; \
	trap 'rm -f content/cv.md' EXIT INT TERM; \
	$(CONTAINER_CMD) zola --root . --config local/cv-config.toml build --force; \
	if [ -f generated/markdown-src/ian-montgomery-cv.md/index.html ]; then \
		mv generated/markdown-src/ian-montgomery-cv.md/index.html generated/markdown/ian-montgomery-cv.md; \
	else \
		echo "error: Markdown CV page missing" >&2; \
		exit 1; \
	fi; \
	rm -rf generated/markdown-src

clean:
	rm -rf dist generated static/styles.css content/cv.md

# --- Lint targets (run inside the container, except semgrep which uses its own image) ---

lint: lint-shell lint-yaml lint-semgrep

lint-shell:
	$(CONTAINER_CMD) shellcheck scripts/*.sh

lint-yaml:
	$(CONTAINER_CMD) yamllint .github/workflows/ lefthook.yml data/

lint-semgrep:
	$(CONTAINER_ENGINE) run --rm -v $(PWD):/src:z -w /src semgrep/semgrep:1.151.0 semgrep scan --config=auto --error

lint-secrets:
	CONTAINER_ENGINE=$(CONTAINER_ENGINE) ./scripts/betterleaks-scan.sh $(BETTERLEAKS_FLAGS)
