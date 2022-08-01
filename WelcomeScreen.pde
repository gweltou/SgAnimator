public class WelcomeScreen extends Screen {
  ComplexShape mill;
  PostureTree pt;
  Posture posture;
  float innerRadius;

  public WelcomeScreen() {
    int numWings = floor(random(12, 24));
    innerRadius = numWings * 3.2f;
    int r1 = floor(random(1, 7));
    float speed = 10f;
    float dur, mult, offset;

    // Single wing shape
    float[] verts = new float[] {0f, 10f, 100f, 18f, 106f, 6f, 110f, 0f, 106f, -6f, 100f, -18f, 0f, -10f};
    ComplexShape wing = new ComplexShape("wing");
    DrawablePolygon shape = new DrawablePolygon(verts);
    colorMode(HSB, 1f);
    color c = color(random(1f), 0.32f, 0.85f);
    shape.setColor(red(c), green(c), blue(c), 1f);
    colorMode(RGB, 255);
    wing.addShape(shape);
    wing.hardTranslate(innerRadius, 0f);
    wing.setLocalOrigin(new Vector2(0f, 0f));

    mill = new ComplexShape("mill");
    for (int i=0; i<numWings; i++) {
      ComplexShape newWing = wing.copy();
      mill.addShape(newWing);
    }
    pt = PostureTree.buildTree(mill);

    dur = speed * random(0.4f, 2f);
    mult = 0.25f;
    offset = map(numWings, 8, 32, 1, 1.5);
    float colDelta = 0.07;
    for (int i=0; i<numWings; i++) {
      ComplexShape cs = mill.getChildren().get(i);
      cs.setTint(random(-colDelta, colDelta), random(-colDelta, colDelta), random(-colDelta, colDelta), 1f);
      TimeFunction stretch = new TFSin(dur, mult, offset, (r1*i*360/numWings)-180);
      pt.findByShape(cs).getAnimations().add(new Animation(stretch, Animation.AXE_SX));
      TimeFunction rotate = new TFConstant((float) i/numWings);
      pt.findByShape(cs).getAnimations().add(new Animation(rotate, Animation.AXE_ROT));
    }
    TimeFunction spin = new TFSpin(0f, speed*random(2f, 4f), 1f);
    pt.getAnimations().add(new Animation(spin, Animation.AXE_ROT));
    posture = new Posture();
    posture.setPostureTree(pt);
  }

  @Override
    public void draw() {
    if (avatar != null) {
      currentScreen = mainScreen;
      mainScreen.showUI();
      return;
    }

    background(255);

    pushMatrix();
    translate(innerRadius*1.3, innerRadius*1.3);
    //translate(width/2, height);
    //scale(1.5);
    posture.update(1f/frameRate);
    mill.draw(renderer, pt);
    popMatrix();

    fill(127);
    textFont(titleFont);
    textSize(48);
    String s = "Press       +     to load a file";
    int margin = floor((width - textWidth(s)) * 0.5f);
    text(s, margin, height/2);
    drawKey(margin + 120, height/2 - 34, "Ctrl", 40);
    drawKey(margin + 224, height/2 - 34, "O", 40);

    fill(63);
    textFont(tooltipFont);
    text("to show help", (width/2) - 50, 60 + height/2);
    drawKey((width/2) - 90, 36 + height/2, "H", 32);

    textFont(defaultFontSmall);
    text("Ver. " + version, width-80, height-60);
    text("Lib. " + PRenderer.version(), width-80, height-40);
  }

  @Override
    void mouseClicked(MouseEvent event) {
    selectInput("Select a file", "inputFileSelected");
    //loadScreen = new LoadScreen();
  }

  @Override
    void keyPressed(KeyEvent event) {
    if (event.isControlDown() && event.getKeyCode() == 79) {
      // CTRL+o, load a new file
      selectInput("Select a file", "inputFileSelected");
    } else if (key == 'h') {
      // Help screens
      currentScreen = helpScreen1;
    }
  }
}
