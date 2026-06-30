/**
 * Screens.pde
 *
 * Screen-object state machine. Each application phase is a class implementing
 * the Screen interface, owning its own draw and interaction logic. Replaces
 * switch-based setupN()/drawN()/cleanupN() dispatch — adding a screen means
 * adding a class, with no edits to the main tab and no state checks leaking
 * into mousePressed()/keyPressed().
 *
 * Transitions: setScreen(SCREEN_MAIN) calls exit() on the old screen and
 * enter() on the new one.
 */

interface Screen {
  void enter();                       // called when this screen becomes active
  void exit();                        // called when leaving this screen
  void draw();                        // called every frame while active
  default void mousePressed()  {}
  default void mouseReleased() {}
  default void keyPressed()    {}
}

Screen currentScreen;
Screen SCREEN_INTRO = new IntroScreen();
Screen SCREEN_MAIN  = new MainScreen();

void setScreen(Screen next) {
  if (currentScreen != null) currentScreen.exit();
  currentScreen = next;
  currentScreen.enter();
}


/// ---- INTRO SCREEN — title + data folder selection ---- ///

float canvasCenterX, canvasCenterY;

class IntroScreen implements Screen {

  boolean built = false;          // controllers are created once, then shown/hidden
  boolean labelFieldVisible = false; // toggled by P key
  boolean pendingLabelFocus = false; // set focus on the NEXT frame to avoid 'p' being typed

  public void enter() {
    resizeCanvas(800, 800);
    canvasCenterX = width / 2.0;
    canvasCenterY = height / 2.0;

    if (!built) {
      initIntroControls();
      built = true;
    } else {
      showController("selectDataPath", true);
      if (parentFolderPath != null) showController("confirm", true);
    }

    initPreferences();
  }

  public void exit() {
    showController("confirm", false);
    showController("selectDataPath", false);
    showController("participantLabel", false); // always hide debug field on exit
  }

  public void draw() {
    if (pendingLabelFocus) {
      cp5.get(Textfield.class, "participantLabel").setFocus(true);
      pendingLabelFocus = false;
    }

    background(cTheme);

    textAlign(CENTER);
    rectMode(CENTER);

    noFill();
    stroke(cBlack);
    strokeWeight(20);
    rect(canvasCenterX, canvasCenterY, width, height);

    textFont(headerFont);
    textSize(24);
    fill(cBlack);
    text("P R E C I O U S", canvasCenterX, canvasCenterY);

    textFont(labelFont14);
    textSize(14);
    text(title, canvasCenterX, canvasCenterY + 15);

    textFont(subFont);
    if (parentFolderPath == null) {
      textSize(18);
      text("Please Select Facebook Data Folder", canvasCenterX, 580);
    } else {
      textSize(14);
      text("Facebook data folder selected:", canvasCenterX, 590);
      textSize(18);
      text(folderName, canvasCenterX, 610);
    }

    // Validation error — set by validateDataFolder() (per-program) when
    // Confirm is pressed and the expected data isn't found. A dedicated
    // warning colour, distinct from the artwork palette, since this is a
    // utility screen rather than the artwork itself. Sits between the
    // title and the Select Data Folder button (which starts at y 500).
    if (dataValidationError != null) {
      textFont(labelFontMono);
      textSize(13);
      fill(cWarning);
      text(dataValidationError, canvasCenterX, 460);
    }

    // Participant label — plain text, bottom of screen.
    // Dimmed when the edit field is open so the field reads as the active state.
    textFont(labelFontMono);
    textSize(13);
    fill(labelFieldVisible ? color(80) : cBlack);
    text("PARTICIPANT LABEL:  " + fileNameAppend, canvasCenterX, height - 40);
  }

  public void keyPressed() {
    if ((key == 'p' || key == 'P') && !labelFieldVisible) {
      labelFieldVisible = true;
      showController("participantLabel", true);
      cp5.get(Textfield.class, "participantLabel").setText(fileNameAppend);
      // Focus is set in draw() on the next frame — setting it here causes
      // the triggering 'p' keystroke to be appended to the field contents.
      pendingLabelFocus = true;
    }
    if (key == ESC && labelFieldVisible) {
      // Cancel edit — restore original value and hide
      cp5.get(Textfield.class, "participantLabel").setText(fileNameAppend);
      showController("participantLabel", false);
      labelFieldVisible = false;
      key = 0; // consume Esc so it doesn't close the sketch
    }
  }
}


/// ---- MAIN SCREEN — controls, preview, export ---- ///

class MainScreen implements Screen {

  boolean built = false;

  public void enter() {
    resizeCanvas(1500, 1000);

    // TEMPLATE: real programs load + parse data files here using
    // parentFolderPath, setting dataLoading = true first if the load is
    // slow enough to need spreading across frames (see Render.pde's DATA
    // LOADING section and SampleData.pde's stepDataLoad()). The template
    // just builds placeholder objects, which load instantly.
    buildSampleObjects();
  }

  public void exit() {}

  public void draw() {
    background(0);

    // GUI is built immediately so the controls panel is visible even while
    // a slow data load is still running — only the readouts that depend
    // on the load's result update later, once the per-program code does so.
    if (!built) {
      initMainControls();
      built = true;
    }

    // Format and exports stay locked until data is ready — otherwise a
    // buffer could be created (and exported) against incomplete data.
    setFormatRadioLocked(dataLoading);
    updateExportLockState();

    if (dataLoading) {
      stepDataLoad(25); // ms budget per frame — see Render.pde
    } else if (bufferCreated) {
      handleBufferRedraw();  // debounced re-render of the art buffer
      drawPreview();         // pan/zoom blit of buffer to the stage
      handleNotices();       // RENDERING / EXPORTING notices on top
      handleExport();        // deferred export with frame delay
      handleHover();         // rollover detection in the preview area
      drawHoverTooltip();
    } else {
      // No buffer yet — prompt the user to choose a format
      float px = ((width - guiWidth) / 2.0) + guiWidth;
      float py = height / 2.0;
      textFont(labelFontMono);
      textSize(18);
      textAlign(CENTER, CENTER);
      fill(cGrey);
      text("SELECT AN ARTWORK FORMAT TO BEGIN", px, py);
    }

    // GUI column background — drawn after preview so artwork never overlaps it
    noStroke();
    fill(cBlack);
    rectMode(CORNER);
    rect(0, 0, guiWidth, height);

    drawOverlays();

    // Loading notice — drawn after the GUI panel so it sits cleanly within
    // the preview area, not under it.
    if (dataLoading) drawLoadingNotice();

    // Lazy pop-out visibility — on first click the child frame isn't ready
    // yet, so poll until isReady(), then show it.
    if (objFrame != null && objFrame.isReady() && objFramePendingShow) {
      objFrame.getSurface().setVisible(true);
      objFramePendingShow = false;
    }

    // Screenshots.pde — must run LAST so save() captures the fully-drawn frame
    handleScreenshot();
  }

  public void mousePressed() {
    // Begin dragging the preview when pressing inside the preview area
    if (mouseX > guiWidth && mouseX < width && mouseY > 0 && mouseY < height) {
      dragEnabled = true;
      dragStartLoc = new PVector(mouseX - dragOffsetX, mouseY - dragOffsetY);
    }
  }

  public void mouseReleased() {
    dragEnabled = false;
  }

  public void keyPressed() {
    handleScreenshotKey(); // Screenshots.pde — F12 opens the note prompt
  }
}
