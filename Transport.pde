public class Transport {
  Group group;
  Textfield postureName;
  Button prevPostureButton;
  Button nextPostureButton;
  ButtonRec buttonRec;
  Numberbox animDuration;
  
  private int barHeight = 10;
  private int height = 20;
  private int spacing = 2;
  private int textfieldWidth = 100;
  private int buttonSize = 24;
  private int x = 200;
  private int y = margin + barHeight + 1;
  private int width;

  public Transport() {
    group = cp5.addGroup("transportgroup")
      .setBarHeight(barHeight)
      .setBackgroundHeight(height+3)
      .setBackgroundColor(color(0, 100))
      .setCaptionLabel("transport")
      .setPosition(x, y)
      ;
    
    PVector pos = new PVector(0, 0);

    prevPostureButton = cp5.addButton("prevposture")
      .setLabel("<<")
      .setPosition(pos.x, pos.y)
      .setSize(buttonSize, height)
      .setGroup(group)
      ;
    pos.add(buttonSize + spacing, 0);

    postureName = cp5.addTextfield("posturename")
      //.setLabelVisible(false) // Doesn't work
      .setLabel("")
      .setText("posture0")
      .setPosition(pos.x, pos.y)
      .setSize(textfieldWidth, height)
      .setFont(defaultFont)
      .setFocus(false)
      .setColor(color(255, 255, 255))
      .setAutoClear(false)
      .setGroup(group)
      ;
    pos.add(textfieldWidth + spacing, 0);

    nextPostureButton = cp5.addButton("nextposture")
      .setLabel(">>")
      .setPosition(pos.x, pos.y)
      .setSize(buttonSize, height)
      .setGroup(group)
      ;
    pos.add(buttonSize + 2*spacing, 0);

    buttonRec = new ButtonRec(cp5, "buttonrec", pos);
    buttonRec.setGroup(group);
    pos.add(buttonSize + spacing, 0);

    animDuration = new NumberboxInput(cp5, "animduration")
      .setPosition(pos.x, pos.y)
      .setSize(40, height)
      .setGroup(group);
    pos.add(animDuration.getWidth() + spacing, 0);

    width = (int) pos.x;
    group.setWidth(width);
    hide();
  }
  
  public boolean contains(int x, int y) {
    return (x >= this.x && x <= this.x+width && y >= this.y-barHeight && y <= this.y);
  }
  
  public void move(int dx, int dy) {
    x += dx;
    y += dy;
    group.setPosition(x, y);
  }
  
  public void setPosition(int x, int y) {
    this.x = x;
    this.y = y;
    group.setPosition(x, y);
  }

  public void show() {
    group.show();
  }

  public void hide() {
    group.hide();
  }

  private class ButtonRec extends Button {
    public ButtonRec(ControlP5 theControlP5, String theName, PVector position) {
      super(theControlP5, theName);
      setLabel("Rec");
      setSize(buttonSize, height);
      setPosition(position.x, position.y);
      setSwitch(true);
      setColorActive(color(255, 0, 0));
    }

    @Override
    public void mousePressed() {
      super.mousePressed();
      if (isOn()) {
        renderer.stopRecording();
      } else {
        renderer.startRecording();
        avatar.resetAnimation();
      }
    }
  }
}
