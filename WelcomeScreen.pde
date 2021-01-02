public class WelcomeScreen extends Screen {
  ComplexShape mill;
  float innerRadius;

  public WelcomeScreen() {
    int numWings = floor(random(8, 32));
    innerRadius = numWings * 4;
    float duration = 4f;
    int r1 = floor(random(1, 12));

    // Single wing shape
    float[] verts = new float[] {0f, 10f, 100f, 18f, 106f, 6f, 110f, 0f, 106f, -6f, 100f, -18f, 0f, -10f};
    ComplexShape wing = new ComplexShape();
    DrawablePolygon shape = new DrawablePolygon(verts);
    colorMode(HSB, 1f);
    color c = color(random(1), 0.3f, 1f);
    shape.setColor(red(c), green(c), blue(c), 1f);
    colorMode(RGB, 255);
    wing.addShape(shape);
    TimeFunction stretch = new TFSin(duration*random(0.4f, 2f), 0.3f, map(numWings, 8, 32, 1, 1.5), 0f);
    wing.addAnimation(new Animation(stretch, Animation.AXE_SX));
    TimeFunction translate = new TFConstant(innerRadius, 1f);
    wing.addAnimation(new Animation(translate, Animation.AXE_X));

    mill = new ComplexShape();
    for (int i=0; i<numWings; i++) {
      ComplexShape newWing = wing.copy();
      newWing.setColorMod(random(0.9, 1.1), random(0.9, 1.1), random(0.9, 1.1), 1f);
      newWing.getAnimation(0).setParam("phase", r1*i*360/numWings);
      TimeFunction rotate = new TFConstant(i*360/numWings, 1f);
      newWing.addAnimation(new Animation(rotate, Animation.AXE_ROT));
      mill.addShape(newWing);
    }

    TimeFunction spin = new TFSpin(0f, duration*random(2.4f, 4f), 1f, 1);
    mill.addAnimation(new Animation(spin, Animation.AXE_ROT));
  }

  @Override
    public void draw() {
    if (avatar != null) {
      showUI();
      currentScreen = mainScreen;
      return;
    }

    background(255);
    
    pushMatrix();
    translate(innerRadius*1.3, innerRadius*1.3);
    //translate(width/2, height);
    //scale(1.5);
    mill.updateAnimation(1f/frameRate);
    mill.draw(renderer);
    popMatrix();
    
    fill(127);
    textSize(32);
    text("Press CTRL+o  to load a file", width/3, height/2);
    fill(63);
    textSize(20);
    text("'h' to show help", (width/2) - 80, 50 + height/2);
    text("Ver. "+version, width-110, height-20);
  }

  @Override
    void mouseClicked(MouseEvent event) {
    selectInput("Select a file", "fileSelected");
  }

  @Override
    void keyPressed(KeyEvent event) {
    switch (key) {
    case 'h':  // Help screens
      currentScreen = helpScreen1;
      break;
    case 15:  // CTRL+o, load a new file
      selectInput("Select a file", "fileSelected");
      break;
    }
  }
}
