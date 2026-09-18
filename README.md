# Ian Montgomery — Infrastructure Engineer

My personal site at [ianmontgomery.net](https://ianmontgomery.net), hosted on
Cloudflare Pages. It combines two routes in one Zola build:

- `/` — a 1-bit digital business card.
- `/resume` — the full resume.
- `/generated/markdown/ian-montgomery-cv.md` — the Markdown CV.

## About Me

Infrastructure Engineer at Xero, working across CI/CD automation, AWS, Kubernetes, and observability. Started in web development, then spent six years managing a multi-million dollar retail operation before returning to engineering. That operational experience shapes how I approach reliability and cross-team communication.

## Tech Stack

- **Framework**: Zola (static site generator, Tera templates)
- **Styling**: TailwindCSS (standalone CLI — no Node.js)
- **PDF**: Typst; **OG card**: resvg
- **Toolchain**: 100% containerized in a single `resume-builder` container image (`Dockerfile`) — Zola, Typst, resvg, and the Tailwind standalone CLI. No Node.js, no `node_modules`.
- **Hosting**: Cloudflare Pages (free tier)
- **DNS / CDN**: Cloudflare
- **CI/CD**: GitHub Actions — builds the site in the `resume-builder` container, then deploys `dist/` to Cloudflare Pages via Wrangler
- **Deps**: Dependabot (`.github/dependabot.yml`) for GitHub Actions and Docker base image updates

Resume data lives in `data/*.json` (single source of truth) and is consumed by the
website (`templates/resume.html` and `templates/card.html`), the Markdown CV
(`templates/cv.md`), and the PDF (`templates/pdf/resume.typ`) alike.

### Routes & structure

- `content/_index.md` (`template = "card.html"`) → `/` — the digital business card.
- `content/resume.md` (`template = "resume.html"`) → `/resume/` — the resume.
- `content/cv.md` (`template = "cv.md"`) → `/generated/markdown/ian-montgomery-cv.md`.
- The PDF is a local-only artifact and is never deployed.

This repo is the source of truth for ianmontgomery.net; the standalone
`ianmontgomery.net` repo is retired. `deploy.yaml` publishes `dist/` to the
Cloudflare Pages project named by the `CLOUDFLARE_PROJECT_NAME` repository
variable (set it to the existing ianmontgomery.net project).

## Development

All builds run inside the `resume-builder` container — the only host
requirement is Docker or Podman and `make`.

```bash
# Build the toolchain image (also runs automatically as part of dev/build)
make image

# Start the live-reloading dev server at http://localhost:4321
make dev

# Build the deployable site (CSS, HTML, OG card, Markdown CV) into dist/
make site

# Full local build — everything in `site` PLUS the PDF resume.
# The PDF is generated locally only: it is never built in CI/CD and never
# published to Cloudflare Pages.
make build
```

See [`.github/workflows/deploy.yaml`](.github/workflows/deploy.yaml) for the deployment pipeline.

## 1-bit redesign

The site is restyled as a 1-bit / early-Macintosh design: strictly pure black
(`#000`) and pure white (`#fff`), monospace type only, hard 2–4px borders, no
border-radius, shadows, gradients, colors, grays, or animated transitions.
The section order is unchanged: HEADER/BIO → SKILLS → WORK → EDUCATION.

### Files changed

- `templates/base.html` — IBM Plex Mono via Google Fonts (Courier New fallback),
  skip link, per-route `title`/`description`/OG blocks, light/dark `theme-color`,
  removed the theme toggle and the iconify runtime.
- `templates/card.html` — the `/` digital business card: centred 34rem column,
  128px dithered portrait, uppercase name, blinking terminal cursor role line,
  dither divider, and a bordered contact box (email, resume, GitHub, LinkedIn).
  On viewports at least 700px wide and 640px tall it is locked to the viewport
  height with no page scroll, matching the original standalone card.
- `templates/resume.html` — the `/resume` page: header/bio with blinking terminal
  cursor, skills grid, and Mac-window blocks for work and education (black title
  bar, dates right-aligned, logo, duties, caps skills separated by `/`).
- `templates/macros.html` — square bordered skill chips (info popover preserved).
- `templates/og/card.svg` — 1-bit OpenGraph card.
- `styles/input.css` — 1-bit component layer, `steps()` blink cursor, CSS-only
  dither dividers, focus-visible rules, print stylesheet.
- `tailwind.config.js` — black/white palette only, monospace family, zero
  radius/shadow, zero-duration transitions.
- `static/js/app.js` — theme switcher removed; skill-chip popovers kept.
- `static/_headers` — CSP updated for the Google Fonts hosts; iconify hosts dropped.
- `static/favicon.svg` — 1-bit.

`static/fonts/` still holds the old self-hosted Inter / JetBrains Mono files.
They are no longer referenced and can be deleted if you keep the Google Fonts CDN.

### Images

- **Portrait** — `static/assets/portrait.png` (1-bit, 128×128) is rendered scaled up
  with `image-rendering: pixelated`, so the hard pixel edges stay crisp. It carries
  the `.im-pixelated` utility, which is *not* applied globally; swap the file to
  change the portrait.
- **Work / education logos** — the original full-color artwork in
  `static/assets/` is used directly (`xero.jpg`, `endgame.jpg`, `epi.jpg`,
  `commonsense.jpg`, `racine.png`, `umd.jpeg`, `dev_academy.jpeg`), referenced via
  `data/*.json`.

### Optional: 1-bit dithers

If you later want dithered logos to match the portrait, convert them and point the
`data/*.json` `image` fields at the results:

```bash
mkdir -p static/assets/dithered
for img in static/assets/*.jpg static/assets/*.jpeg static/assets/*.png; do
  [ -e "$img" ] || continue
  name="$(basename "${img%.*}")"
  magick "$img" \
    -background white -alpha remove -alpha off \
    -resize '128x128^' -gravity center -extent 128x128 \
    -colorspace Gray -dither Riemersma -colors 2 -type bilevel \
    "static/assets/dithered/${name}.png"
done
```

ImageMagick has no built-in Atkinson dither; `Riemersma` (error diffusion) is the
closest MacPaint-like look. Swap in `-dither FloydSteinberg` if you prefer.
`-type bilevel` (with `-colors 2`) guarantees a true 1-bit PNG.

### Verify

```bash
make site   # Tailwind + Zola (+ OG card, Markdown CV); no PDF
```
