// ── Design Tokens ─────────────────────────────────────────────────────────────
export const Colors = {
  primary:       '#7C6EFA',   // Indigo-violet
  primaryDark:   '#5A4FD8',
  primaryLight:  '#9D93FC',
  secondary:     '#00D4AA',   // Teal-green
  accent:        '#FF9F43',   // Orange

  bg:            '#0F0F1A',   // Deep dark background
  surface:       '#1A1A2E',   // Card/surface
  surface2:      '#24243E',   // Elevated surface
  border:        '#2E2E4A',   // Subtle border

  success:       '#00D4AA',
  warning:       '#FF9F43',
  error:         '#FF6B6B',
  info:          '#54A0FF',

  textPrimary:   '#FFFFFF',
  textSecondary: '#A0A0C0',
  textMuted:     '#606080',
  textInverse:   '#0F0F1A',

  white:         '#FFFFFF',
  black:         '#000000',
  transparent:   'transparent',
};

export const FontSizes = {
  xs:   11,
  sm:   13,
  md:   15,
  lg:   17,
  xl:   20,
  xxl:  24,
  xxxl: 30,
  huge: 38,
};

export const FontWeights = {
  regular:    '400' as const,
  medium:     '500' as const,
  semibold:   '600' as const,
  bold:       '700' as const,
  extrabold:  '800' as const,
};

export const Spacing = {
  xs:  4,
  sm:  8,
  md:  12,
  lg:  16,
  xl:  20,
  xxl: 28,
  xxxl:40,
};

export const Radius = {
  sm:   6,
  md:   10,
  lg:   14,
  xl:   20,
  full: 999,
};

export const Shadows = {
  sm: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
    elevation: 2,
  },
  md: {
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.4,
    shadowRadius: 8,
    elevation: 5,
  },
  glow: {
    shadowColor: '#7C6EFA',
    shadowOffset: { width: 0, height: 0 },
    shadowOpacity: 0.5,
    shadowRadius: 12,
    elevation: 8,
  },
};
