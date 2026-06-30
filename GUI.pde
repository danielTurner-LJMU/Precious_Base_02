/**
 * GUI.pde
 *
 * Builds the ControlP5 interface for both screens and routes events.
 *
 * Most controllers bind automatically to the global variable sharing their
 * name (squareSize, crossSize, showSquares...), so the only job left for
 * controlEvent() is marking the art buffer dirty and routing pop-out toggles.
 *
 * TEMPLATE: initMainControls() contains the SAMPLE control set. Replace the
 * one-liners in the CONTROLS section with your program's controls — the
 * INPUT / ARTWORK FORMAT / OUTPUT sections should carry across unchanged.
 *
 * Also carries across unchanged: the registerMethod("post", this) call in
 * initGUI() (required for F12 screenshots, see Screenshots.pde), and
 * confirm() / setFormatRadioLocked() / updateExportLockState(), which
 * implement the data-validation and load-locking contract described in
 * SampleData.pde and Render.pde's DATA LOADING section.
 */

ControlP5 cp5;

RadioButton rFormat;      // artwork format: portrait / landscape / square
RadioButton rExportSize;  // export size: A4 / A3 / A2 / A1

void initGUI() {
  cp5 = new ControlP5(this);
  headerFont     = loadFont("MADETOMMY-Bold-24.vlw");
  labelFont14    = loadFont("AGaramondPro-Regular-14.vlw");
  subFont        = createFont("Inconsolata-Regular.ttf", 18, true);
  labelFontMono  = createFont("Inconsolata-Bold.ttf", 12, true);
  cp5FontMain = new ControlFont(labelFont14);
  cp5FontMono = new ControlFont(labelFontMono);

  // Registered AFTER ControlP5's own constructor, so this "post" hook runs
  // strictly after ControlP5's internal widget rendering for the frame —
  // needed so F12 screenshots (Screenshots.pde) capture the GUI controls
  // too, not just whatever was drawn before ControlP5's own draw pass.
  registerMethod("post", this);
}


/// ---- INTRO SCREEN CONTROLS ---- ///

void initIntroControls() {

  // Debug text field for editing the participant label — hidden by default.
  // Revealed by pressing P on the intro screen; dismissed by P, Esc, or Enter.
  cp5.addTextfield("participantLabel")
    .setPosition(canvasCenterX - sButtonW, 200)
    .setSize(sButtonW * 2, 36)
    .setAutoClear(false)
    .setText(fileNameAppend)
    .setColor(cWhite)
    .setColorBackground(cBlack)
    .setColorForeground(cGrey)
    .setColorActive(cTheme)
    .setColorCursor(cWhite)
    .setColorLabel(cBlack)
    .hide()
    ;
  Textfield tf = cp5.get(Textfield.class, "participantLabel");
  tf.getCaptionLabel()
    .setText("PARTICIPANT LABEL  (enter to confirm, esc to cancel)")
    .setFont(cp5FontMono)
    .setSize(11)
    .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingY(6);

  cp5.addButton("selectDataPath")
    .setPosition(canvasCenterX - (sButtonW / 2), 500)
    .setSize(sButtonW, sButtonH)
    ;
  styleIntro("selectDataPath", "Select Data Folder");

  cp5.addButton("confirm")
    .setPosition(canvasCenterX - (lButtonW / 2), 640)
    .setSize(lButtonW, lButtonH)
    .hide()
    ;
  styleIntro("confirm", "Confirm");
}


/// ---- MAIN SCREEN CONTROLS ---- ///

void initMainControls() {

  layoutStart(20, 8);

  // --- INPUT --- //
  header("INPUT");
  infoLabel("inputFolder", "FOLDER: " + folderName);
  infoLabel("participantReadout", "PARTICIPANT LABEL: " + fileNameAppend);
  infoLabel("objectReadout",
    "Sample objects: " + numSquares + " squares   " + numCrosses + " crosses");

  // --- ARTWORK FORMAT --- //
  // Format fixes the composition's aspect; the base size is always A4.
  // Physical output size is chosen at export time (OUTPUT section below).
  header("ARTWORK FORMAT");
  rFormat = radioRow("artworkFormat", FORMAT_LABELS, 70, 30, 10);
  // Nothing is pre-selected — choosing a format creates the first buffer.
  // Once chosen, clicking the active item can't deselect back to none.
  rFormat.setNoneSelectedAllowed(false);

  // --- CONTROLS --- //
  // TEMPLATE: replace from here down to OUTPUT with your real controls.
  header("CONTROLS");

  slider("imScale", "PREVIEW ZOOM", 0.02, 1.5, 0.2);
  gap(6);
  slider("squareSize",  "SQUARE SIZE (MM)",  2,   40, squareSize);
  slider("crossSize",   "CROSS SIZE (MM)",   2,   40, crossSize);
  slider("crossWeight", "CROSS WEIGHT (MM)", 0.2, 8,  crossWeight);
  gap(10);

  rowStart();
  toggleInRow("showSquares", "SHOW\nSQUARES").setValue(showSquares);
  toggleInRow("showCrosses", "SHOW\nCROSSES").setValue(showCrosses);
  rowEnd(20 + 38); // control height + label clearance

  rowStart();
  bangInRow("regenerate", "REGENERATE", 100, 40);
  bigToggleInRow("showObjects", "SHOW/HIDE\nOBJECTS", 100, 40).setValue(false);
  rowEnd(40 + 42);

  // --- OUTPUT --- //
  // Export size is a pure scale factor on the composition — exports
  // RE-RENDER in mm at the target resolution, they never upscale pixels.
  header("OUTPUT");
  infoLabel("exportSizeLabel", "EXPORT SIZE");
  gap(4);
  rExportSize = radioRow("exportSize", EXPORT_LABELS);
  rExportSize.setNoneSelectedAllowed(false);
  gap(8);

  rowStart();
  bangInRow("saveTiff", "SAVE\nTIFF", 75, 40);
  bangInRow("savePdf",  "SAVE\nPDF",  75, 40);
  bangInRow("saveSvg",  "SAVE\nSVG",  75, 40);
  bangInRow("saveAll",  "SAVE\nALL",  75, 40);
  rowEnd(0);

  // Visual default; exportSizeSelect already defaults to 0 (A4) so state
  // and display agree even if activate() doesn't broadcast.
  rExportSize.activate(0);

  // Exports are meaningless before the first buffer — locked until a
  // format is chosen (unlocked in artworkFormat()).
  controllerLocked("saveTiff", true);
  controllerLocked("savePdf",  true);
  controllerLocked("saveSvg",  true);
  controllerLocked("saveAll",  true);
}


/// ---- RADIO CALLBACKS ---- ///

// Artwork format selected — rebuilds the art buffer at the new aspect.
// Export unlocking is handled generically by updateExportLockState(),
// called every frame from MainScreen.draw() — not here.
void artworkFormat(int a) {
  // Clicking an already-selected radio item returns -1; ignore it
  if (a == -1) return;
  if (dataLoading) return; // radio is locked while loading, but guard regardless

  if ((a - 1 != formatSelect) || !bufferCreated) {
    formatSelect = a - 1;
    createArtBuffer();
    layoutSampleObjects(); // TEMPLATE: real programs recompute layout here
    markArtDirty();
  }
}

// Locks/unlocks the format radio's individual items — used to prevent
// choosing a format (and so creating a buffer) before data has finished
// loading. Called every frame from MainScreen.draw(); only acts on actual
// transitions, mirroring updateExportLockState()'s guard below.
boolean formatRadioLocked = false; // matches the initial unlocked state set in initMainControls()

void setFormatRadioLocked(boolean locked) {
  if (rFormat == null || locked == formatRadioLocked) return;

  for (Toggle t : rFormat.getItems()) {
    t.setLock(locked);
    t.setColorBackground(locked ? color(200) : cGrey);
    t.setColorForeground(locked ? color(200) : cTheme);
    t.setColorActive(locked ? color(200) : cTheme);
  }
  formatRadioLocked = locked;
}

// Exports are only meaningful once a buffer exists AND data has finished
// loading — recomputed every frame from MainScreen.draw() rather than
// once in artworkFormat(), so the lock state is correct regardless of
// whether a format gets chosen before or after loading completes.
boolean exportsLocked = true; // matches the initial locked state set in initMainControls()

void updateExportLockState() {
  boolean shouldLock = !(bufferCreated && !dataLoading);
  if (shouldLock == exportsLocked) return;

  controllerLocked("saveTiff", shouldLock);
  controllerLocked("savePdf",  shouldLock);
  controllerLocked("saveSvg",  shouldLock);
  controllerLocked("saveAll",  shouldLock);
  exportsLocked = shouldLock;
}

// Export size selected — stored only; used at export time
void exportSize(int a) {
  if (a == -1) return;
  exportSizeSelect = a - 1;
}


/// ---- CENTRAL EVENT DISPATCHER ---- ///

void controlEvent(ControlEvent theEvent) {

  // Radio groups are handled by their named callbacks above; the group
  // event itself has no single controller, so bail out early.
  if (rFormat     != null && theEvent.isFrom(rFormat))     return;
  if (rExportSize != null && theEvent.isFrom(rExportSize)) return;

  // Pop-out "Hide Panel" bang — sync the main toggle
  if (theEvent.isFrom("hidePanel")) {
    cp5.get(Toggle.class, "showObjects").setValue(false);
    return;
  }

  Controller c = theEvent.getController();
  if (c == null) return;
  String name = c.getName();
  if (name == null) return;

  // Per-object visibility toggles from the pop-out window
  if (name.startsWith("objToggle_")) {
    int id = c.getId();
    if (id >= 0 && id < sampleObjects.size()) {
      sampleObjects.get(id).visible = (c.getValue() == 1.0);
      markArtDirty();
    }
    return;
  }

  // Controls that change the artwork — mark the buffer dirty (debounced).
  // TEMPLATE: add your artwork-affecting controller names here.
  if (name.equals("squareSize")  || name.equals("crossSize") ||
      name.equals("crossWeight") || name.equals("showSquares") ||
      name.equals("showCrosses")) {
    markArtDirty();
  }

  // NOTE: "imScale" is deliberately absent — zoom is handled by
  // drawPreview() scaling the blit and never re-renders the buffer.
}


/// ---- BANG / TOGGLE CALLBACKS ---- ///

void regenerate() {
  layoutSampleObjects();
  markArtDirty();
}

void confirm() {
  dataValidationError = null;
  if (!validateDataFolder()) return; // stay on intro screen; error shown by IntroScreen.draw()
  setScreen(SCREEN_MAIN);
}

// Intro text field callback — fires on Enter. Sanitises the label for
// filename safety, persists it, and reflects the cleaned value back into
// the field so the user sees exactly what will be used.
public void participantLabel(String val) {
  fileNameAppend = sanitiseLabel(val);
  saveParticipantLabel();
  cp5.get(Textfield.class, "participantLabel").setText(fileNameAppend);
  // Dismiss the debug field and reset the flag so P can reopen it
  showController("participantLabel", false);
  if (currentScreen instanceof IntroScreen) {
    ((IntroScreen) currentScreen).labelFieldVisible = false;
  }
  // Keep the main-screen readout in sync if it was already built
  Textlabel rl = cp5.get(Textlabel.class, "participantReadout");
  if (rl != null) rl.setText("PARTICIPANT LABEL: " + fileNameAppend);
}

// Pop-out window — created lazily on first click (child sketches launched
// at startup cause peer/threading errors). MainScreen.draw() polls
// isReady() before making it visible.
ObjectListFrame objFrame;
boolean objFramePendingShow = false;

public void showObjects(boolean val) {
  objFramePendingShow = val;
  if (val && objFrame == null) {
    objFrame = new ObjectListFrame(this, "Objects");
  }
  if (objFrame != null && objFrame.isReady()) {
    objFrame.getSurface().setVisible(val);
  }
}
