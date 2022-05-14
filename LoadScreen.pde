//import java.io.FileInputStream;


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

    hideUI();

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
      .setFont(defaultFont)
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
      ;
    w += 80 + 10;

    keepGeomBtn = cp5.addButton("keepgeombtn")
      .removeCallback()
      .setWidth(100)
      .setPosition(w, groupHeight/2f)
      .setLabel("Keep Geometry")
      .setGroup(loadGroup)
      .plugTo(this, "keepGeomFn")
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
      transport.postureName.setText(postures.getPosture(0).name);
      transport.animDuration.setValue(postures.getPosture(0).duration);
      transport.prevAnimDuration = postures.getPosture(0).duration;
      avatar.loadPosture(0);
      setPostureCollectionDirty();
    }

    // Update pivots and transforms
    for (ComplexShape cs : newAvatar.getPartsList()) {
      ComplexShape backCs = avatar.getShape().getById(cs.getId());
      if (backCs != null) {
        backCs.setLocalOrigin(cs.getLocalOrigin());
        backCs.setTransform(cs.getTransform());
      }
    }
    
    showUI();
    
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

    int textY = ceil((height + groupHeight)/2f + 48);
    if (keepGeomBtn.isInside()) {
      String s = "Keep current geometry and update transforms, pivot points and animations from this JSON file";
      float w = textWidth(s);
      text(s, (width-w)/2f, textY);
    }

    if (loadAllBtn.isInside()) {
      String s = "Load new file";
      float w = textWidth(s);
      text(s, (width-w)/2f, textY);
    }
  }
}
