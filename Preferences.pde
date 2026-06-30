/**
 * Preferences.pde   (reusable shell)
 *
 * Persists the selected Facebook data folder path between runs in a small
 * preferences file inside the sketch's data folder.
 *
 * In the template the path is stored and displayed but never parsed —
 * real programs read their data files from it in buildSampleObjects()'s
 * replacement (see SampleData.pde header).
 */

String prefFilePath  = "preciousPrefs.txt";
String labelFilePath = "participantLabel.txt"; // holds fileNameAppend between runs

String parentFolderPath;   // absolute path to the selected data folder
String folderName = "(none selected)"; // last path segment, for display

// Set by validateDataFolder() (per-program, see SampleData.pde) when the
// expected data isn't found at Confirm time. Read by IntroScreen.draw() —
// console output alone is useless in an exported, distributed application.
String dataValidationError = null;


// Loads stored settings: the data folder path and the participant label
void initPreferences() {

  loadParticipantLabel();

  File pref = new File(dataPath(prefFilePath));
  if (!pref.exists()) return;

  String[] prefs = loadStrings(dataPath(prefFilePath));
  if (prefs == null || prefs.length == 0 || prefs[0].trim().isEmpty()) return;

  parentFolderPath = prefs[0].trim();

  // File.getName() handles both / and \ separators (Windows-safe)
  folderName = new File(parentFolderPath).getName();

  if (currentScreen == SCREEN_INTRO) {
    showController("confirm", true);
  }
}

// Intro button callback — opens the system folder dialog
void selectDataPath() {
  selectFolder("Select a folder to process:", "folderSelected");
}

// Folder dialog callback
void folderSelected(File selection) {

  if (selection == null) {
    println("Window was closed or the user hit cancel.");
    return;
  }

  dataValidationError = null; // a fresh folder choice deserves a fresh attempt
  parentFolderPath = selection.getAbsolutePath();
  folderName = selection.getName();
  println("User selected " + parentFolderPath);

  // saveStrings creates or overwrites — no separate writer needed
  saveStrings(dataPath(prefFilePath), new String[]{ parentFolderPath });

  if (currentScreen == SCREEN_INTRO) {
    showController("confirm", true);
  }

  // Keep the main-screen folder label in sync if it exists already
  Textlabel t = cp5.get(Textlabel.class, "inputFolder");
  if (t != null) t.setText("FOLDER: " + folderName);
}


/// ---- PARTICIPANT LABEL ---- ///
// fileNameAppend (the trailing label on every export and colophon) is held
// in data/participantLabel.txt so switching participants never requires a
// code change or re-export of the application. It can be edited either by
// changing that file directly, or via the text field on the intro screen.

void loadParticipantLabel() {
  File f = new File(dataPath(labelFilePath));
  if (!f.exists()) {
    // First run — write the current default so the file exists and is
    // discoverable for hand-editing.
    saveParticipantLabel();
    return;
  }
  String[] lines = loadStrings(dataPath(labelFilePath));
  if (lines != null && lines.length > 0) {
    fileNameAppend = sanitiseLabel(lines[0]);
  }
  // Keep the intro text field in sync if it already exists
  Textfield tf = cp5.get(Textfield.class, "participantLabel");
  if (tf != null) tf.setText(fileNameAppend);
}

void saveParticipantLabel() {
  saveStrings(dataPath(labelFilePath), new String[]{ fileNameAppend });
}

// Labels end up in filenames and folder names, so strip the characters
// that are illegal on Windows/macOS and trim whitespace. Falls back to
// "test" rather than allowing an empty label.
String sanitiseLabel(String s) {
  if (s == null) return "test";
  s = s.trim().replaceAll("[\\\\/:*?\"<>|]", "-");
  return s.isEmpty() ? "test" : s;
}
