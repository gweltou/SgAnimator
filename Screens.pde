public interface Screen {
  public void draw();
}



public class MainScreen implements Screen {

  public void draw() {
    float time = (float) millis() / 1000.0f;
    background(255);

    if (avatar != null) {
      renderer.pushMatrix(transform);
      if (playAnim)
        avatar.updateAnimation(time-lastTime);
      avatar.draw(renderer);
      avatar.drawSelectedOnly(renderer);

      if (showUI) {
        renderer.drawPivot();
        renderer.drawMarker(0, 0);
        renderer.drawAxes();
        if (selected != null) {
          if (!hardTransform.isIdt()) {
            renderer.pushMatrix(hardTransform);
            selected.setColorMod(1f, 1f, 1f, 0.4f);
            selected.draw(renderer);
            selected.setColorMod(1f, 1f, 1f, 1f);
            renderer.popMatrix();
          }
        } else {
          image(selectpart, partsList.getPosition()[0] + partsList.getWidth() + 4, partsList.getPosition()[1]);
        }
      }
      renderer.popMatrix();
      if (playAnim == false && (frameCount>>5)%2 == 0) {
        fill(255, 0, 0, 127);
        textSize(32);
        text("PAUSED", -60+width/2, height-80);
      }
      if (timeline != null) {
        timeline.highlightSliders();
      }

      if (setPivot) {
        fill(255, 0, 0);
        noStroke();
        ellipse(mouseX, mouseY, 8, 8);
      }

      if (mustUpdateUI == true && selected != null) {
        updateUI();
        mustUpdateUI = false;
      }
    } else {
      if (showUI)
        hideUI();
      
      fill(127);
      textSize(32);
      text("Press CTRL+o  to load a file", width/3, height/2);
      fill(63);
      textSize(20);
      text("'h' to show help", (width/2) - 80, 50 + height/2);
    }

    lastTime = time;
  }
}


public class HelpScreen1 implements Screen {
  public void draw() {
    if (showUI)
      hideUI();
    
    background(255);
    fill(0);
    textSize(20);
    text("CTRL+o\n"+
      "CTRL+s\n"+
      "Up/Down\n"+
      "p\n"+
      "r\n"+
      "d\n"+
      "h\n"+
      "right click\n"+
      "MAJ + right drag\n", width/4, height/4);
    text("Open file (svg or json)\n"+
      "Save json file\n"+
      "Select next/previous shape group\n"+
      "play/pause animation\n"+
      "reset animation\n"+
      "show/hide UI\n"+
      "help screen\n"+
      "place pivot\n"+
      "translate geometry\n", width/2, height/4);
    text("Ver. "+version, width-110, height-20);
  }
}


public class LoadScreen implements Screen {
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
      // Reset coordinates transformation matrix
      transform.setToTranslation(width/2, height/2);
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


  public void draw() {
    if (backgroundImage != null)
      image(backgroundImage, 0, 0);

    if (mustDestroy) {
      loadGroup.remove();
      currentScreen = screens[0];
    }
  }
}
