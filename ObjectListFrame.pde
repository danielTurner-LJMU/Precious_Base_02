/**
 * ObjectListFrame.pde   (reusable shell)
 *
 * A generic pop-out window: undecorated child sketch with a custom-drawn
 * draggable title bar, a vertical scrollbar + mouse-wheel scrolling, All
 * ON/OFF bangs, a Hide button, and one visibility toggle per object in
 * sampleObjects. Toggle events are plugged to the PARENT sketch and routed
 * by controlEvent() via the "objToggle_<index>" naming convention.
 *
 * DRAG-TO-TOGGLE: clicking one toggle and dragging sets every toggle swept
 * over to the same state as the first one clicked — avoids clicking each
 * toggle individually when bulk-toggling a run of items.
 *
 * Created lazily on first click of the Show/Hide Objects toggle — child
 * sketches launched at startup cause peer/threading errors.
 *
 * This is the genericised descendant of the Advertisers ControlFrame; the
 * tabbed FilterFrame variant follows the same skeleton (tabs + per-tab
 * scroll offsets) and can be ported on top of this when needed.
 */

class ObjectListFrame extends PApplet {

  ControlP5 cp5;
  PApplet parent;
  boolean ready = false;

  String panelTitle;

  // Draggable title bar
  int dragBarHeight = 30;
  int windowDragOffsetX, windowDragOffsetY;
  boolean windowDragging = false;
  float windowTargetX, windowTargetY;
  float windowCurrentX, windowCurrentY;

  int totalToggles;
  int toggleHeight = 25;
  int toggleStartY;
  int visibleHeight;

  // Scrollbar
  float scrollOffset = 0;
  float scrollTrackX;
  float scrollTrackY;
  float scrollTrackHeight;
  float scrollThumbY;
  float scrollThumbHeight = 40;
  boolean draggingThumb = false;
  float thumbDragOffsetY = 0;
  boolean thumbHovered = false;

  // Drag-to-toggle — tracks the state set by the first toggle clicked so
  // all subsequent toggles swept over during the drag are set to match.
  boolean dragTogglingActive = false;
  boolean dragToggleTargetState = false;


  ObjectListFrame(PApplet _parent, String name) {
    super();
    parent = _parent;
    panelTitle = name;
    totalToggles = sampleObjects.size();
    PApplet.runSketch(new String[]{ name }, this);
  }

  public void settings() {
    size(400, 800);
  }

  public void setup() {
    cp5 = new ControlP5(this);
    noLoop(); // pause render thread until window decoration is complete

    toggleStartY      = dragBarHeight + 75;
    visibleHeight     = height - toggleStartY - 20;
    scrollTrackX      = width - 30;
    scrollTrackY      = toggleStartY;
    scrollTrackHeight = visibleHeight;
    scrollThumbY      = scrollTrackY;

    // Remove window decorations on the AWT thread. noLoop() above ensures
    // the render thread won't try to draw until loop() is called at the
    // end — eliminating the "valid peer" race condition.
    javax.swing.SwingUtilities.invokeLater(() -> {
      java.awt.Frame frame = (java.awt.Frame) javax.swing.SwingUtilities
        .getWindowAncestor((java.awt.Component) surface.getNative());
      if (frame != null) {
        frame.dispose();
        frame.setUndecorated(true);
        frame.setSize(frame.getWidth(), Math.max(frame.getHeight() - 30, 100));
        frame.setVisible(false);
      }
      loop();
    });

    cp5.addBang("setAllOn")
      .setPosition(20, dragBarHeight + 10)
      .setSize(40, 20)
      .setLabel("All ON")
      .plugTo(this)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);

    cp5.addBang("setAllOff")
      .setPosition(80, dragBarHeight + 10)
      .setSize(40, 20)
      .setLabel("All OFF")
      .plugTo(this)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);

    // Plugged to PARENT — handled in the main sketch's controlEvent()
    cp5.addBang("hidePanel")
      .setPosition(width - 90, dragBarHeight + 10)
      .setSize(40, 20)
      .setLabel("Hide Panel")
      .setTriggerEvent(Bang.RELEASE)
      .plugTo(parent)
      .setColorForeground(cGrey)
      .setColorActive(cTheme);

    // One toggle per object — id carries the sampleObjects index so the
    // parent's controlEvent() can route directly to the object.
    for (int i = 0; i < totalToggles; i++) {
      SampleObject o = sampleObjects.get(i);

      Toggle t = cp5.addToggle("objToggle_" + i)
        .setPosition(20, toggleStartY + i * toggleHeight)
        .setId(i)
        .setSize(40, 20)
        .setLabel(o.name)
        .plugTo(parent)
        .setBroadcast(false)
        .setValue(o.visible)
        .setBroadcast(true)
        .setColorBackground(cGrey)
        .setColorActive(cTheme)
        .setColorForeground(cWhite);

      t.getCaptionLabel().setVisible(true);
      t.getCaptionLabel().getStyle().marginTop = -20;
      t.getCaptionLabel().getStyle().marginLeft = 45;
    }

    ready = true;
  }

  public boolean isReady() {
    return ready;
  }

  public void draw() {
    if (!ready) return;

    noStroke();
    fill(cBlack);
    rect(0, 0, width, height + 20);

    // Title bar
    fill(cTheme);
    rect(0, 0, width, dragBarHeight);
    fill(cBlack);
    textAlign(LEFT, CENTER);
    textSize(14);
    text(panelTitle, 10, dragBarHeight / 2);

    // Scrollbar
    thumbHovered = mouseX > scrollTrackX && mouseX < scrollTrackX + 10 &&
                   mouseY > scrollThumbY && mouseY < scrollThumbY + scrollThumbHeight;

    fill(cGrey);
    rect(scrollTrackX, scrollTrackY, 10, scrollTrackHeight);
    stroke(cWhite);
    fill((thumbHovered || draggingThumb) ? cTheme : cBlack);
    rect(scrollTrackX, scrollThumbY, 10, scrollThumbHeight);

    // Smooth window dragging via the emulated title bar
    if (windowDragging) {
      windowCurrentX = lerp(windowCurrentX, windowTargetX, 0.3);
      windowCurrentY = lerp(windowCurrentY, windowTargetY, 0.3);
      java.awt.Window win = javax.swing.SwingUtilities
        .getWindowAncestor((java.awt.Component) surface.getNative());
      if (win != null) {
        win.setLocation(Math.round(windowCurrentX), Math.round(windowCurrentY));
      }
    }

    // Position toggles against the scroll offset; hide any outside the list area
    for (int i = 0; i < totalToggles; i++) {
      Toggle t = cp5.get(Toggle.class, "objToggle_" + i);
      if (t != null) {
        float y = toggleStartY + i * toggleHeight - scrollOffset;
        t.setVisible(y >= toggleStartY && y < toggleStartY + visibleHeight);
        t.setPosition(20, y);
      }
    }
  }

  float maxScroll() {
    return max(0, totalToggles * toggleHeight - visibleHeight);
  }

  // Returns the list index (0-based) of the toggle whose row contains the
  // given y coordinate, accounting for scroll. Returns -1 if outside the
  // toggle area or over the scrollbar.
  int toggleIndexAtY(float y) {
    if (y < toggleStartY || mouseX > scrollTrackX) return -1;
    int idx = (int)((y + scrollOffset - toggleStartY) / toggleHeight);
    if (idx >= 0 && idx < totalToggles) return idx;
    return -1;
  }

  public void mousePressed() {
    // Title bar drag
    if (mouseY < dragBarHeight) {
      windowDragging = true;
      java.awt.Component comp = (java.awt.Component) surface.getNative();
      java.awt.Window win = javax.swing.SwingUtilities.getWindowAncestor(comp);
      if (win != null) {
        java.awt.Point windowPos = comp.getLocationOnScreen();
        windowDragOffsetX = (windowPos.x + mouseX) - win.getX();
        windowDragOffsetY = (windowPos.y + mouseY) - win.getY();
        windowCurrentX = win.getX();
        windowCurrentY = win.getY();
        windowTargetX = windowCurrentX;
        windowTargetY = windowCurrentY;
      }
    }

    // Scrollbar thumb drag
    if (thumbHovered) {
      draggingThumb = true;
      thumbDragOffsetY = mouseY - scrollThumbY;
    }

    // Drag-to-toggle — ControlP5 has already flipped the toggle on mouseDown,
    // so read its new state NOW as the target for the whole drag gesture.
    int idx = toggleIndexAtY(mouseY);
    if (idx >= 0) {
      Toggle t = cp5.get(Toggle.class, "objToggle_" + idx);
      if (t != null) {
        dragToggleTargetState = t.getBooleanValue();
        dragTogglingActive = true;
      }
    }
  }

  public void mouseReleased() {
    windowDragging   = false;
    draggingThumb    = false;
    dragTogglingActive = false;
  }

  public void mouseDragged() {
    // Window drag
    if (windowDragging) {
      java.awt.Component comp = (java.awt.Component) surface.getNative();
      java.awt.Window win = javax.swing.SwingUtilities.getWindowAncestor(comp);
      if (win != null) {
        java.awt.Point windowPos = comp.getLocationOnScreen();
        windowTargetX = (windowPos.x + mouseX) - windowDragOffsetX;
        windowTargetY = (windowPos.y + mouseY) - windowDragOffsetY;
      }
    }

    // Scrollbar thumb drag
    if (draggingThumb && maxScroll() > 0) {
      scrollThumbY = constrain(mouseY - thumbDragOffsetY,
        scrollTrackY, scrollTrackY + scrollTrackHeight - scrollThumbHeight);
      scrollOffset = map(scrollThumbY - scrollTrackY,
        0, scrollTrackHeight - scrollThumbHeight, 0, maxScroll());
    }

    // Drag-to-toggle — set any toggle the cursor moves over to the target
    // state established on mousePressed. Skips if the cursor is on the
    // scrollbar or outside the toggle area.
    if (dragTogglingActive && !draggingThumb && !windowDragging) {
      int idx = toggleIndexAtY(mouseY);
      if (idx >= 0) {
        Toggle t = cp5.get(Toggle.class, "objToggle_" + idx);
        if (t != null && t.getBooleanValue() != dragToggleTargetState) {
          t.setValue(dragToggleTargetState);
        }
      }
    }
  }

  public void mouseWheel(MouseEvent event) {
    if (maxScroll() <= 0) return;
    scrollOffset = constrain(scrollOffset + event.getCount() * 10, 0, maxScroll());
    scrollThumbY = map(scrollOffset, 0, maxScroll(),
      scrollTrackY, scrollTrackY + scrollTrackHeight - scrollThumbHeight);
  }

  public void setAllOn() {
    for (int i = 0; i < totalToggles; i++) {
      Toggle t = cp5.get(Toggle.class, "objToggle_" + i);
      if (t != null) t.setValue(true);
    }
  }

  public void setAllOff() {
    for (int i = 0; i < totalToggles; i++) {
      Toggle t = cp5.get(Toggle.class, "objToggle_" + i);
      if (t != null) t.setValue(false);
    }
  }
}
