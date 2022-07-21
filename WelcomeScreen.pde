public class WelcomeScreen extends Screen {
  ComplexShape mill;
  float innerRadius;

  public WelcomeScreen() {
    int numWings = floor(random(8, 32));
    innerRadius = numWings * 4;
    float duration = 8f;
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
    TimeFunction translate = new TFConstant(innerRadius);
    wing.addAnimation(new Animation(translate, Animation.AXE_X));

    mill = new ComplexShape();
    for (int i=0; i<numWings; i++) {
      ComplexShape newWing = wing.copy();
      //newWing.setColorMod(random(0.9, 1.1), random(0.9, 1.1), random(0.9, 1.1), 1f);
      newWing.setColorMod(random(-0.1, 0.1), random(-0.1, 0.1), random(-0.1, 0.1), 1f);
      newWing.getAnimation(0).setParam("phase", r1*i*360/numWings);
      TimeFunction rotate = new TFConstant((float) i/numWings);
      newWing.addAnimation(new Animation(rotate, Animation.AXE_ROT));
      mill.addShape(newWing);
    }

    TimeFunction spin = new TFSpin(0f, duration * random(3f, 4f), 1f);
    mill.addAnimation(new Animation(spin, Animation.AXE_ROT));
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
    mill.update(1f/frameRate);
    mill.draw(renderer);
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
    text("Ver. " + version, width-80, height-40);
    text("Lib. " + PRenderer.version(), width-80, height-20);
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
    }
    else if (key == 'h') {
      // Help screens
      currentScreen = helpScreen1;
    }
  }
}
