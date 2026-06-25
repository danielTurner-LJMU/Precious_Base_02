/**
 * Precious: Base Template
 *
 * A reusable starting point for the "Precious" series of Processing programs
 * that generate artworks from personal Facebook data exports.
 *
 * This template contains the full application shell with placeholder content:
 *
 *   - Intro screen with data-folder selection (path stored, not yet parsed)
 *   - Screen-object state machine (see Screens.pde)
 *   - Millimetre-based rendering: ALL artwork drawing happens in mm,
 *     a single scale transform maps mm -> pixels/points per output target
 *   - First-class layers: the same layer functions feed the composite
 *     preview/TIFF, the multi-page risograph PDF, and per-pen SVG files
 *   - Artwork FORMAT (portrait/landscape/square) chosen up front;
 *     export SIZE (A4..A1) chosen at export time — exports re-render,
 *     they never upscale pixels
 *   - Layout-cursor GUI helpers (no magic y-position multipliers)
 *   - Pan / zoom preview, hover tooltips, deferred exports with notices,
 *     debounce on buffer redraws, generic scrollable pop-out window,
 *     colophon stub, preferences file
 *
 * TO BUILD A NEW PROGRAM FROM THIS TEMPLATE — the usual touch points:
 *   1. SampleData.pde   -> replace with your data loading + object classes
 *   2. Layers.pde       -> replace the layer list + layer drawing functions
 *   3. GUI.pde          -> swap the sample controls for real ones (one line each)
 *   4. Colophon.pde     -> extend buildColophon() with program-specific detail
 *   Everything else (screens, export, preview, pop-out) should not need edits.
 *
 * Author: Daniel Turner
 * Institution: Liverpool John Moores University
 * PhD Project: Precious: Reclaiming Value for Personal Data
 *
 * Built with Processing 4
 * Dependencies: ControlP5 (GUI), processing.pdf + processing.svg (export, bundled)
 */

import processing.pdf.*;  // PDF export (bundled with Processing)
import processing.svg.*;  // SVG export (bundled with Processing)
import controlP5.*;       // GUI library
import java.util.*;       // Utilities

String title = "Precious: Base Template";

// Short machine-friendly program name — used in export file names
String programName = "Precious_Base";

/* Appended to export filenames:
 Final programs will have the participant's pseudo label passed here so works
 are attributable. All testing/development exports are appended "test". */
String fileNameAppend = "test";

int guiWidth = 500; // right edge of the GUI column on the main screen

void setup() {
  // ControlP5 quirk: controllers won't respond if positioned outside the
  // INITIAL surface size, so start large and resize down per-screen.
  size(1920, 1080);

  initGUI();
  surface.setResizable(true);
  windowTitle(title);

  // Force non-Retina rendering.
  // Processing 4.5.x + ControlP5 on macOS can produce
  // oversized GUI text and slower rendering at pixelDensity(2).
  pixelDensity(1);

  setScreen(SCREEN_INTRO);
}

// All top-level events forward to the current screen — no state checks here.
void draw() {
  currentScreen.draw();
}
void mousePressed() {
  currentScreen.mousePressed();
}
void mouseReleased() {
  currentScreen.mouseReleased();
}
void keyPressed() {
  currentScreen.keyPressed();
}

// Resizes and centres the sketch window on screen
void resizeCanvas(int w, int h) {
  int windowX = (displayWidth  - w) / 2;
  int windowY = (displayHeight - h) / 2;
  windowResize(w, h);
  surface.setLocation(windowX, windowY);
}

// Common overlay graphics — vertical separator between controls and preview
void drawOverlays() {
  stroke(255);
  strokeWeight(1);
  line(guiWidth, 0, guiWidth, height);
}
