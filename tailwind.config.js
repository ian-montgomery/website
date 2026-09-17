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
        ink: '#000000',
        paper: '#ffffff',
        // Neutralise the only two grays Tailwind's preflight emits
        // (default border colour + input placeholder). 1-bit means 1-bit.
        gray: {
          200: '#000000',
          400: '#000000',
        },
        color: {
          'button-bg': '#000000',
          'button-bg-contrast': '#ffffff',
          'text-title': '#000000',
          'text-primary': '#000000',
          'text-secondary': '#000000',
          'text-contrast': '#ffffff',
          'icon-light': '#000000',
          'icon-main': '#000000',
          'icon-dark': '#000000',
          border: '#000000',
          separator: '#000000',
          'bg-body': '#ffffff',
          'bg-card': '#ffffff',
          'bg-popover': '#ffffff',
          'bg-tooltip': '#000000',
          'bg-light': '#ffffff',
          'bg-main': '#ffffff',
          'bg-dark': '#000000',
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
        DEFAULT: '#000000',
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
            '--tw-prose-body': '#000000',
            '--tw-prose-headings': '#000000',
            '--tw-prose-lead': '#000000',
            '--tw-prose-links': '#000000',
            '--tw-prose-bold': '#000000',
            '--tw-prose-counters': '#000000',
            '--tw-prose-bullets': '#000000',
            '--tw-prose-hr': '#000000',
            '--tw-prose-quotes': '#000000',
            '--tw-prose-quote-borders': '#000000',
            '--tw-prose-captions': '#000000',
            '--tw-prose-kbd': '#000000',
            '--tw-prose-kbd-shadows': '#000000',
            '--tw-prose-code': '#000000',
            '--tw-prose-pre-code': '#ffffff',
            '--tw-prose-pre-bg': '#000000',
            '--tw-prose-th-borders': '#000000',
            '--tw-prose-td-borders': '#000000',
          },
        },
      },
    },
  },
  plugins: [typographyPlugin],
};
