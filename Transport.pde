public class Transport {
  Group group;
  Textfield postureName;
  Button prevPostureButton;
  Button nextPostureButton;
  ButtonRec buttonRec;
  Numberbox animDuration;
  Textlabel frameCounter;
  
  public int frameNumber = 0;
  private int barHeight = 10;
  private int height = 20;
  private int width;
  private int spacing = 2;
  private int textfieldWidth = 100;
  private int buttonSize = 24;
  private int x = 200;
  private int y = margin + barHeight;
  private float prevAnimDuration = 0f;


  public Transport() {
    group = cp5.addGroup("transportgroup")
      .setBarHeight(barHeight)
      .setBackgroundHeight(height + 1)
      .setBackgroundColor(backgroundColor)
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
    prevPostureButton.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_CLICK) {
          if (postureIndex <= 0)
            return;
          if (animationCollectionDirty) {
            // Save fullAnimation to animationCollection
            savePosture();
          }
          postureIndex--;
          Posture prevPosture = postures.getPosture(postureIndex);
          avatar.loadPosture(prevPosture);
          postureName.setText(prevPosture.name);
          animDuration.setValue(prevPosture.duration);
          prevAnimDuration = prevPosture.duration;
          mustUpdateUI = true;
        }
      }
    });
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
    nextPostureButton.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_CLICK) {
          if (animationCollectionDirty) {
            // Save posture to animationCollection
            savePosture();
          }
          postureIndex++;
          if (postureIndex >= postures.size()) {
            postureIndex = postures.size();
            avatar.clearAnimation();
            postureName.setText("posture" + postureIndex);
            animDuration.setValue(0f);
            prevAnimDuration = 0f;
          } else {
            Posture nextPosture = postures.getPosture(postureIndex);
            avatar.loadPosture(nextPosture);
            postureName.setText(nextPosture.name);
            animDuration.setValue(nextPosture.duration);
            prevAnimDuration = nextPosture.duration;
          }
          mustUpdateUI = true;
        }
      }
    });
    pos.add(buttonSize + 2*spacing, 0);
    

    animDuration = new NumberboxInput(cp5, "animduration")
      .setPosition(pos.x, pos.y)
      .setSize(40, height)
      .setGroup(group);
    animDuration.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_BROADCAST && animDuration.getValue() != prevAnimDuration) {
          animationCollectionDirty = true;
        }
      }
    });
    pos.add(animDuration.getWidth(), 0);
    
    
    frameCounter = cp5.addTextlabel("framecounter")
      .setLabel("counter")
      .setText(String.valueOf(frameNumber))
      .setPosition(pos.x, pos.y)
      .setSize(30, height)
      .setFont(defaultFont)
      .setColor(color(255, 255, 255))
      .setGroup(group)
      ;
    pos.add(30 + spacing, 0);


    //cp5.addButton("resetcounter")
    new Button(cp5, "resetcounter")
      .setLabel("Rst")
      .setSize(buttonSize, height)
      .setPosition(pos.x, pos.y)
      .setGroup(group)
      .plugTo(this, "resetCounter")
      ;
    pos.add(buttonSize + spacing, 0);
    
    
    buttonRec = new ButtonRec(cp5, "buttonrec", pos);
    buttonRec.setGroup(group);
    pos.add(buttonSize, 0);


    width = (int) pos.x;
    group.setWidth(width);
    hide();
  }
  
  
  public void increaseCounter() {
    frameCounter.setText(String.valueOf(++frameNumber));
  }
  
  public int getCounter() {
    return frameNumber;
  }
  
  public void resetCounter() {
    frameNumber = 0;
    frameCounter.setText("0");
  }
  
  
  public boolean contains(int x, int y) {
    return (x >= this.x && x <= this.x+width && y >= this.y-barHeight && y <= this.y);
  }
  
  
  public void move(int dx, int dy) {
    group.open();
    x += dx;
    y += dy;
    x = max(1, min(sketchWidth() - group.getWidth() - 1, x));
    y = max(barHeight + 2, min(sketchHeight() - height - 1, y));
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
        mainScreen.stopRecording();
      } else {
        mainScreen.startRecording();
      }
    }
  }
}
