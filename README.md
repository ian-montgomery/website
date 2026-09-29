# ianmontgomery.net

Source for my personal site, [ianmontgomery.net](https://ianmontgomery.net)

## Stack

- **Framework**: [Hugo](https://gohugo.io/) (static site generator, Go templates)
- **Styling**: Tailwind CSS v4, standalone CLI with CSS-first config — no Node.js
- **PDF / OG card**: Typst / resvg
- **Hosting**: Cloudflare Pages, deployed from GitHub Actions
- **Toolchain**: a single container image (`resume-builder`) built from the `Dockerfile`; no Node.js or `node_modules`

Resume content lives in `data/*.yaml` and is the single source of truth for the
web resume, the local PDF, and the local Markdown CV.

## Build

Requires Docker or Podman and `make`:

```bash
make site    # deployable site (CSS, HTML, OG card) into dist/
make dev     # live-reloading dev server at http://localhost:1313 (Hugo + Tailwind watch)
make build   # site + local-only PDF and Markdown CV
make lint    # shell, YAML, and SAST checks
```

The PDF and Markdown CV are generated locally only and are never deployed. To
include a phone number in them, copy `.env.example` to `.env` and set
`RESUME_PHONE`.

## Structure

- `data/*.yaml` — resume content (Hugo data files, shared with the PDF/Markdown CV)
- `content/` — page routes (`/` card and `/resume/`)
- `layouts/` — Hugo templates (base template, home/resume layouts, partials, output formats)
- `assets/` — build inputs: `assets/css/main.css` (Tailwind v4 source), `assets/js/app.js`, `assets/og/card.svg`, `assets/pdf/resume.typ`
- `static/` — assets, headers, redirects
- `Dockerfile` / `Makefile` — containerized build toolchain

`make css` compiles `assets/css/main.css` to `assets/css/styles.css`, which Hugo
fingerprints (cache-busted URL + Subresource Integrity) via
`layouts/_partials/css.html`; `assets/js/app.js` is fingerprinted the same way.
`static/_headers` sets the CSP and long-lived caching for the hashed CSS/JS and
the fonts.

Deploys run from `.github/workflows/deploy.yaml` on push to `main`.
