import java.io.FileInputStream;


public class LoadScreen extends Screen {
  private PImage backgroundImage;
  Group loadGroup;
  Toggle geomToggle, animToggle;
  int groupWidth = 180;
  int groupHeight = 180;
  String filename;
  File selection;
  boolean mustDestroy = false;
  
  public LoadScreen() {
    doBackground();
  }

  public void setupUI(File selection) {
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
    partsList.setItems(avatar.getPartsNamePre());
    baseFilename = filename.substring(0, filename.length()-5);
    showUI();
    accordion.hide();

    mustDestroy = true;
  }


  private void loadAvatarFile(File file) {
    boolean loadGeom = geomToggle.getValue() == 1.0f;
    boolean loadAnim = animToggle.getValue() == 1.0f;
    
    Avatar newAvatar = Avatar.fromFile(file);
    if (newAvatar == null)
      return;
    
    if (loadGeom) {
      avatar = newAvatar;
      mainScreen.resetView();
    }
    
    // AnimationCollection is kept separated for simplicity
    // rather than storing and retrieving it from the Avatar class
    postureIndex = 0;
    if (loadAnim) {
      postures = newAvatar.postures;
      if (postures.size() > 0) {
        avatar.postures = postures;
        transport.postureName.setText(postures.getPosture(0).name);
        avatar.loadPosture(0);
      }
    } else {
      postures = new PostureCollection();
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
