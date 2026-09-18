# ianmontgomery.net

Source for my personal site, [ianmontgomery.net](https://ianmontgomery.net): a
1-bit digital business card at `/` and a full resume at `/resume/`.

## Stack

- **Framework**: [Zola](https://www.getzola.org/) (static site generator, Tera templates)
- **Styling**: Tailwind CSS (standalone CLI — no Node.js)
- **PDF / OG card**: Typst / resvg
- **Hosting**: Cloudflare Pages, deployed from GitHub Actions
- **Toolchain**: a single container image (`resume-builder`) built from the `Dockerfile`; no Node.js or `node_modules`

Resume content lives in `data/*.json` and is the single source of truth for the
web resume, the local PDF, and the local Markdown CV.

## Build

Requires Docker or Podman and `make`:

```bash
make site    # deployable site (CSS, HTML, OG card) into dist/
make dev     # live-reloading dev server at http://localhost:4321
make build   # site + local-only PDF and Markdown CV
make lint    # shell, JSON, YAML, and SAST checks
```

The PDF and Markdown CV are generated locally only and are never deployed. To
include a phone number in them, copy `.env.example` to `.env` and set
`RESUME_PHONE`.

## Structure

- `data/*.json` — resume content
- `content/` — page routes
- `templates/` — Tera templates
- `static/` — assets, headers, redirects
- `styles/input.css` — Tailwind source
- `Dockerfile` / `Makefile` — containerized build toolchain

Deploys run from `.github/workflows/deploy.yaml` on push to `main`.
