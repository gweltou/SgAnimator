public class Transport extends MoveableGroup {
  Textfield postureName;
  Button prevPostureButton;
  Button nextPostureButton;
  ButtonRec buttonRec;
  Numberbox animDuration;
  Textlabel frameCounter;
  Icon cameraToggle;
  Icon playToggle;

  public int frameNumber = 0;
  private int textfieldWidth = 100;
  private int buttonSize = 24;
  private float pAnimDuration = 0f;


  public Transport() {
    x = margin;
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
      .plugTo(this, "prevPosture")
      .setGroup(group)
      ;
    prevPostureButton.onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Load previous posture");
      }
    }
    );
    pos.add(buttonSize + spacing, 0);


    postureName = cp5.addTextfield("posturename")
      //.setLabelVisible(false) // Doesn't work
      .setLabel("")
      .setText("posture0")
      .setPosition(pos.x, pos.y)
      .setSize(textfieldWidth, groupHeight)
      .setFont(defaultFontSmall)
      .setFocus(false)
      .setColor(color(255, 255, 255))
      .setAutoClear(false)
      .setGroup(group)
      ;
    postureName.onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Change posture name");
      }
    }
    );
    pos.add(textfieldWidth + spacing, 0);


    nextPostureButton = cp5.addButton("nextposture")
      .setLabel(">>")
      .setPosition(pos.x, pos.y)
      .setSize(buttonSize, groupHeight)
      .plugTo(this, "nextPosture")
      .setGroup(group)
      ;
    nextPostureButton.onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Load next posture");
      }
    }
    );
    pos.add(buttonSize + 2*spacing, 0);


    animDuration = new NumberboxInput(cp5, "animduration")
      .setUnit(" s")
      .setPosition(pos.x, pos.y)
      .setSize(40, groupHeight)
      .setRange(0, 999)
      .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
      .setGroup(group)
      ;
    animDuration.addCallback(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        if (theEvent.getAction() == ControlP5.ACTION_BROADCAST && animDuration.getValue() != pAnimDuration) {
          setFileDirty();
        }
      }
    }
    );
    animDuration.onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Set this posture's total duration (in seconds)");
      }
    }
    );
    pos.add(animDuration.getWidth(), 0);


    frameCounter = cp5.addTextlabel("framecounter")
      .setLabel("counter")
      .setText(String.valueOf(frameNumber))
      .setPosition(pos.x, pos.y)
      .setSize(30, groupHeight)
      .setFont(defaultFontSmall)
      .setColor(color(255, 255, 255))
      .setGroup(group)
      ;
    frameCounter.onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Frame counter");
      }
    }
    );
    pos.add(30 + spacing, 0);


    new Button(cp5, "resetcounter")
      .setLabel("Rst")
      .setSize(buttonSize, groupHeight)
      .setPosition(pos.x, pos.y)
      .setGroup(group)
      .plugTo(this, "resetCounter")
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Reset frame counter");
      }
    }
    );
    pos.add(buttonSize + spacing, 0);


    buttonRec = new ButtonRec(cp5, "buttonrec", pos);
    buttonRec.setGroup(group);
    buttonRec.onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Record frames to disk");
      }
    }
    );
    pos.add(buttonSize + spacing, 0);


    cameraToggle = cp5.addIcon("cameratoggle", 0)
      .setPosition(pos.x, pos.y)
      .setSize(buttonSize, groupHeight)
      .setFont(iconFont)
      .setFontIcons(#00f030, #00f030)
      .setFontIconSize(18)
      .setSwitch(true)
      .showBackground()
      .setGroup(group)
      .plugTo(this, "onToggleCamera")
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Show / Hide camera (key 'k')");
      }
    }
    );
    pos.add(buttonSize + spacing, 0);


    playToggle = cp5.addIcon("playtoggle", 0)
      .setPosition(pos.x, pos.y)
      .setSize(buttonSize, groupHeight)
      .setFont(iconFont)
      .setFontIcons(#00f04b, #00f04d)
      .setFontIconSize(18)
      .setSwitch(true)
      .showBackground()
      .setGroup(group)
      .setOff()
      .plugTo(this, "onTogglePlay")
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Play / Pause animation (key 'p')");
      }
    }
    );
    pos.add(buttonSize, 0);


    groupWidth = (int) pos.x;
    group.setWidth(groupWidth);
    hide();
  }


  public void prevPosture() {
    if (postureIndex <= 0)
      return;
    if (fileDirty) {
      // Save fullAnimation to animationCollection
      savePosture();
    }
    postureIndex--;
    //Posture prevPosture = postures.getPosture(postureIndex);
    avatar.loadPosture(postureIndex);
    postureName.setText(avatar.getCurrentPosture().getName());
    animDuration.setValue(avatar.getCurrentPosture().getDuration());
    pAnimDuration = avatar.getCurrentPosture().getDuration();
    avatar.resetAnimation();
    mustUpdateUI = true;
  }

  public void nextPosture() {
    if (fileDirty) {
      // Save posture to postureCollection
      savePosture();
    }
    postureIndex++;
    if (postureIndex >= avatar.getPostures().size()) {
      postureIndex = avatar.getPostures().size();
      postureName.setText("posture" + postureIndex);
      animDuration.setValue(0f);
      pAnimDuration = 0f;
    } else {
      //Posture nextPosture = postures.getPosture(postureIndex);
      avatar.loadPosture(postureIndex);
      postureName.setText(avatar.getCurrentPosture().getName());
      animDuration.setValue(avatar.getCurrentPosture().getDuration());
      pAnimDuration = avatar.getCurrentPosture().getDuration();
      avatar.resetAnimation();
    }
    mustUpdateUI = true;
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

  public void onToggleCamera(boolean val) {
    if (val)
      mainScreen.camera.show();
    else
      mainScreen.camera.hide();
  }

  public void onTogglePlay(boolean val) {
    if (avatar != null) {
      avatar.resetAnimation();
      mainScreen.playing = val;
    }
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
        if (animDuration.getValue() > 0f) {
          mainScreen.startRecording();
        } else {
          tooltip.warn("Can't record. Choose the posture's duration first !");
          buttonRec.setOff();
        }
      }
    }
  }
}
