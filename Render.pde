/**
 * Render.pde   (reusable shell — should not need edits per program)
 *
 * THE UNIT SYSTEM
 * All artwork drawing happens in MILLIMETRES ("art units"). One scale
 * transform maps mm to the output target:
 *
 *     pixels: pxPerUnit = dpi / 25.4  (× export size factor)
 *     points: ptPerUnit = 72  / 25.4  (× export size factor)
 *
 * Because of this, "export at A1" is NOT an upscale — it is a re-render
 * of the same mm-space composition at a higher resolution. Stroke weights,
 * sizes and type are defined in mm and stay physically meaningful.
 *
 * The preview buffer is rendered at PREVIEW_DPI for the chosen FORMAT
 * (always A4-based), then blitted to the stage with pan/zoom in
 * drawPreview(). Redraws are on-demand and debounced.
 */

final float MM_PER_INCH = 25.4;

float PREVIEW_DPI = 300; // preview buffer resolution (A4 @300 = 2480×3508)
float EXPORT_DPI  = 300; // raster export resolution

// ---- ARTWORK FORMAT ---- //
// Base composition sizes in mm. All A4-derived; export sizes scale these.
String[]  FORMAT_LABELS = { "PORTRAIT", "LANDSCAPE", "SQUARE" };
PVector[] FORMAT_MM = {
  new PVector(210, 297),  // A4 portrait
  new PVector(297, 210),  // A4 landscape
  new PVector(210, 210),  // square (A4 short edge)
};
int formatSelect = 0;

PVector artMM() { return FORMAT_MM[formatSelect]; }

// ---- EXPORT SIZE ---- //
// ISO A-series shares the 1:sqrt(2) aspect, so each size step is a pure
// linear scale factor on the composition — no recomposition needed.
String[] EXPORT_LABELS  = { "A4", "A3", "A2", "A1" };
float[]  EXPORT_FACTORS = { 1.0, sqrt(2), 2.0, 2 * sqrt(2) };
int exportSizeSelect = 0;

// ---- BUFFER + REDRAW STATE ---- //
PGraphics artBuffer;             // preview-resolution render of the artwork
float previewPxPerUnit;          // px per mm in the preview buffer
boolean bufferCreated = false;

boolean artDirty = true;         // buffer needs re-rendering
int lastGuiChange = 0;           // millis of last artwork-affecting GUI event
int redrawDebounceMs = 250;      // settle time before redraw fires

// ---- PREVIEW PAN / ZOOM ---- //
float imScale;                   // current preview zoom (bound to slider)
float imScaleStored;             // fit-to-window zoom for current buffer
float previewCentreX, previewCentreY;
float dragOffsetX = 0, dragOffsetY = 0;
boolean dragEnabled = false;
PVector dragStartLoc;


// Creates the preview buffer for the current format
void createArtBuffer() {

  previewPxPerUnit = PREVIEW_DPI / MM_PER_INCH;
  PVector mm = artMM();

  artBuffer = createGraphics(round(mm.x * previewPxPerUnit),
                             round(mm.y * previewPxPerUnit));
  bufferCreated = true;

  previewCentreX = ((width - guiWidth) / 2.0) + guiWidth;
  previewCentreY = height / 2.0;

  // Fit-to-window zoom based on the longest edge
  if (artBuffer.height >= artBuffer.width) {
    imScale = (float) height / artBuffer.height;
  } else {
    imScale = (float) (width - guiWidth) / artBuffer.width;
  }
  imScaleStored = imScale;

  Controller c = cp5.getController("imScale");
  if (c != null) c.setValue(imScale);

  imageMode(CENTER);
}

void markArtDirty() {
  artDirty = true;
  lastGuiChange = millis();
}

// Debounced redraw — waits for the GUI to settle so the RENDERING notice
// has time to appear before a slow render blocks the thread.
void handleBufferRedraw() {
  if (!artDirty) return;
  if (millis() - lastGuiChange > redrawDebounceMs) {
    renderComposite(artBuffer, previewPxPerUnit);
    artDirty = false;
  }
}

// Blits the buffer to the stage with pan and zoom
void drawPreview() {

  // When zoomed out enough to see the whole artwork, ease the pan back
  // to centre so the preview re-centres itself.
  if (imScale <= imScaleStored) {
    dragOffsetX *= 0.6;
    dragOffsetY *= 0.6;
  }

  if (dragEnabled) {
    dragOffsetX = mouseX - dragStartLoc.x;
    dragOffsetY = mouseY - dragStartLoc.y;
  }

  pushMatrix();
  translate(previewCentreX + dragOffsetX, previewCentreY + dragOffsetY);
  scale(imScale);
  image(artBuffer, 0, 0);
  popMatrix();
}

/**
 * Converts a screen coordinate (e.g. the mouse) to artwork units (mm).
 * Reverses the preview transform chain: translate -> scale -> CENTER
 * image mode -> px-per-unit.
 */
PVector screenToUnits(float mx, float my) {
  float bx = mx - (previewCentreX + dragOffsetX);
  float by = my - (previewCentreY + dragOffsetY);
  bx /= imScale;
  by /= imScale;
  bx += artBuffer.width  / 2.0;
  by += artBuffer.height / 2.0;
  return new PVector(bx / previewPxPerUnit, by / previewPxPerUnit);
}


/// ---- DATA LOADING (generic chunked-load support) ---- ///
//
// Some programs need to read enough external data that doing it all in one
// go inside MainScreen.enter() would freeze the sketch — Processing is
// single-threaded, so nothing redraws until enter() returns. Rather than
// move that work to a background Java thread (ControlP5/PGraphics calls
// aren't safe off the main thread, and the resulting concurrency bugs are
// hard to debug in the Processing IDE), slow loading is spread across
// frames instead:
//
//   - set dataLoading = true wherever the per-program load begins
//   - implement stepDataLoad(budgetMs) (SampleData.pde) to do a bounded
//     amount of work each call, updating loadingLabel / loadingProgress as
//     it goes, and setting dataLoading = false once complete
//
// MainScreen.draw() (Screens.pde) calls stepDataLoad() and
// drawLoadingNotice() automatically whenever dataLoading is true, and
// locks the format radio and export buttons until it's false — programs
// that never set dataLoading never pay for any of this.

boolean dataLoading     = false;
String  loadingLabel    = "LOADING...";
float   loadingProgress = 0; // 0..1, drawn as a fill bar

void drawLoadingNotice() {
  float px = ((width - guiWidth) / 2.0) + guiWidth;
  float py = height / 2.0;

  textFont(labelFontMono);
  textAlign(CENTER, CENTER);
  fill(cGrey);
  textSize(16);
  text(loadingLabel, px, py - 24);

  float barW = 320, barH = 8;
  float barX = px - barW / 2.0, barY = py + 8;

  noFill();
  stroke(cGrey);
  strokeWeight(1);
  rect(barX, barY, barW, barH);

  noStroke();
  fill(cTheme);
  rect(barX, barY, barW * constrain(loadingProgress, 0, 1), barH);
}


/// ---- HOVER / TOOLTIP ---- ///

SampleObject hoveredObject = null;

void handleHover() {
  hoveredObject = null;
  if (dragEnabled || mouseX <= guiWidth) return;

  PVector u = screenToUnits(mouseX, mouseY);
  // Iterate in reverse so the object drawn on top wins the rollover
  for (int i = sampleObjects.size() - 1; i >= 0; i--) {
    SampleObject o = sampleObjects.get(i);
    if (o.visible && o.hit(u.x, u.y)) {
      hoveredObject = o;
      return;
    }
  }
}

void drawHoverTooltip() {
  if (hoveredObject == null) return;

  String[] lines = hoveredObject.tooltipLines();

  int padding = 10;
  int lineH = 18;
  textFont(labelFontMono);
  textSize(13);

  float maxW = 0;
  for (String l : lines) maxW = max(maxW, textWidth(l));
  float rectW = maxW + padding * 2;
  float rectH = lines.length * lineH + padding * 2;

  float tx = mouseX + 15;
  float ty = mouseY;
  if (tx + rectW > width) tx = mouseX - rectW - 15;

  noStroke();
  fill(cTheme, 220);
  rectMode(CORNER);
  rect(tx, ty, rectW, rectH);

  fill(cBlack);
  textAlign(LEFT);
  for (int i = 0; i < lines.length; i++) {
    if (lines[i] != null && !lines[i].isEmpty()) {
      text(lines[i], tx + padding, ty + padding + (i + 1) * lineH - 4);
    }
  }
}


/// ---- NOTICES ---- ///

void handleNotices() {
  if (artDirty) drawNotice("RENDERING...");
  if (pendingExport != EXPORT_NONE) drawNotice("EXPORTING...");
}

void drawNotice(String msg) {
  pushMatrix();
  translate(previewCentreX, previewCentreY);

  textFont(labelFontMono);
  textSize(18);
  float msgWidth = textWidth(msg);
  int padding = 10;

  rectMode(CENTER);
  textAlign(CENTER);
  fill(0, 200);
  noStroke();
  rect(0, 0, msgWidth + padding * 2, textAscent() + textDescent() + padding * 2);
  fill(cTheme);
  text(msg, 0, textAscent() * 0.4);

  popMatrix();
}
