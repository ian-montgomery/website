IMAGE_NAME ?= cv-builder

# Local-only secrets (gitignored). Provides CV_PHONE for the PDF and
# Markdown CV; empty in CI.
-include .env

# Prefer an explicit CONTAINER_ENGINE (command-line or environment); otherwise
# use an engine whose daemon is actually reachable — Docker on CI runners, else
# Podman on rootless workstations/VPS.
ifeq ($(origin CONTAINER_ENGINE),undefined)
  ifeq ($(shell command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1 && echo yes),yes)
    CONTAINER_ENGINE := docker
  else ifneq (,$(shell command -v podman 2>/dev/null))
    CONTAINER_ENGINE := podman
  else
    CONTAINER_ENGINE := docker
  endif
endif

ifeq ($(CONTAINER_ENGINE),podman)
CONTAINER_CMD ?= podman run --rm -v $(PWD):/workspace:z -w /workspace $(IMAGE_NAME)
DEV_CMD ?= podman run --rm -it --replace --name $(IMAGE_NAME)-dev -p 1313:1313 -v $(PWD):/workspace:z -w /workspace $(IMAGE_NAME)
IMAGE_BUILD_CMD = podman build --platform linux/amd64 -f Dockerfile -t $(IMAGE_NAME) .
else
CONTAINER_CMD ?= docker run --rm --user $(shell id -u):$(shell id -g) -v $(PWD):/workspace -w /workspace $(IMAGE_NAME)
DEV_CMD ?= docker run --rm -it -p 1313:1313 -v $(PWD):/workspace -w /workspace $(IMAGE_NAME)
IMAGE_BUILD_CMD = docker buildx build --platform linux/amd64 -f Dockerfile -t $(IMAGE_NAME) --load .
endif

.PHONY: help image dev build site css hugo pdf og markdown private-data clean lint lint-shell lint-yaml lint-semgrep lint-secrets

help:
	@echo "make image      build the $(IMAGE_NAME) container image"
	@echo "make dev        Hugo + Tailwind dev server at http://localhost:1313"
	@echo "make build      site + local-only PDF and Markdown CV"
	@echo "make site       deployable site (CSS, HTML, OG card); what CI builds"
	@echo "make pdf        compile the PDF CV (local only)"
	@echo "make markdown   generate the Markdown CV (local only)"
	@echo "make lint       shell + YAML + SAST checks (CI-safe)"
	@echo "make clean      remove build artifacts"

image:
	$(IMAGE_BUILD_CMD)

dev: image private-data
	$(DEV_CMD) \
		sh -c 'tailwindcss -i assets/css/main.css -o assets/css/styles.css --minify; \
		tailwindcss -i assets/css/main.css -o assets/css/styles.css --minify --watch --poll & \
		exec hugo server --bind 0.0.0.0 --port 1313 --baseURL http://localhost:1313/'

build: image site pdf markdown

site: css hugo og

# Writes the gitignored local data file the CV templates read.
private-data:
	@printf '{"phone":"%s"}\n' '$(CV_PHONE)' > local/private.json

# Tailwind CSS v4 (standalone CLI); Hugo fingerprints the output.
css:
	$(CONTAINER_CMD) tailwindcss -i assets/css/main.css -o assets/css/styles.css --minify

hugo: private-data
	@test ! -e content/cv-markdown.md || { echo "error: remove staged content/cv-markdown.md first" >&2; exit 1; }
	$(CONTAINER_CMD) hugo --destination dist --cleanDestinationDir

pdf: private-data
	mkdir -p generated/pdf
	$(CONTAINER_CMD) typst compile --root . assets/pdf/cv.typ generated/pdf/ian-montgomery-cv.pdf

og:
	mkdir -p dist/generated/og
	$(CONTAINER_CMD) resvg assets/og/card.svg dist/generated/og/index.png -w 1200 -h 630

# The Markdown CV source (local/cv.md) is staged into content/ only for this
# build, so `make site` can never include it. It is staged as cv-markdown.md
# because content/cv.md is the web /cv/ page.
markdown: private-data
	@mkdir -p generated/markdown
	@cp local/cv.md content/cv-markdown.md; \
	trap 'rm -f content/cv-markdown.md' EXIT INT TERM; \
	$(CONTAINER_CMD) hugo --destination generated/markdown-src --cleanDestinationDir --quiet; \
	mv generated/markdown-src/cv-markdown/ian-montgomery-cv.md generated/markdown/ian-montgomery-cv.md; \
	rm -rf generated/markdown-src

clean:
	rm -rf dist generated public assets/css/styles.css content/cv-markdown.md resources .hugo_build.lock

lint: lint-shell lint-yaml lint-semgrep

lint-shell:
	$(CONTAINER_CMD) shellcheck scripts/*.sh

lint-yaml:
	$(CONTAINER_CMD) yamllint .github/workflows/ lefthook.yml data/

lint-semgrep:
	$(CONTAINER_ENGINE) run --rm -v $(PWD):/src:z -w /src semgrep/semgrep:1.151.0 semgrep scan --config=auto --error

lint-secrets:
	CONTAINER_ENGINE=$(CONTAINER_ENGINE) ./scripts/betterleaks-scan.sh $(BETTERLEAKS_FLAGS)
