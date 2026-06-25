/**
 * Layers.pde   (PER-PROGRAM — replace the layer list for each new program)
 *
 * The artwork is expressed as an ordered list of LAYERS. Each layer is one
 * drawing function operating in mm. The same layer functions feed every
 * output target — the export code decides whether to composite or separate:
 *
 *   - Preview + TIFF:  renderComposite() draws all enabled layers into one
 *                      buffer in screen order.
 *   - Risograph PDF:   one PAGE per enabled layer (Export.pde).
 *   - Pen-plotter SVG: one FILE per enabled layer = one file per pen.
 *
 * Any aesthetic change made in a drawLayer function automatically appears
 * in the preview AND every export format — there is exactly one copy of
 * the drawing code.
 *
 * TO ADD A LAYER: add a constant + name, bump layerCount(), add a case in
 * drawLayer(), and (optionally) an enable condition in layerEnabled().
 */

final int LAYER_SQUARES = 0;
final int LAYER_CROSSES = 1;

int layerCount() { return 2; }

// Used for SVG filenames and the colophon
String layerName(int layer) {
  switch (layer) {
    case LAYER_SQUARES: return "squares";
    case LAYER_CROSSES: return "crosses";
  }
  return "layer" + layer;
}

// Whether a layer is currently switched on
boolean layerEnabled(int layer) {
  switch (layer) {
    case LAYER_SQUARES: return showSquares;
    case LAYER_CROSSES: return showCrosses;
  }
  return true;
}

/**
 * Draws one layer. ALL coordinates, sizes and stroke weights are in mm —
 * the caller has already applied the mm -> px/pt scale transform.
 */
void drawLayer(PGraphics g, int layer) {

  switch (layer) {

  case LAYER_SQUARES:
    g.noStroke();
    g.fill(cPink);
    g.rectMode(CENTER);
    for (SampleObject o : sampleObjects) {
      if (o.visible && o.kind == KIND_SQUARE) {
        g.rect(o.x, o.y, squareSize, squareSize);
      }
    }
    break;

  case LAYER_CROSSES:
    g.noFill();
    g.stroke(cDarkGrey);
    g.strokeWeight(crossWeight);     // mm — physically meaningful at any size
    for (SampleObject o : sampleObjects) {
      if (o.visible && o.kind == KIND_CROSS) {
        float r = crossSize * 0.5;
        g.line(o.x - r, o.y - r, o.x + r, o.y + r);
        g.line(o.x - r, o.y + r, o.x + r, o.y - r);
      }
    }
    break;
  }
}


/// ---- RENDER ENTRY POINTS (reusable — leave as-is) ---- ///

/**
 * Composite render: white ground + all enabled layers in order.
 * Used by the preview buffer and the TIFF export.
 *
 * @param g          target graphics (raster)
 * @param pxPerUnit  pixels per mm for this target
 */
void renderComposite(PGraphics g, float pxPerUnit) {
  g.beginDraw();
  g.background(255);
  g.pushMatrix();
  g.scale(pxPerUnit);
  for (int i = 0; i < layerCount(); i++) {
    if (layerEnabled(i)) drawLayer(g, i);
  }
  g.popMatrix();
  g.endDraw();
}

/**
 * Single-layer render onto an already-open graphics context.
 * Used by the PDF (per page) and SVG (per file) exports, which own their
 * beginDraw / endDraw / page-break sequencing.
 *
 * @param g           target graphics (PDF or SVG)
 * @param unitsScale  points (or px) per mm for this target
 */
void renderSingleLayer(PGraphics g, float unitsScale, int layer) {
  g.pushMatrix();
  g.scale(unitsScale);
  drawLayer(g, layer);
  g.popMatrix();
}
