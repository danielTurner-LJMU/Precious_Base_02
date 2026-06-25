# PRECIOUS: BASE TEMPLATE

Part of the *Precious* series — a PhD practice-led research project exploring
personal Facebook data as artistic material. This repository is the reusable
base layer that each program in the series is built from; it contains no
Facebook-specific data parsing itself — that logic is added per program.

**This repo is a starting point, not a standalone artwork.** To build a new
program from it, use "Use this template" above, then edit the files listed
below.

## What it does

A reusable shell for the Precious series. Run it, select any folder on the
intro screen (the path is stored but not parsed), hit Confirm, and you get
pink squares + dark grey crosses on an A4-based canvas with working zoom,
pan, hover tooltips, a pop-out object list, and TIFF / multi-page PDF /
per-layer SVG export at A4–A1.

## Requirements

Processing 4, ControlP5 library (Sketch > Import Library > Manage Libraries).
PDF and SVG libraries ship with Processing.

## Architecture at a glance

All artwork drawing is in millimetres. One scale transform maps mm to the
output target (preview px, TIFF px, PDF/SVG points). Exports therefore
re-render at the chosen size — nothing is upscaled, ever.

The artwork is a list of layers (`Layers.pde`). The same layer functions
feed the composite preview/TIFF, one-page-per-layer PDFs (riso), and
one-file-per-layer SVGs (one file per plotter pen).

## Which files change per program

| File | Purpose |
|---|---|
| `SampleData.pde` | your data loading + object classes |
| `Layers.pde` | your layer list + drawing functions (mm only!) |
| `GUI.pde` | swap sample controls (one line each via `Layout_Helpers`) |
| `Colophon.pde` | extend `buildColophon()` |

## Which files should not need edits

`Precious_Base.pde`, `Screens.pde`, `Render.pde`, `Export.pde`,
`Layout_Helpers.pde`, `Preferences.pde`, `ObjectListFrame.pde`

## Extending it

- **Adding a control** — one line in `initMainControls()` + (if it changes
  the artwork) its name in `controlEvent()`'s dirty list
- **Adding a layer** — constant + name + case in `Layers.pde`
- **Adding an export size** — label + factor in `Render.pde`
- **Changing base format size** — `FORMAT_MM` in `Render.pde`

## License

MIT — see [LICENSE](./LICENSE).
