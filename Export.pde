/**
 * Export.pde   (reusable shell — should not need edits per program)
 *
 * One deferred-export mechanism for every format. Because Processing is
 * single-threaded the UI freezes during export, so bang buttons only QUEUE
 * an export; handleExport() counts down a couple of frames first so the
 * EXPORTING notice renders before the thread blocks.
 *
 * Every export RE-RENDERS the artwork from the layer functions at the
 * chosen export size — the preview buffer is never scaled or touched.
 *
 *   TIFF: composite of all enabled layers at EXPORT_DPI × size factor
 *   PDF:  multi-page, one page per enabled layer (risograph separations),
 *         sized in points so it opens at correct physical size
 *   SVG:  ONE FILE PER ENABLED LAYER — i.e. one file per plotter pen
 *
 * All files for one export share a timestamped folder, plus a colophon.
 */

final int EXPORT_NONE = 0;
final int EXPORT_TIFF = 1;
final int EXPORT_PDF  = 2;
final int EXPORT_SVG  = 3;
final int EXPORT_ALL  = 4;

int pendingExport = EXPORT_NONE;
int exportFrameDelay = 0;

// Shared base name for the current export — generated once per export so
// every file (tiff/pdf/svgs/colophon) lands in the same folder.
String currentExportBaseName = "";


/// ---- BANG CALLBACKS ---- ///

void saveTiff() { queueExport(EXPORT_TIFF); }
void savePdf()  { queueExport(EXPORT_PDF);  }
void saveSvg()  { queueExport(EXPORT_SVG);  }
void saveAll()  { queueExport(EXPORT_ALL);  }

void queueExport(int mode) {
  if (!bufferCreated) return;
  pendingExport = mode;
  exportFrameDelay = 2; // frames the EXPORTING notice shows before blocking
}


/// ---- DEFERRED EXPORT HANDLER (called from MainScreen.draw) ---- ///

void handleExport() {
  if (pendingExport == EXPORT_NONE) return;

  if (exportFrameDelay > 0) {
    exportFrameDelay--;
    return;
  }

  currentExportBaseName = generateBaseName();
  ArrayList<String> files = new ArrayList<String>();

  if (pendingExport == EXPORT_TIFF || pendingExport == EXPORT_ALL) {
    files.add(exportTiff());
  }
  if (pendingExport == EXPORT_PDF || pendingExport == EXPORT_ALL) {
    files.add(exportPdf());
  }
  if (pendingExport == EXPORT_SVG || pendingExport == EXPORT_ALL) {
    files.addAll(exportSvg());
  }

  saveColophon(files);
  pendingExport = EXPORT_NONE;
}


/// ---- NAMING ---- ///

String generateBaseName() {
  return programName + " - " +
    year() + "-" + nf(month(), 2) + "-" + nf(day(), 2) +
    " - " + nf(hour(), 2) + "-" + nf(minute(), 2) + "-" + nf(second(), 2) +
    " - " + EXPORT_LABELS[exportSizeSelect] + " " + FORMAT_LABELS[formatSelect] +
    " - " + fileNameAppend;
}

String exportFolder() {
  return "x - output/" + currentExportBaseName + "/";
}


/// ---- FORMAT EXPORTERS ---- ///

// Composite raster at the chosen export size — a fresh render, not an upscale
String exportTiff() {
  float pxPerUnit = (EXPORT_DPI / MM_PER_INCH) * EXPORT_FACTORS[exportSizeSelect];
  PVector mm = artMM();

  PGraphics g = createGraphics(round(mm.x * pxPerUnit), round(mm.y * pxPerUnit));
  renderComposite(g, pxPerUnit);

  String path = exportFolder() + currentExportBaseName + ".tif";
  g.save(path);
  println("TIFF saved: " + path + "  (" + g.width + " x " + g.height + " px)");
  g.dispose();
  return path;
}

/**
 * Multi-page PDF — one page per enabled layer, for risograph separation.
 * Sized in points (72/inch) × export factor, so the file opens at the
 * correct physical size in Illustrator / Photoshop.
 *
 * TEMPLATE: layers print in their working colours here. Riso programs
 * convert per-layer to greyscale/knockouts inside their drawLayer()
 * functions (see the Advertisers programs for the knockout patterns).
 */
String exportPdf() {
  float ptPerUnit = (72.0 / MM_PER_INCH) * EXPORT_FACTORS[exportSizeSelect];
  PVector mm = artMM();
  String path = exportFolder() + currentExportBaseName + ".pdf";

  PGraphics g = createGraphics(round(mm.x * ptPerUnit), round(mm.y * ptPerUnit), PDF, path);
  PGraphicsPDF pdf = (PGraphicsPDF) g;

  g.beginDraw();
  boolean firstPage = true;
  for (int i = 0; i < layerCount(); i++) {
    if (!layerEnabled(i)) continue;
    if (!firstPage) pdf.nextPage();
    renderSingleLayer(g, ptPerUnit, i);
    firstPage = false;
  }
  g.endDraw();
  g.dispose();
  println("PDF saved: " + path);
  return path;
}

/**
 * SVG — one file per enabled layer. SVG has no pages, and for pen plotting
 * one-file-per-pen is exactly what you want anyway. Filenames carry the
 * layer index and name so plot order is unambiguous.
 */
ArrayList<String> exportSvg() {
  float ptPerUnit = (72.0 / MM_PER_INCH) * EXPORT_FACTORS[exportSizeSelect];
  PVector mm = artMM();
  ArrayList<String> out = new ArrayList<String>();

  for (int i = 0; i < layerCount(); i++) {
    if (!layerEnabled(i)) continue;

    String path = exportFolder() + currentExportBaseName +
      "_layer" + (i + 1) + "_" + layerName(i) + ".svg";

    PGraphics g = createGraphics(round(mm.x * ptPerUnit), round(mm.y * ptPerUnit), SVG, path);
    g.beginDraw();
    renderSingleLayer(g, ptPerUnit, i);
    g.endDraw();
    g.dispose();

    println("SVG saved: " + path);
    out.add(path);
  }
  return out;
}
