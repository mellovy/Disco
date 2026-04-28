import 'package:flutter/material.dart';

/// Soft Pixel palette — pastel vaporwave inspired by retro interface art.
/// Think: pink & mint on sky blue, chunky pixel borders, warm cream panels.
class PixelColors {
  // ── Dark mode: deep periwinkle with neon pastel pops ──────────────────────
  static const darkBg       = Color(0xFF1A1030);   // deep purple-navy
  static const darkSurface  = Color(0xFF2B1F4A);   // muted purple
  static const darkCard     = Color(0xFF3A2B5F);   // soft violet card
  static const darkBorder   = Color(0xFF7B5EA7);   // mid purple border

  // Neon pastel accents for dark mode
  static const neonPink     = Color(0xFFFF7EB9);   // soft bubblegum pink
  static const neonCyan     = Color(0xFF7FECFF);   // pastel cyan/mint
  static const neonYellow   = Color(0xFFFFE87C);   // creamy yellow
  static const neonGreen    = Color(0xFF96FFCC);   // mint green
  static const neonPurple   = Color(0xFFD4AAFF);   // lavender

  // ── Light mode: sky blue base with pink & mint accents ────────────────────
  static const lightBg      = Color(0xFFD6EEFF);   // soft sky blue (like the ref image bg)
  static const lightSurface = Color(0xFFEDD6F5);   // pale lavender surface
  static const lightCard    = Color(0xFFFFC8E8);   // pastel pink card (ref image panels)
  static const lightCardAlt = Color(0xFFC8F5E8);   // pastel mint card
  static const lightBorder  = Color(0xFFB090CC);   // medium lavender border

  // Punchy accents for light mode
  static const accentPink   = Color(0xFFE86DB0);   // hot pink (ref image buttons/borders)
  static const accentMint   = Color(0xFF3DCFB0);   // teal-mint (ref image highlights)
  static const accentBlue   = Color(0xFF6B8BFF);   // periwinkle blue
  static const accentLavender = Color(0xFFAA80FF); // soft purple
  static const accentOrange = Color(0xFFFF9B6B);   // warm peach (kept for compatibility)
  static const accentRose   = Color(0xFFFF6BA8);   // rose pink

  // ── Pixel-art specific ────────────────────────────────────────────────────
  /// The "dither" checkerboard tint used in retro UIs
  static const pixelDither  = Color(0x22FFFFFF);

  static const primary = accentPink;
}