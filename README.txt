PRECIOUS: BASE TEMPLATE
=======================

A reusable shell for the Precious series. Run it, select any folder on the
intro screen (the path is stored but not parsed), hit Confirm, and you get
pink squares + dark grey crosses on an A4-based canvas with working zoom,
pan, hover tooltips, a pop-out object list, and TIFF / multi-page PDF /
per-layer SVG export at A4-A1.

REQUIREMENTS
  Processing 4, ControlP5 library (Sketch > Import Library > Manage Libraries).
  PDF and SVG libraries ship with Processing.

ARCHITECTURE AT A GLANCE
  All artwork drawing is in MILLIMETRES. One scale transform maps mm to the
  output target (preview px, TIFF px, PDF/SVG points). Exports therefore
  RE-RENDER at the chosen size - nothing is upscaled, ever.

  The artwork is a list of LAYERS (Layers.pde). The same layer functions
  feed the composite preview/TIFF, one-page-per-layer PDFs (riso), and
  one-file-per-layer SVGs (one file per plotter pen).

WHICH FILES CHANGE PER PROGRAM
  SampleData.pde   -> your data loading + object classes
  Layers.pde       -> your layer list + drawing functions (mm only!)
  GUI.pde          -> swap sample controls (one line each via Layout_Helpers)
  Colophon.pde     -> extend buildColophon()

WHICH FILES SHOULD NOT NEED EDITS
  Precious_Base.pde, Screens.pde, Render.pde, Export.pde,
  Layout_Helpers.pde, Preferences.pde, ObjectListFrame.pde

ADDING A CONTROL          -> one line in initMainControls() + (if it changes
                             the artwork) its name in controlEvent()'s dirty list
ADDING A LAYER            -> constant + name + case in Layers.pde
ADDING AN EXPORT SIZE     -> label + factor in Render.pde
CHANGING BASE FORMAT SIZE -> FORMAT_MM in Render.pde
