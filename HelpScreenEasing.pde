public class HelpScreenEasing extends Screen {
  private int frameWidth = 120;
  private int frameHeight = 90;
  private int spacing = 8;
  private int margin = width/8;
  private PGraphics[] frames;


  HelpScreenEasing() {
    frames = new PGraphics[Animation.interpolationNamesSimp.length];
    int i = 0;
    for (String interpolationName : Animation.interpolationNamesSimp) {
      Interpolation fn = Animation.getInterpolation(interpolationName);
      frames[i++] = createInterpolationFrame(frameWidth, frameHeight, fn, interpolationName);
    }
  }


  PGraphics createInterpolationFrame(int w, int h, Interpolation fn, String name) {
    PGraphics pg = createGraphics(w, h);
    pg.beginDraw();
    pg.background(#FFC500);
    float prev = h * fn.apply(0f);
    float val;
    float penX;
    float stepX = 2f;
    pg.stroke(0);
    for (penX=stepX; penX<w; penX+=stepX) {
      val = h * fn.apply(penX/w);
      pg.line(penX-stepX, h-prev, penX, h-val);
      prev = val;
    }
    val = h * fn.apply(1f);
    pg.line(penX-stepX, h-prev, w, h-val);
    pg.fill(0, 127);
    pg.text(name, w-textWidth(name)-4, h-4);
    pg.endDraw();
    return pg;
  }


  @Override
  public void draw() {
    background(255);
    fill(127);
    textSize(32);
    int offset = floor(textWidth("Easing functions"));
    text("Easing functions", (width/2)-offset/2, -20+height/6);

    int posX = margin;
    int posY = height/5;
    for (PGraphics frame : frames) {
      image(frame, posX, posY);
      posX += frameWidth + spacing;
      if (posX + frameWidth + spacing > width-margin) {
        posX = margin;
        posY += frameHeight + spacing;
      }
    }
  }


  @Override
  void keyPressed(KeyEvent event) {
    if (avatar != null)
      showUI();
    currentScreen = mainScreen;
  }
  
  @Override
  void mouseClicked(MouseEvent event) {
    if (avatar != null)
      showUI();
    currentScreen = mainScreen;
  }
}
