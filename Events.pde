import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;


boolean axeSetFirst = false;  // Used when animation's axe is chosen before function
String axeSetFirstName;
boolean controllerClicked = false;


void controlEvent(ControlEvent event) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException {
  if (paramLocked)
    return;

  controllerClicked = true;

  if (event.isGroup() && timeline != null)
    timeline.remove();

  if (event.isController()) {
    String name = event.getName();
    float value = event.getValue();
    //println("event", event);
    
    if (name.equals("posturename")) {
      // Posture name has changed
      setFileDirty();
    } else if (name.startsWith("function")) {
      // Change the animations's function or add a new animation with the given function
      String[] m = match(name, "function(\\d+)");
      int animNum = parseInt(m[1]);
      Class<TimeFunction> tfclass = TimeFunction.functionClasses[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      ArrayList<Animation> animations = selectedPostureTree.getAnimations();
      if (animNum < animations.size()) {
        animations.get(animNum).setFunction(tf);
      } else {
        Animation newAnimation = new Animation(tf);
        if (axeSetFirst && parseInt(match(axeSetFirstName, "axe(\\d+)")[1]) == animNum) {
          int axeVal = (int) cp5.getController(axeSetFirstName).getValue();
          newAnimation.setAxe(axeVal);
        }
        animations.add(newAnimation);
      }
      //selected.reset();
      /*if (tf instanceof TFTimetable) {
       timeline = new Timeline(animNum);
       //timeline.setFunction((TFTimetable) tf);
       //timeline.show();
       }*/
      mustUpdateUI = true;
      mainScreen.playing = true;
      setFileDirty();
    } else if (name.startsWith("axe")) {
      String[] m = match(name, "axe(\\d+)");
      int animNum = parseInt(m[1]);
      // Should check if an function is set first
      if (animNum == selectedPostureTree.getAnimations().size()) {
        // No function set yet
        axeSetFirst = true;
        axeSetFirstName = name;
      } else {
        selectedPostureTree.getAnimations().get(animNum).setAxe((int) value);
        mustUpdateUI = true;
        mainScreen.playing = true;
        setFileDirty();
      }
    } else if (name.startsWith("animamp")) {
      String[] m = match(name, "animamp(\\d+)");
      int animNum = parseInt(m[1]);
      selectedPostureTree.getAnimations().get(animNum).setAmp(int(value*100f) / 100f);
      setFileDirty();
    } else if (name.startsWith("animinv")) {
      String[] m = match(name, "animinv(\\d+)");
      int animNum = parseInt(m[1]);
      selectedPostureTree.getAnimations().get(animNum).setInv(value == 0 ? true : false);
      setFileDirty();
    } else if (name.startsWith("copybtn")) {
      String[] m = match(name, "copybtn(\\d+)");
      int animNum = parseInt(m[1]);
      animationClipboard = selectedPostureTree.getAnimations().get(animNum).copy();
      mustUpdateUI = true;
    } else if (name.startsWith("pastebtn")) {
      String[] m = match(name, "pastebtn(\\d+)");
      int animNum = parseInt(m[1]);
      if (animationClipboard != null) {
        //selected.reset();
        ArrayList<Animation> animations = selectedPostureTree.getAnimations();
        if (animNum < animations.size()) {
          animations.set(animNum, animationClipboard.copy());
        } else {
          animations.add(animationClipboard.copy());
        }
        mustUpdateUI = true;
        setFileDirty();
      }
    } else if (name.startsWith("delbtn")) {
      String[] m = match(name, "delbtn(\\d+)");
      int animNum = parseInt(m[1]);
      //selected.reset(); // So transform matrix is set to identity
      selectedPostureTree.getAnimations().remove(animNum);
      mustUpdateUI = true;
      setFileDirty();
    } else if (name.startsWith("swapup")) {
      String[] m = match(name, "swapup(\\d+)");
      int animNum = parseInt(m[1]);
      ArrayList<Animation> animations = selectedPostureTree.getAnimations();
      Animation moveup = animations.get(animNum);
      animations.set(animNum, animations.get(animNum-1));
      animations.set(animNum-1, moveup);
      //updateUI();
      keepsOpenAnimNum = animNum-1;
      mustUpdateUI = true;
      setFileDirty();
    } else if (name.startsWith("swapdown")) {
      String[] m = match(name, "swapdown(\\d+)");
      int animNum = parseInt(m[1]);
      ArrayList<Animation> animations = selectedPostureTree.getAnimations();
      Animation moveup = animations.get(animNum+1);
      animations.set(animNum+1, animations.get(animNum));
      animations.set(animNum, moveup);
      //updateUI();
      keepsOpenAnimNum = animNum+1;
      mustUpdateUI = true;
      setFileDirty();
    } else if (name.startsWith("showtimeline")) {
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        if (timeline != null) {
          timeline.remove();
        } else {
          int animNum = parseInt(m[2]);
          timeline = new Timeline(animNum);
          //timeline.setFunction((TFTimetable) selected.getAnimation(animNum).getFunction());
          //timeline.show();
        }
      }
    } else if (name.startsWith("tl")) {
      // Timeline specific parameters
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        if (m[1].equals("tlnumsteps")) {
          timeline.updateTable();
        } else if (m[1].equals("tlslider")) {
          timeline.setTableValue(Integer.parseInt(m[2]), value);
        } else if (m[1].equals("tllshift")) {
          timeline.lshift();
        } else if (m[1].equals("tlrshift")) {
          timeline.rshift();
        }
      }
      //timeline.show();
      setFileDirty();
    } else {
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        String paramName = m[1];
        int animNum = parseInt(m[2]);
        TimeFunction fn = selectedPostureTree.getAnimations().get(animNum).getFunction();
        if (paramName.equals("easing")) {
          // Send value as a string (name of the easing function)
          int idx = floor(value);
          fn.setParam(paramName, Animation.interpolationNamesSimp[idx]);
        } else {
          // Round to 2 decimals
          value = int(value*100f) / 100f; //<>//
          fn.setParam(paramName, value);
        }
        mainScreen.playing = true;
        setFileDirty(); //<>// //<>//
        //if (timeline != null && timeline.getFunction() == fn)
        //  timeline.show();
      }
    }
  }
}



void setFileDirty() {
  fileDirty = true;
  surface.setTitle(appName + " - *" + baseFilename + ".json");
}


void inputFileSelected(File selection) throws IOException {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else { //<>//
    println("User selected " + selection.getAbsolutePath());
    String filename = selection.getAbsolutePath();
    if (filename.endsWith("svg")) {
      ComplexShape shape = ComplexShape.fromPShape(loadShape(filename));
      
      if (shape == null) {
        println("Could not load SVG file");
        return;
      }

      // Go up the complexShape tree if the root is empty (has only one child)
      while (shape.getShapes().size() == 1 && shape.getChildren().size() == 1)
        shape = (ComplexShape) shape.getShapes().get(0);

      // Center shape on world coordinates
      shape.hardTranslate(-shape.getBoundingBox().getCenter().x, -shape.getBoundingBox().bottom);

      selected = null;
      avatar = new Avatar();
      avatar.setShape(shape);
      mainScreen.partsList.setItems(avatar.getPartsNamePre());
      baseFilename = filename.substring(0, filename.length()-4);

      currentScreen = mainScreen;
      mainScreen.transport.postureName.setText("posture0");
      mainScreen.resetView();
      mainScreen.showUI();
      BoundingBox bb = avatar.getShape().getBoundingBox();
      float margin = min((bb.right-bb.left), (bb.bottom-bb.top)) / 20f;
      mainScreen.camera.set(bb.left - margin, bb.top - margin, bb.right + margin, bb.bottom + margin);
      setFileDirty();
    } else if (filename.endsWith("json")) {
      if (avatar == null) {
        loadJsonFile(selection);
      } else {
        loadScreen = new LoadScreen();
        fileToLoad = selection;
      }
    } else {
      println("Bad filename");
    }
  }
}


void outputFileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    if (avatar != null) {
      if (fileDirty)
        savePosture();

      String filename = selection.getAbsolutePath();
      if (!filename.toLowerCase().endsWith(".json"))
        filename = filename.concat(".json");

      avatar.saveFile(filename);
      baseFilename = filename.substring(0, filename.length()-5);
      surface.setTitle(appName + " - " + baseFilename + ".json");
    }
  }
}


void loadJsonFile(File file) {
  Avatar newAvatar = Avatar.fromFile(file);

  if (newAvatar == null) {
    println("Error while loading file");
    return;
  }

  avatar = newAvatar;

  mainScreen.partsList.setItems(avatar.getPartsNamePre());

  // postures are kept separated for simplicity
  // rather than storing and retrieving it from the Avatar class
  postureIndex = 0;
  if (avatar.getCurrentPosture() != null) {
    mainScreen.transport.postureName.setText(avatar.getCurrentPosture().getName());
    mainScreen.transport.animDuration.setValue(avatar.getCurrentPosture().getDuration());
    mainScreen.transport.pAnimDuration = avatar.getCurrentPosture().getDuration();
  } else {
    mainScreen.transport.postureName.setText("posture0");
    println("no postures in loaded file");
  }

  selected = null;

  String filename = file.getAbsolutePath();
  baseFilename = filename.substring(0, filename.length()-5);
  surface.setTitle(appName + " - " + filename);
  mainScreen.resetView();
  mainScreen.showUI();
  BoundingBox bb = avatar.getShape().getBoundingBox();
  float margin = min((bb.right-bb.left), (bb.bottom-bb.top)) / 20f;
  mainScreen.camera.set(bb.left - margin, bb.top - margin, bb.right + margin, bb.bottom + margin);
}
