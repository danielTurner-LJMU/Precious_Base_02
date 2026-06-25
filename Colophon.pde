/**
 * Colophon.pde   (stub — extend buildColophon() per program)
 *
 * Writes a plain-text colophon alongside each export: a human-readable
 * record of the source data, settings, and output files for the session.
 * The full Advertisers-style colophon (data summaries, frequency lists,
 * wrapped name blocks) slots into buildColophon() per program.
 */

import java.text.SimpleDateFormat;

final int COLOPHON_LINE_WIDTH = 80;
final String DIVIDER = "================================================================================";

// Generated once per program run — links a colophon to its session
String sessionID = hex((int) random(0xFFFFFF), 6).toLowerCase();


void saveColophon(ArrayList<String> exportedFiles) {
  String[] lines = buildColophon(exportedFiles);
  String path = exportFolder() + currentExportBaseName + "_colophon.txt";
  saveStrings(path, lines);
  println("Colophon saved: " + path);
}

// TEMPLATE: extend with program-specific data summaries per program
String[] buildColophon(ArrayList<String> exportedFiles) {

  ArrayList<String> l = new ArrayList<String>();
  SimpleDateFormat sdf = new SimpleDateFormat("dd MMMM yyyy  'at'  HH:mm");

  l.add(DIVIDER);
  l.add(title);
  l.add("Session " + sessionID + "  —  " + sdf.format(new java.util.Date()));
  l.add(DIVIDER);
  l.add("");
  l.add("SOURCE");
  l.add("  Data folder:    " + (parentFolderPath == null ? "(none)" : parentFolderPath));
  l.add("");
  l.add("ARTWORK");
  l.add("  Format:         " + FORMAT_LABELS[formatSelect] +
        "  (" + nf(artMM().x, 0, 0) + " x " + nf(artMM().y, 0, 0) + " mm base)");
  l.add("  Export size:    " + EXPORT_LABELS[exportSizeSelect] +
        "  (x" + nf(EXPORT_FACTORS[exportSizeSelect], 0, 3) + ")");
  l.add("");
  l.add("SETTINGS");
  l.add("  Square size:    " + nf(squareSize, 0, 1) + " mm");
  l.add("  Cross size:     " + nf(crossSize, 0, 1) + " mm");
  l.add("  Cross weight:   " + nf(crossWeight, 0, 2) + " mm");
  l.add("  Show squares:   " + yn(showSquares));
  l.add("  Show crosses:   " + yn(showCrosses));
  l.add("");
  l.add("LAYERS");
  for (int i = 0; i < layerCount(); i++) {
    l.add("  " + (i + 1) + ". " + layerName(i) + (layerEnabled(i) ? "" : "  (off)"));
  }
  l.add("");
  l.add("FILES");
  for (String f : exportedFiles) {
    l.add("  " + new File(f).getName());
  }
  l.add("");
  l.add(DIVIDER);

  return l.toArray(new String[0]);
}

String yn(boolean b) { return b ? "YES" : "NO"; }
