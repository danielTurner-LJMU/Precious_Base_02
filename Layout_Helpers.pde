/**
 * Layout_Helpers.pde
 *
 * Theme colours, fonts, controller styling, and the LAYOUT CURSOR —
 * a y-position that helper functions advance as they place controls.
 *
 * Building a control column becomes a vertical list of one-liners:
 *
 *   layoutStart(20, 20);
 *   header("CONTROLS");
 *   slider("squareSize", "SQUARE SIZE (MM)", 1, 40, squareSize);
 *   rowStart();
 *   toggleInRow("showSquares", "SHOW\nSQUARES");
 *   toggleInRow("showCrosses", "SHOW\nCROSSES");
 *   rowEnd(34);
 *
 * Reordering controls = reordering lines. Inserting a control shifts
 * everything below automatically. Spacing density = the gap variables.
 */

// ---- THEME ---- //
color cBlack    = #282829; // near-black background
color cTheme    = #FAEB9F; // theme yellow
color cGrey     = #AAC0C1; // soft grey-blue
color cWhite    = color(255);
color cWarning  = #B5474B; // utility-screen warnings only — never part of the artwork palette

// Sample artwork colours (template content only)
color cPink     = #F229AC;
color cDarkGrey = #3A3A3C;

// ---- FONTS ---- //
// The template uses safe built-in fonts; swap in your .vlw / .ttf files
// per program (see the Advertisers programs for loadFont/createFont usage).
PFont headerFont, subFont, labelFont14, labelFontMono;
ControlFont cp5FontMain, cp5FontMono;

// ---- CONTROL DIMENSIONS ---- //
int sButtonW = 150, sButtonH = 50;
int lButtonW = 250, lButtonH = 85;
int sliderWidth  = 350;
int sliderHeight = 19;

// ---- LAYOUT CURSOR ---- //
float luX, luY;        // current column x / running y
float luRowX;          // x cursor within a horizontal row
float rowGapY      =  8; // vertical gap after a slider — within a group
float sectionGapY = 12; // extra space before a section header
float colGapX     = 60; // default horizontal step inside a row

void layoutStart(float x, float y) {
  luX = x;
  luY = y;
}

void gap(float px) {
  luY += px;
}

// Section header label
void header(String text) {
  luY += sectionGapY;
  cp5.addTextlabel("hdr_" + text)
    .setText(text)
    .setPosition(luX, luY)
    .setColorValue(cGrey)
    .setFont(subFont)
    ;
  luY += 30;
}

// Plain info label (returns it so text can be updated later)
Textlabel infoLabel(String name, String text) {
  Textlabel t = cp5.addTextlabel(name)
    .setText(text)
    .setPosition(luX, luY)
    .setColorValue(cGrey)
    .setFont(cp5FontMono)
    ;
  luY += 22;
  return t;
}

// Standard slider — full width, styled, cursor advanced
Slider slider(String name, String label, float min, float max, float val) {
  Slider s = cp5.addSlider(name)
    .setLabel(label)
    .setPosition(luX, luY)
    .setSize(sliderWidth, sliderHeight)
    .setRange(min, max)
    .setValue(val)
    ;
  styleMain(name);
  luY += sliderHeight + rowGapY;
  return s;
}

// ---- HORIZONTAL ROWS ---- //
// rowStart() resets the row cursor; *InRow() helpers place controls left to
// right; rowEnd(clearance) advances the y cursor past the row.

void rowStart() {
  luRowX = luX;
}

void rowEnd(float clearance) {
  luY += clearance;
}

Toggle toggleInRow(String name, String label) {
  Toggle t = cp5.addToggle(name)
    .setLabel(label)
    .setPosition(luRowX, luY)
    .setSize(50, 20)
    ;
  styleMain(name);
  luRowX += colGapX;
  return t;
}

Bang bangInRow(String name, String label, int w, int h) {
  Bang b = cp5.addBang(name)
    .setLabel(label)
    .setPosition(luRowX, luY)
    .setSize(w, h)
    ;
  styleMain(name);
  luRowX += w + 10;
  return b;
}

Toggle bigToggleInRow(String name, String label, int w, int h) {
  Toggle t = cp5.addToggle(name)
    .setLabel(label)
    .setPosition(luRowX, luY)
    .setSize(w, h)
    ;
  styleMain(name);
  luRowX += w + 20;
  return t;
}

// Horizontal radio button group — items flow left to right, labels below
// Compact overload — uses default item size (40×20) and spacing (35px)
RadioButton radioRow(String name, String[] items) {
  return radioRow(name, items, 40, 20, 10);
}

// Full overload — pass item width, height, and column spacing explicitly.
// Example: radioRow("artworkFormat", FORMAT_LABELS, 70, 30, 20)
RadioButton radioRow(String name, String[] items, int itemW, int itemH, int colSpacing) {
  RadioButton r = cp5.addRadioButton(name)
    .setPosition(luX, luY)
    .setSize(itemW, itemH)
    .setItemsPerRow(items.length)
    .setSpacingColumn(colSpacing)
    .setColorBackground(cGrey)
    .setColorForeground(cTheme)
    .setColorActive(cTheme)
    .setColorLabel(cGrey)
    ;
  for (int i = 0; i < items.length; i++) {
    r.addItem(items[i], i + 1);
  }
  for (Toggle t : r.getItems()) {
    t.getCaptionLabel()
      .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
      .setPaddingY(5)
      .setFont(cp5FontMono);
  }
  luY += itemH + 30; // control height + label clearance
  return r;
}


/// ---- CONTROLLER STYLING ---- ///

void showController(String theControllerName, boolean show) {
  Controller c = cp5.getController(theControllerName);
  if (c == null) return;
  if (show) c.show();
  else      c.hide();
}

// Style settings for the main screen
void styleMain(String theControllerName) {
  Controller c = cp5.getController(theControllerName);

  c.setColorBackground(cGrey);
  c.setColorForeground(cWhite);
  c.setColorActive(cTheme);
  c.getCaptionLabel().setColor(cGrey);
  c.getCaptionLabel().setFont(cp5FontMono);
  c.getCaptionLabel().setSize(14);
  c.getValueLabel().setFont(cp5FontMono);
  c.getValueLabel().setColor(cBlack);
  c.getValueLabel().setSize(14);

  // Bangs read better with a grey resting state
  if (c instanceof Bang) c.setColorForeground(cGrey);
}

// Greyed-out style for locked controllers
void styleLocked(String theControllerName) {
  Controller c = cp5.getController(theControllerName);

  c.setColorBackground(color(200));
  c.setColorForeground(color(200));
  c.setColorActive(color(200));
  c.getCaptionLabel().setColor(color(200));
  c.getCaptionLabel().setFont(cp5FontMono);
  c.getCaptionLabel().setSize(14);
  c.getValueLabel().setFont(cp5FontMono);
  c.getValueLabel().setColor(color(200));
  c.getValueLabel().setSize(14);

  if (c instanceof Bang) c.setColorForeground(color(200));
}

void controllerLocked(String theControllerName, boolean locked) {
  Controller c = cp5.getController(theControllerName);
  c.setLock(locked);
  if (locked) styleLocked(theControllerName);
  else        styleMain(theControllerName);
}

// Style settings for the intro screen
void styleIntro(String theControllerName, String label) {
  Controller c = cp5.getController(theControllerName);

  c.setColorForeground(cGrey);
  c.setColorBackground(cBlack);
  c.setColorActive(cGrey);
  c.getCaptionLabel().toUpperCase(false);
  c.getCaptionLabel().setColor(cWhite);
  c.getCaptionLabel().setFont(cp5FontMain);
  c.getCaptionLabel().setSize(14);
  c.getValueLabel().setColor(cWhite);
  c.getValueLabel().setFont(cp5FontMain);
  c.getValueLabel().setSize(14);

  c.getCaptionLabel().setText(label);
}
