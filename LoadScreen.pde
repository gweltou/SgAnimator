public class LoadScreen extends Screen {
  private PImage backgroundImage;
  Group loadGroup;
  Toggle geomToggle, animToggle;
  int groupWidth = 180;
  int groupHeight = 180;
  String filename;
  File selection;
  boolean mustDestroy = false;

  public LoadScreen(File selection) {
    this.selection = selection;
    filename = selection.getAbsolutePath();

    doBackground();
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

    geomToggle = cp5.addToggle("loadgeometrytoggle")
      .setLabelVisible(false)
      .setPosition(groupWidth-56, 60)
      .setSize(20, 20)
      .setValue(1.0f)
      .setGroup(loadGroup)
      ;
    cp5.addTextlabel("loadgeometrylabel")
      .setPosition(32, 60 + 3)
      .setFont(defaultFont)
      .setText("Geometry")
      .setGroup(loadGroup)
      ;

    animToggle = cp5.addToggle("loadanimationtoggle")
      .setLabelVisible(false)
      .setPosition(groupWidth-56, 90)
      .setSize(20, 20)
      .setValue(1.0f)
      .setGroup(loadGroup)
      ;
    cp5.addTextlabel("loadanimationlabel")
      .setPosition(32, 90 + 3)
      .setFont(defaultFont)
      .setText("Animations")
      .setGroup(loadGroup)
      ;

    int okWidth = 50;
    cp5.addButton("loadokbutton")
      .removeCallback()
      .setWidth(okWidth)
      .setPosition((groupWidth/2)-(okWidth/2), groupHeight-34)
      .setLabel("Ok")
      .setGroup(loadGroup)
      .plugTo(this, "okFunction")
      ;
    paramLocked = false;
  }


  public void doBackground() {
    backgroundImage = createImage(width, height, RGB);
    loadPixels();
    arrayCopy(pixels, backgroundImage.pixels);
    backgroundImage.updatePixels();
    backgroundImage.filter(GRAY);
    backgroundImage.filter(BLUR, 3);
  }


  public void okFunction() {
    if (paramLocked == true)
      return;

    loadAvatarFile(selection);

    selectedIndex = 0;
    selected = null;
    partsName = new String[avatar.getPartsList().length];
    for (int i=0; i<partsName.length; i++) {
      partsName[i] = avatar.getPartsList()[i].getId();
    }
    partsList.setItems(partsName);
    baseFilename = filename.substring(0, filename.length()-5);
    showUI();

    mustDestroy = true;
  }


  private void loadAvatarFile(File file) {
    println("load avatar");
    JsonValue fromJson = null;
    try {
      InputStream in = new FileInputStream(file);
      fromJson = new JsonReader().parse(in);
    }
    catch (IOException e) {
      e.printStackTrace();
    }
    if (fromJson == null)
      return;

    // Load shape first
    if (fromJson.has("geometry") && geomToggle.getValue() == 1.0f) {
      JsonValue jsonGeometry = fromJson.get("geometry");
      avatar = new Avatar();
      avatar.setShape(ComplexShape.fromJson(jsonGeometry));
      mainScreen.resetView();
    }

    // AnimationCollection is kept separated for simplicity
    // rather than storing and retrieving it from the Avatar class
    fullAnimationIndex = 0;
    if (fromJson.has("animation") && animToggle.getValue() == 1.0f) {
      JsonValue jsonAnimation = fromJson.get("animation");
      animationCollection = AnimationCollection.fromJson(jsonAnimation);
      //avatar.setAnimationCollection(animationCollection));
      if (animationCollection.size() > 0) {
        avatar.setFullAnimation(animationCollection.getFullAnimation(fullAnimationIndex));
        animName.setText(animationCollection.getFullAnimationName(fullAnimationIndex));
      }
    } else {
      animationCollection = new AnimationCollection();
    }
  }


  @Override
  public void draw() {
    if (backgroundImage != null) {
      image(backgroundImage, 0, 0);
    } else  {
      background(255);
    }

    if (mustDestroy) {
      loadGroup.remove();
      currentScreen = mainScreen;
    }
  }
}