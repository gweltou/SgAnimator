public class LoadScreen extends Screen {
  private PImage backgroundImage;
  Group loadGroup;
  Toggle geomToggle, animToggle;
  Button loadAllBtn, keepGeomBtn;
  int groupWidth = 2*24 + 80 + 100 + 60 + 2*10;
  int groupHeight = 90;
  String filename;
  File selection;
  boolean mustDestroy = false;

  public LoadScreen() {
    doBackground();
  }

  public void createModalBox(File selection) {
    this.selection = selection;
    filename = selection.getAbsolutePath();

    mainScreen.hideUI();

    paramLocked = true;
    loadGroup = new Group(cp5, "loadfilegroup")
      .setWidth(groupWidth)
      .setBackgroundHeight(groupHeight)
      .setPosition((width/2)-(groupWidth/2), (height/2)-(groupHeight/2))
      .setBackgroundColor(color(0, 100))
      .hideBar()
      ;

    cp5.addTextlabel("filenamelabel")
      .setPosition(4, 10)
      .setFont(defaultFontSmall)
      .setText(selection.getName())
      .setGroup(loadGroup)
      ;

    int w = 24;
    loadAllBtn = cp5.addButton("loadallbtn")
      .removeCallback()
      .setWidth(80)
      .setPosition(w, groupHeight/2f)
      .setLabel("Load all")
      .setGroup(loadGroup)
      .plugTo(this, "loadAllFn")
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Load new file");
      }
    }
    )
    ;
    w += 80 + 10;

    keepGeomBtn = cp5.addButton("keepgeombtn")
      .removeCallback()
      .setWidth(100)
      .setPosition(w, groupHeight/2f)
      .setLabel("Keep Geometry")
      .setGroup(loadGroup)
      .plugTo(this, "keepGeomFn")
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Keep current geometry and update transforms, pivot points and animations from this JSON file");
      }
    }
    )
    ;
    w += 100 + 10;

    cp5.addButton("cancelbtn")
      .removeCallback()
      .setWidth(60)
      .setPosition(w, groupHeight/2f)
      .setLabel("Cancel")
      .setGroup(loadGroup)
      .plugTo(this, "cancelFn")
      ;
    paramLocked = false;

    fill(64);
    textSize(18);
  }


  public void doBackground() {
    backgroundImage = createImage(width, height, RGB);
    loadPixels();
    arrayCopy(pixels, backgroundImage.pixels);
    backgroundImage.updatePixels();
    backgroundImage.filter(GRAY);
    backgroundImage.filter(BLUR, 3);
  }


  public void loadAllFn() {
    loadJsonFile(selection);
    mustDestroy = true;
  }


  public void keepGeomFn() {
    Avatar newAvatar = Avatar.fromFile(selection);

    if (newAvatar == null) {
      println("Error while loading file");
      mustDestroy = true;
      return;
    }

    // postures are kept separated for simplicity
    // rather than storing and retrieving it from the Avatar class
    postureIndex = 0;
    if (newAvatar.postures != null) {
      postures = newAvatar.postures; // Creates problems if newAvatar has a different config than previous avatar
      avatar.postures = postures;
      mainScreen.transport.postureName.setText(postures.getPosture(0).name);
      mainScreen.transport.animDuration.setValue(postures.getPosture(0).duration);
      mainScreen.transport.prevAnimDuration = postures.getPosture(0).duration;
      avatar.loadPosture(0);
      setFileDirty();
    }

    // Update pivots and transforms
    for (ComplexShape cs : newAvatar.getPartsList()) {
      ComplexShape backCs = avatar.getShape().getById(cs.getId());
      if (backCs != null) {
        backCs.setLocalOrigin(cs.getLocalOrigin());
        backCs.setTransform(cs.getTransform());
      }
    }

    mainScreen.showUI();

    mustDestroy = true;
  }


  public void cancelFn() {
    mustDestroy = true;
  }


  @Override
    public void draw() {
    if (backgroundImage != null) {
      image(backgroundImage, 0, 0);
    } else {
      background(255);
    }

    if (mustDestroy) {
      loadGroup.remove();
      currentScreen = previousScreen;
    }
  }
}
