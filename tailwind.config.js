import typographyPlugin from '@tailwindcss/typography';

const MONO = ['"IBM Plex Mono"', '"Courier New"', 'Courier', 'monospace'];

/**
 * 1-bit / early-Macintosh design system.
 *
 * Strictly pure black (#000) and pure white (#fff). No grays, no colors,
 * no border-radius, no shadows, no gradients (dither strips are built in CSS),
 * and no animated transitions. `theme.borderRadius` / `theme.boxShadow` are
 * intentionally *replaced* (not extended) so any stray utility collapses to 0.
 *
 * Legacy `color-*` semantic tokens are kept, but flattened to black/white, so
 * older template markup keeps compiling while the palette stays 1-bit.
 *
 * @type {import('tailwindcss').Config}
 */
export default {
  content: ['./templates/**/*.html', './templates/**/*.svg', './content/**/*.md', './static/**/*.js'],
  theme: {
    borderRadius: {
      none: '0',
      DEFAULT: '0',
      sm: '0',
      md: '0',
      lg: '0',
      xl: '0',
      '2xl': '0',
      '3xl': '0',
      full: '0',
    },
    boxShadow: {
      none: 'none',
      DEFAULT: 'none',
      sm: 'none',
      md: 'none',
      lg: 'none',
      xl: 'none',
      '2xl': 'none',
      inner: 'none',
    },
    extend: {
      spacing: {
        15: '3.75rem',
        18: '4.5rem',
        26: '6.5rem',
        50: '12.5rem',
      },
      colors: {
        // Route the two 1-bit colours through theme variables so the entire
        // palette (including Tailwind's built-in black/white utilities) flips
        // with the device colour scheme. See styles/input.css for the values.
        black: 'var(--im-ink)',
        white: 'var(--im-paper)',
        ink: 'var(--im-ink)',
        paper: 'var(--im-paper)',
        // Neutralise the only two grays Tailwind's preflight emits
        // (default border colour + input placeholder). 1-bit means 1-bit.
        gray: {
          200: 'var(--im-ink)',
          400: 'var(--im-ink)',
        },
        color: {
          'button-bg': 'var(--im-ink)',
          'button-bg-contrast': 'var(--im-paper)',
          'text-title': 'var(--im-ink)',
          'text-primary': 'var(--im-ink)',
          'text-secondary': 'var(--im-ink)',
          'text-contrast': 'var(--im-paper)',
          'icon-light': 'var(--im-ink)',
          'icon-main': 'var(--im-ink)',
          'icon-dark': 'var(--im-ink)',
          border: 'var(--im-ink)',
          separator: 'var(--im-ink)',
          'bg-body': 'var(--im-paper)',
          'bg-card': 'var(--im-paper)',
          'bg-popover': 'var(--im-paper)',
          'bg-tooltip': 'var(--im-ink)',
          'bg-light': 'var(--im-paper)',
          'bg-main': 'var(--im-paper)',
          'bg-dark': 'var(--im-ink)',
        },
      },
      fontFamily: {
        mono: MONO,
        header: MONO,
        body: MONO,
        skills: MONO,
      },
      borderColor: {
        // Default border colour for the whole document (preflight default is gray-200).
        DEFAULT: 'var(--im-ink)',
      },
      transitionDuration: {
        DEFAULT: '0s',
        0: '0s',
        75: '0s',
        100: '0s',
        150: '0s',
        200: '0s',
        300: '0s',
        500: '0s',
        700: '0s',
        1000: '0s',
      },
      transitionDelay: {
        DEFAULT: '0s',
        75: '0s',
        100: '0s',
        150: '0s',
        200: '0s',
        300: '0s',
        500: '0s',
        700: '0s',
        1000: '0s',
      },
      typography: {
        DEFAULT: {
          css: {
            '--tw-prose-body': 'var(--im-ink)',
            '--tw-prose-headings': 'var(--im-ink)',
            '--tw-prose-lead': 'var(--im-ink)',
            '--tw-prose-links': 'var(--im-ink)',
            '--tw-prose-bold': 'var(--im-ink)',
            '--tw-prose-counters': 'var(--im-ink)',
            '--tw-prose-bullets': 'var(--im-ink)',
            '--tw-prose-hr': 'var(--im-ink)',
            '--tw-prose-quotes': 'var(--im-ink)',
            '--tw-prose-quote-borders': 'var(--im-ink)',
            '--tw-prose-captions': 'var(--im-ink)',
            '--tw-prose-kbd': 'var(--im-ink)',
            '--tw-prose-kbd-shadows': 'var(--im-ink)',
            '--tw-prose-code': 'var(--im-ink)',
            '--tw-prose-pre-code': 'var(--im-paper)',
            '--tw-prose-pre-bg': 'var(--im-ink)',
            '--tw-prose-th-borders': 'var(--im-ink)',
            '--tw-prose-td-borders': 'var(--im-ink)',
          },
        },
      },
    },
  },
  plugins: [typographyPlugin],
};
