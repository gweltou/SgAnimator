import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;


boolean axeSetFirst = false;  // Used when animation's axe is chosen before function
String axeSetFirstName;
boolean controllerClicked = false;


void controlEvent(ControlEvent event) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException  {
  if (paramLocked)
    return;
  
  controllerClicked = true;
  
  if (event.isGroup() && timeline != null)
      timeline.remove();
      
  if (event.isController()) {
    String name = event.getName();
    float value = event.getValue();
    println("event", event);
    
    if (name.equals("partslist")) {
      select(avatar.getPartsList()[int(value)]);
      selectedIndex = int(partsList.getValue());
      return;
    } else if (avatar != null) {  // Don't reset animation when selecting parts
      avatar.resetAnimation();
    }
    
    if (name.equals("posturename")) {
      // Change fullAnim name
      setAnimationCollectionDirty();
    }
    
    else if (name.startsWith("function")) {
      String[] m = match(name, "function(\\d+)");
      int animNum = parseInt(m[1]);
      Class<TimeFunction> tfclass = Animation.timeFunctions[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      int numberOfAnimations = selected.getAnimationList().length;
      if (animNum < numberOfAnimations) {
        selected.getAnimation(animNum).setFunction(tf);
      } else {
        Animation a = new Animation(tf);
        if (axeSetFirst && parseInt(match(axeSetFirstName, "axe(\\d+)")[1]) == animNum) {
          int axeVal = (int) cp5.getController(axeSetFirstName).getValue();
          a.setAxe(axeVal);
        }
        selected.addAnimation(a);
      }
      //selected.reset();
      /*if (tf instanceof TFTimetable) {
        timeline = new Timeline(animNum);
        //timeline.setFunction((TFTimetable) tf);
        //timeline.show();
      }*/
      mustUpdateUI = true;
      playing = true;
      setAnimationCollectionDirty();
    }
    
    else if (name.startsWith("axe")) {
      String[] m = match(name, "axe(\\d+)");
      int animNum = parseInt(m[1]);
      // Should check if an function is set first
      if (animNum == selected.getAnimationList().length) {
        // No function set yet
        axeSetFirst = true;
        axeSetFirstName = name;
      } else {      
        selected.getAnimation(animNum).setAxe((int) value);
        mustUpdateUI = true;
        playing = true;
        setAnimationCollectionDirty();
      }
    }
    
    else if (name.startsWith("animamp")) {
      String[] m = match(name, "animamp(\\d+)");
      int animNum = parseInt(m[1]);
      selected.getAnimation(animNum).setAmp(int(value*100f) / 100f);
      setAnimationCollectionDirty();
    }
    
    else if (name.startsWith("animinv")) {
      String[] m = match(name, "animinv(\\d+)");
      int animNum = parseInt(m[1]);
      selected.getAnimation(animNum).setInv(value == 0 ? true : false);
      setAnimationCollectionDirty();
    }
    
    else if (name.equals("pivotbtn")) {
      setPivot = ((Button) cp5.getController("pivotbtn")).isOn();
      avatar.resetAnimation();
      playing = false;
    }
    
    else if (name.equals("importbtn")) {
      println("yay");
      //importButton.hide();
      selectInput("Select a file", "inputFileSelected");
      loadScreen = new LoadScreen();
    }
    
    else if (name.startsWith("copybtn")) {
      String[] m = match(name, "copybtn(\\d+)");
      int animNum = parseInt(m[1]);
      animationClipboard = selected.getAnimation(animNum).copy();
      mustUpdateUI = true;
    }
    
    else if (name.startsWith("pastebtn")) {
      String[] m = match(name, "pastebtn(\\d+)");
      int animNum = parseInt(m[1]);
      if (animationClipboard != null) {
        //selected.reset();
        if (animNum < selected.getAnimationList().length) {
          selected.setAnimation(animNum, animationClipboard.copy());
        } else {
          selected.addAnimation(animationClipboard.copy());
        }
        mustUpdateUI = true;
        setAnimationCollectionDirty();
      }
    }
    
    else if (name.startsWith("delbtn")) {
      String[] m = match(name, "delbtn(\\d+)");
      int animNum = parseInt(m[1]);
      //selected.reset(); // So transform matrix is set to identity
      selected.removeAnimation(animNum);
      mustUpdateUI = true;
      setAnimationCollectionDirty();
    }
    
    else if (name.startsWith("swapup")) {
      String[] m = match(name, "swapup(\\d+)");
      int animNum = parseInt(m[1]);
      Animation moveup = selected.getAnimation(animNum);
      selected.setAnimation(animNum, selected.getAnimation(animNum-1));
      selected.setAnimation(animNum-1, moveup);
      //updateUI();
      keepsOpenAnimNum = animNum-1;
      mustUpdateUI = true;
      setAnimationCollectionDirty();
    }
    
    else if (name.startsWith("swapdown")) {
      String[] m = match(name, "swapdown(\\d+)");
      int animNum = parseInt(m[1]);
      Animation moveup = selected.getAnimation(animNum+1);
      selected.setAnimation(animNum+1, selected.getAnimation(animNum));
      selected.setAnimation(animNum, moveup);
      //updateUI();
      keepsOpenAnimNum = animNum+1;
      mustUpdateUI = true;
      setAnimationCollectionDirty();
    }
    
    else if (name.startsWith("showtimeline")) {
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
    }
    
    else if (name.startsWith("tl")) {
      // Timeline specific parameters
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        if (m[1].equals("tlnumsteps")) {
          timeline.updateTable();
        }
        else if (m[1].equals("tlslider")) {
          timeline.setTableValue(Integer.parseInt(m[2]), value);
        }
        else if (m[1].equals("tllshift")) {
          timeline.lshift();
        }
        else if (m[1].equals("tlrshift")) {
          timeline.rshift();
        }
      }
      //timeline.show();
      setAnimationCollectionDirty();
    }
    
    else {
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        String paramName = m[1];
        int animNum = parseInt(m[2]);
        TimeFunction fn = selected.getAnimation(animNum).getFunction();
        if (paramName.equals("easing")) {
          // Send value as a string (name of the easing function)
          int idx = floor(value);
          fn.setParam(paramName, Animation.interpolationNamesSimp[idx]);
        } else {
          // Round to 2 decimals
          value = int(value*100f) / 100f;
          fn.setParam(paramName, value);
        }
        playing = true;
        setAnimationCollectionDirty();
        //if (timeline != null && timeline.getFunction() == fn)
        //  timeline.show();
      }
    }
  }
}



void setAnimationCollectionDirty() {
  animationCollectionDirty = true;
  surface.setTitle(appName + " - *" + baseFilename + ".json");
}


void inputFileSelected(File selection) throws IOException { 
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    String filename = selection.getAbsolutePath();
    if (filename.endsWith("svg")) {
      ComplexShape shape = ComplexShape.fromPShape(loadShape(filename));
      if (shape == null) {
        println("Could not load SVG file");
        return;
      }
      
      selectedIndex = 0;
      selected = null;
      // Go down the complexShape tree if the root is empty
      while (shape.getShapes().size() == 1 && shape.getChildren().size() == 1)
        shape = (ComplexShape) shape.getShapes().get(0);
      
      // Center shape
      shape.hardTranslate(-shape.getBoundingBox().getCenter().x, -shape.getBoundingBox().bottom);
      
      
      postures = new PostureCollection();
      avatar = new Avatar();
      avatar.setShape(shape);
      partsList.setItems(avatar.getPartsNamePre());
      baseFilename = filename.substring(0, filename.length()-4);
      
      currentScreen = mainScreen;
      transport.postureName.setText("posture0");
      mainScreen.resetView();
      showUI();
      //accordion.hide(); // Whyyy ???
      setAnimationCollectionDirty();
      
    /*} else if (filename.endsWith("tdat")) {
      rootShape = loadGeometry(selection);
      File animFile = new File(filename.replace(".tdat", ".json"));
      if (animFile.exists()) {
        JSONObject rootElement = loadJSONObject(selection);
        loadAnimation(rootElement.getJSONArray("animation"));
      }*/
    } else if (filename.endsWith("json")) {
      mustLoad = selection;
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
      if (animationCollectionDirty)
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
