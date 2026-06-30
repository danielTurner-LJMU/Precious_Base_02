/**
 * Screenshots.pde   (reusable shell — should not need edits per program)
 *
 * F12 on the main screen opens a short text-field prompt — mirrors the
 * existing participantLabel pattern (enter to confirm, esc to cancel) —
 * for an optional note, then saves a PNG of the full sketch window
 * (controls and preview both) to screenshots/, named by date, time, the
 * program's window title and the note. These are working documentation
 * shots, not artwork exports, so the folder should be gitignored
 * per-program (screenshots/** in .gitignore).
 *
 * Wired in via three calls from MainScreen in Screens.pde:
 * handleScreenshotKey() from keyPressed(), handleScreenshot() from draw(),
 * and registerMethod("post", this) in GUI.pde's initGUI().
 */

String screenshotsFolder = "screenshots";

boolean screenshotFieldVisible = false;
boolean pendingScreenshotFocus = false;
String  pendingScreenshotNote  = "";
int     screenshotCaptureDelay = 0; // frames to wait so the overlay visibly closes first

// Called once per frame from MainScreen.draw() — focus handling only.
// The actual capture trigger lives in post() below, not here: ControlP5
// draws its own widgets via its own internal post-draw hook, so anything
// called from inside draw() — even as its last line — runs BEFORE the GUI
// controls are actually rendered for that frame.
void handleScreenshot() {
  if (pendingScreenshotFocus) {
    cp5.get(Textfield.class, "screenshotNote").setFocus(true);
    pendingScreenshotFocus = false;
  }
}

// Called from MainScreen.keyPressed()
void handleScreenshotKey() {
  if (key == CODED && keyCode == java.awt.event.KeyEvent.VK_F12 && !screenshotFieldVisible) {
    if (cp5.get(Textfield.class, "screenshotNote") == null) buildScreenshotField();

    screenshotFieldVisible = true;
    cp5.get(Textfield.class, "screenshotNote").setText("");
    showController("screenshotNote", true);
    pendingScreenshotFocus = true;
  }

  if (key == ESC && screenshotFieldVisible) {
    showController("screenshotNote", false);
    screenshotFieldVisible = false;
    key = 0; // consume Esc so it doesn't close the sketch
  }
}

// Lazily built on first F12 press — by then MainScreen is already sized,
// so its width/height are valid for centring the field over the preview.
void buildScreenshotField() {
  float fw = 360;
  float fx = guiWidth + ((width - guiWidth) - fw) / 2.0;
  float fy = height / 2.0;

  cp5.addTextfield("screenshotNote")
    .setPosition(fx, fy)
    .setSize((int) fw, 36)
    .setAutoClear(false)
    .setColor(cWhite)
    .setColorBackground(cBlack)
    .setColorForeground(cGrey)
    .setColorActive(cTheme)
    .setColorCursor(cWhite)
    .setColorLabel(cBlack)
    .hide()
    ;
  Textfield tf = cp5.get(Textfield.class, "screenshotNote");
  tf.getCaptionLabel()
    .setText("SCREENSHOT NOTE  (optional, enter to confirm, esc to cancel)")
    .setFont(cp5FontMono)
    .setSize(11)
    .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
    .setPaddingY(6);
}

// Textfield callback — fires on Enter
public void screenshotNote(String val) {
  showController("screenshotNote", false);
  screenshotFieldVisible = false;
  pendingScreenshotNote  = val;
  screenshotCaptureDelay = 2; // let the overlay finish disappearing before capture
}

// Registered as a Processing "post" hook in GUI.pde's initGUI(), AFTER
// ControlP5's own constructor — so this runs strictly after ControlP5's
// widget rendering for the frame, meaning save() here captures the GUI
// controls correctly, not just the panel background.
void post() {
  if (screenshotCaptureDelay > 0) {
    screenshotCaptureDelay--;
    if (screenshotCaptureDelay == 0) {
      captureScreenshot(pendingScreenshotNote);
    }
  }
}

void captureScreenshot(String note) {
  File dir = new File(sketchPath(screenshotsFolder));
  if (!dir.exists()) dir.mkdirs();

  java.text.SimpleDateFormat sdf = new java.text.SimpleDateFormat("yyyy-MM-dd - HH-mm-ss");
  String stamp = sdf.format(new java.util.Date());

  // Pulled from the window title global so the filename auto-updates per
  // program — no hardcoded program name to keep in sync.
  String cleanTitle = sanitiseForFilename(title);
  String clean       = sanitiseForFilename(note);

  String filename = stamp + " - " + cleanTitle + " - screenshot" +
                     (clean.length() > 0 ? " - " + clean : "") + ".png";

  String path = screenshotsFolder + "/" + filename;
  save(path);
  println("Screenshot saved: " + sketchPath(path));
}

String sanitiseForFilename(String s) {
  if (s == null) return "";
  s = s.replace(": ", " - "); // tidy "Precious: Base Template" -> "Precious - Base Template"
  return s.trim().replaceAll("[\\\\/:*?\"<>|]", "-");
}
