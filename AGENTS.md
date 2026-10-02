# AGENTS.md

Operational notes for agent sessions working in this repo. Read alongside
`README.md` (overview). This is a personal CV site (static HTML, plus a
local-only Markdown CV and PDF) with a fully containerized, Node-free toolchain
deployed to Cloudflare Pages.

## Verification

Run `make build` before considering any change done — it builds the
`cv-builder` image, then the full local build (site + PDF + Markdown CV) in
containers. For a site-only change, `make lint` + `make site` is enough until the
final `make build`.

## Build pipeline

The toolchain is **100% containerized and Node-free**: Hugo (site), Typst (PDF),
resvg (OG card), and the standalone Tailwind CSS CLI, all in the
`cv-builder` image from the root `Dockerfile` (digest-pinned base, every tool
download SHA-256 verified, built for `linux/amd64`).

Tailwind is v4 with CSS-first config in `assets/css/main.css` (no
`tailwind.config.js`). Hugo's built-in `css.TailwindCSS` is deliberately **not**
used — since Hugo v0.161.0 it requires a Node-installed CLI. Instead `make css`
compiles the stylesheet, and `layouts/_partials/fingerprinted.html` fingerprints
the CSS and JS (hashed URL + Subresource Integrity) in production, emitting plain
URLs in dev.

- `make site` — `css` → `hugo` (into `dist/`) → `og`.
- `make build` — `image` + `site` + `pdf` + `markdown`.
- `make pdf` / `make markdown` — local-only artifacts under `generated/`.
- `make private-data` — writes `CV_PHONE` from gitignored `.env` to
  `local/private.json` (empty in CI).
- `make dev` — Hugo live-reload server at `http://localhost:1313`, with the
  Tailwind CLI in watch mode.
- `make clean` / `make lint`.

**The PDF and Markdown CV are workstation-local only.** CI runs `make site`
(never `make build`). The Markdown CV source is `local/cv.md`, staged into
`content/cv-markdown.md` only during `make markdown`; `content/cv-markdown.md` is
gitignored and the `hugo` target refuses to build while it exists, so the
deployed site never includes it. (It is staged as `cv-markdown.md` because
`content/cv.md` is the web `/cv/` page.) Never wire `pdf`/`markdown` into CI.

### Lint & hooks

`make lint` = `lint-shell` (ShellCheck on `scripts/`), `lint-yaml` (yamllint on
`data/`, `.github/workflows/`, `lefthook.yml`), and `lint-semgrep` (Semgrep
`--config=auto --error`). `lint-secrets` (Betterleaks) is local-only. `lefthook`
runs these on `pre-commit` and `make lint` + `make build` on `pre-push`.

### Ignored artifacts

`dist/`, `generated/`, `assets/css/styles.css`, `content/cv-markdown.md`,
`local/private.json`, `.env*`, and the legacy `public/`. `AGENTS.md` is tracked.

## Content model

`data/*.yaml` is the single source of truth for every output. Dates are quoted
strings (e.g. `"2023-12-01"`) so Hugo and Typst parse them identically.

- `basics.yaml`, `jobs.yaml`, `education.yaml` — shared by
  `layouts/cv.html` (web, uses `bullets`), `layouts/home.html`
  (card, uses `basics`), `layouts/cv.md` (uses `bullets_pdf`), and
  `build/pdf/cv.typ` (uses `bullets_pdf`).
- `skills.yaml` — skill registry keyed by slug (names/urls/descriptions)
  plus ordered `categories` grouping slugs. Jobs/education reference skills by
  slug. The slug is the id; there is no separate `id` field.
- `achievements.yaml` — certifications (web + Markdown CV; not the PDF).

The phone number is **not** in `basics.yaml`: `make private-data` writes it to
gitignored `local/private.json`, read by `layouts/cv.md` and
`build/pdf/cv.typ` (guarded — omitted when unset). Never commit it.

`content/` holds `_index.md` (`/` card) and `cv.md` (`/cv/`). Templates
are Go templates in `layouts/` — `baseof.html`, `home.html`,
`cv.html`, `cv.md`, and partials (`skill-chip`,
`skill-names`, `term`, `fingerprinted`, `css`, `js`). Named layouts live at the
`layouts/` root (Hugo's post-v0.146 template system; no `_default/`). Internal
page links use Hugo's `relref` and static assets use `relURL`, so an unresolved
ref fails the build. After editing `data/*.yaml`, run `make lint-yaml` and
`make build`.

## Environment & containers

- Container engine is chosen at Makefile parse time: an explicit
  `CONTAINER_ENGINE` (command line or environment) wins, else the daemon that is
  actually reachable (Docker on CI runners, else Podman). Override with
  `make CONTAINER_ENGINE=podman …`.
- SELinux hosts need the `:z` bind-mount relabel; GitHub ubuntu runners don't, so
  CI runs as the host user.

## CI/CD

- `check.yaml` — pull requests: build image, `make lint`, `make site`.
- `deploy.yaml` — push to `main` (path-filtered): build image, `make site`, then
  deploy `dist/` to Cloudflare Pages via `cloudflare/wrangler-action`. Needs
  secrets `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` and the
  `CLOUDFLARE_PROJECT_NAME` repo variable (deploy skipped when unset; the Pages
  project's Git integration is disconnected so this Action is the only deployer).
- Dependabot updates `github-actions` and `docker` weekly. The `Dockerfile`'s
  `*_VERSION` ARGs are bumped manually alongside their `*_SHA256`.

## Deploy & Cloudflare Pages

Hosted at `https://ianmontgomery.net` (`hugo.toml` `baseURL`): `/` is the card,
`/cv/` the CV. Pages serves `dist/`. `static/_headers` (CSP + immutable
caching for hashed CSS/JS) and `static/_redirects` are copied in;
`layouts/404.html` is served on 404. `static/_redirects` 301s the old
`/resume/` paths to `/cv/`.

## Common workflows

- **Edit content** → `data/*.yaml`, then `make lint-yaml` and `make build`.
- **Bump a pinned tool** → update the `*_VERSION` and matching `*_SHA256` in the
  `Dockerfile`.
- **Clean** → `make clean`.
