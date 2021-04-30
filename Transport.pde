Transport transport;


public class Transport extends MoveableGroup {
  Textfield postureName;
  Button prevPostureButton;
  Button nextPostureButton;
  ButtonRec buttonRec;
  Numberbox animDuration;
  Textlabel frameCounter;
  
  public int frameNumber = 0;
  private int textfieldWidth = 100;
  private int buttonSize = 24;
  private float prevAnimDuration = 0f;


  public Transport() {
    x = 200;
    y = margin + barHeight;
    barHeight = 10;
    groupHeight = 20;
    
    group = cp5.addGroup("transportgroup")
      .setBarHeight(barHeight)
      .setBackgroundHeight(groupHeight + 1)
      .setBackgroundColor(backgroundColor)
      .setCaptionLabel("transport")
      .setPosition(x, y)
      ;
    
    PVector pos = new PVector(0, 0);

    prevPostureButton = cp5.addButton("prevposture")
      .setLabel("<<")
      .setPosition(pos.x, pos.y)
      .setSize(buttonSize, groupHeight)
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
      .setSize(textfieldWidth, groupHeight)
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
      .setSize(buttonSize, groupHeight)
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
      .setSize(40, groupHeight)
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
      .setSize(30, groupHeight)
      .setFont(defaultFont)
      .setColor(color(255, 255, 255))
      .setGroup(group)
      ;
    pos.add(30 + spacing, 0);


    new Button(cp5, "resetcounter")
      .setLabel("Rst")
      .setSize(buttonSize, groupHeight)
      .setPosition(pos.x, pos.y)
      .setGroup(group)
      .plugTo(this, "resetCounter")
      ;
    pos.add(buttonSize + spacing, 0);
    
    
    buttonRec = new ButtonRec(cp5, "buttonrec", pos);
    buttonRec.setGroup(group);
    pos.add(buttonSize, 0);


    groupWidth = (int) pos.x;
    group.setWidth(groupWidth);
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
  
  
  private class ButtonRec extends Button {
    public ButtonRec(ControlP5 theControlP5, String theName, PVector position) {
      super(theControlP5, theName);
      setLabel("Rec");
      setSize(buttonSize, groupHeight);
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
