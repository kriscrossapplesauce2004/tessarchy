# Assets

- `shell/artwork/tessarchy-mark.svg`: original Tessarchy tessellated T mark,
  authored as editable SVG for this project. Repository MIT license.
- `shell/artwork/mark-face-0.svg` through `mark-face-5.svg`: the six paths from
  the original mark, separated for the code-driven assembly animation. Same
  provenance and license as the original SVG. No imported console artwork.
- `shell/artwork/aurora-fold.png`: original wallpaper generated with OpenAI
  imagegen on 2026-10-16 for this project. Prompt: portrait mobile OS wallpaper,
  luminous glacier-mint and smoky teal folds, midnight navy, pale gold highlights,
  dark space for typography; no text, logos, or device mockups. No external
  reference images were used.
- `shell/icons/*.svg`: symbolic UI icons authored for Tessarchy under the
  repository MIT license. No icon fonts or external icon libraries are required.

Artwork lives inside `shell/` so development copies, packages, source snapshots
and the ISO staging workflow all carry the same assets. Generated preview
screenshots belong in ignored `build/`, not here.

The official logo kit is exported from the unchanged SVG by
`scripts/export-brand-assets.py --output NEW_DIRECTORY`. It provides transparent
mint/white/black PNG at 16–2048 pixels, SVG, WebP, JPG, ICO, vector PDF and spinning
GIF/WebP/SVG variants, with source hashes and a ZIP manifest. Requires installed
Pillow and rsvg-convert; it never installs dependencies or overwrites existing
output. Generated kits stay under ignored dist/ and are distributed as artifacts.
