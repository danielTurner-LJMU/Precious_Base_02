/**
 * SampleData.pde   (PER-PROGRAM — replace entirely with real data loading)
 *
 * Placeholder content: pink squares and dark grey crosses scattered inside
 * a margin, each with a name for the hover tooltip and a visibility flag
 * driven by the pop-out object list.
 *
 * In a real program this tab becomes the data_*.pde files: JSON parsing of
 * the selected Facebook export folder and the DataObject classes built
 * from it. The contract the rest of the template relies on:
 *
 *   - a list of objects with  name / visible / hit(x,y) / tooltipLines()
 *   - positions expressed in MILLIMETRES within artMM() bounds
 *   - validateDataFolder() — confirms the expected files exist before the
 *     intro screen's Confirm button is allowed to proceed
 *   - stepDataLoad(budgetMs) — for programs with slow external data, does
 *     a bounded amount of loading work per call (see Render.pde's DATA
 *     LOADING section for the full pattern). The placeholder content loads
 *     instantly, so this is a one-line no-op below.
 */

final int KIND_SQUARE = 0;
final int KIND_CROSS  = 1;

int numSquares = 26;
int numCrosses = 18;

// Artwork parameters — mm, bound automatically to the GUI sliders
float squareSize  = 12;
float crossSize   = 10;
float crossWeight = 1.2;
float marginMM    = 18;   // keep-out border inside the composition

// Layer visibility — bound automatically to the GUI toggles
boolean showSquares = true;
boolean showCrosses = true;

ArrayList<SampleObject> sampleObjects = new ArrayList<SampleObject>();


class SampleObject {

  int kind;
  String name;
  float x, y;          // position in mm
  boolean visible = true;

  SampleObject(int kind, String name) {
    this.kind = kind;
    this.name = name;
  }

  // Hit test in mm — half the drawn size as a square hit area
  boolean hit(float ux, float uy) {
    float r = (kind == KIND_SQUARE ? squareSize : crossSize) * 0.5;
    return abs(ux - x) <= r && abs(uy - y) <= r;
  }

  // Lines shown in the hover tooltip
  String[] tooltipLines() {
    return new String[] {
      name,
      (kind == KIND_SQUARE ? "Sample square" : "Sample cross"),
      "x " + nf(x, 0, 1) + " mm   y " + nf(y, 0, 1) + " mm"
    };
  }
}


// Builds the object list — called when entering the main screen.
// (Real programs: parse JSON and construct DataObjects here instead.)
void buildSampleObjects() {
  sampleObjects.clear();
  for (int i = 0; i < numSquares; i++) {
    sampleObjects.add(new SampleObject(KIND_SQUARE, "Square " + nf(i + 1, 2)));
  }
  for (int i = 0; i < numCrosses; i++) {
    sampleObjects.add(new SampleObject(KIND_CROSS, "Cross " + nf(i + 1, 2)));
  }
  layoutSampleObjects();

  Textlabel t = cp5.get(Textlabel.class, "objectReadout");
  if (t != null) {
    t.setText("Sample objects: " + numSquares + " squares   " + numCrosses + " crosses");
  }
}

// Random positions in mm within the current format's bounds.
// Called on REGENERATE and when the artwork format changes.
void layoutSampleObjects() {
  PVector mm = artMM();
  for (SampleObject o : sampleObjects) {
    o.x = random(marginMM, mm.x - marginMM);
    o.y = random(marginMM, mm.y - marginMM);
  }
}


// TEMPLATE: real programs with an external data dependency override this
// to confirm the expected files/folders exist, returning false and
// setting dataValidationError (Preferences.pde) with a participant-
// readable explanation if not. Called from confirm() (GUI.pde) before
// ever leaving the intro screen. The placeholder template has no real
// data dependency, so this always passes.
boolean validateDataFolder() {
  return true;
}

// TEMPLATE: real programs with slow external data override this to do a
// bounded amount of work per call (budgetMs), updating loadingProgress as
// they go, and setting dataLoading = false once complete — see Render.pde's
// DATA LOADING section. The placeholder content has nothing slow to do.
void stepDataLoad(int budgetMs) {
  dataLoading = false;
}
