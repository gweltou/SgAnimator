////
////    EVENTS
////
void keyPressed(KeyEvent event) {
  if (avatar != null && key == CODED) {
    if (keyCode == UP) {
      selected_idx = (selected_idx-1);
      if (selected_idx < 0)
        selected_idx += avatar.getPartsList().length;
      partsList.setValue(selected_idx);
    } else if (keyCode == DOWN) {
      selected_idx = (selected_idx+1) % avatar.getPartsList().length;
      partsList.setValue(selected_idx);
    } else if (keyCode == SHIFT && selected != null) {
      playAnim = false;
      avatar.resetAnimation();
    }
  } else if (!animName.isFocus()) {
    switch (key) {
      case 'p':  // Toggle animation
        if (avatar != null)
          playAnim = !playAnim;
        break;
      case 'r':  // Reset animation
        if (avatar != null)
          avatar.resetAnimation();
        break;
      case 'd':  // Edit animation mode
        if (avatar != null) {
          if (showUI) {
            hideUI();
            if (timeline != null)
              timeline.hide();
          } else {
            showUI();
          }
        }
        break;
      case 15:  // CTRL+o, load a new file
        selectInput("Select a file", "fileSelected");
        break;
      case 19: // CTRL+s, save
        if (avatar != null) {
          if (fullAnimationDirty)
            saveFullAnimation(animName.getText(), fullAnimationIndex);
          saveAvatarFile(avatar);
        }
        break;
      default:
        break;
    }
  }
}


void keyReleased() {
  if (key == CODED && keyCode == SHIFT && selected != null) {
    selected.hardTransform(hardTransform);
    hardTransform.idt();
    playAnim = true;
  }
}


void mouseWheel(MouseEvent event) {
  if (!partsList.isInside()) {
    float z = pow(1.1, -event.getCount());
    Affine2 unproject = new Affine2(transform).inv();
    Vector2 point = new Vector2(mouseX, mouseY);
    unproject.applyTo(point);
    transform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);
  }
}



void mouseClicked(MouseEvent event) {
  if (event.getButton() == LEFT) {
    if (setPivot && !cp5.getController("pivotbutton").isInside()) {
      Vector2 point = new Vector2(mouseX, mouseY);
      Affine2 t = new Affine2(transform).inv();
      t.applyTo(point);
      selected.setLocalOrigin(point.x, point.y);
      ((Button) cp5.getController("pivotbutton")).setOff();
      playAnim = true;
    }
    pivotButton.hide();
  } else {
    // RIGHT CLICK opens context menu (pivot button)
    if (selected != null) {
      pivotButton.setPosition(mouseX, mouseY);
      pivotButton.show();
    }
  }
}



void mouseDragged(MouseEvent event) {
  pivotButton.hide();
  if (event.getButton() == RIGHT) {
    int dx = mouseX-pmouseX;
    int dy = mouseY-pmouseY;
    if (keyPressed && keyCode == SHIFT && selected != null) {
      // scale translation by the zoom factor
      hardTransform.translate(dx/transform.m00, dy/transform.m11);
    } else {
      // scale translation by the zoom factor
      transform.translate(dx/transform.m00, dy/transform.m11);
    }
  }
}



import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

void controlEvent(ControlEvent event) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException  {
  if (event.isController() && !paramLocked) {
    if (timeline != null)
      timeline.hide();
    
    String name = event.getName();
    float value = event.getValue();
    //println("event", name, value);
    
    if (name.equals("partslist")) {
      select(avatar.getPartsList()[int(value)]);
      selected_idx = int(partsList.getValue());
    }
    
    else if (name.equals("animname")) {
      // Change fullAnim name
      println(animName.getText());
      fullAnimationDirty = true;
    }
    else if (name.equals("prevanim")) {
      if (fullAnimationIndex <= 0)
        return;
      
      if (fullAnimationDirty) {
        // Save fullAnimation to animationCollection
        saveFullAnimation(animName.getText(), fullAnimationIndex);
      }
      fullAnimationIndex--;
      avatar.setFullAnimation(animationCollection.getFullAnimation(fullAnimationIndex));
      animName.setText(animationCollection.getFullAnimationName(fullAnimationIndex));
      mustUpdateUI = true;
    }
    else if (name.equals("nextanim")) {
      if (fullAnimationDirty) {
        // Save fullAnimation to animationCollection
        saveFullAnimation(animName.getText(), fullAnimationIndex);
      }
      
      fullAnimationIndex++;
      if (fullAnimationIndex >= animationCollection.size()) {
        fullAnimationIndex = animationCollection.size();
        avatar.clearAnimation();
        animName.setText("anim"+fullAnimationIndex);
      } else {
        avatar.setFullAnimation(animationCollection.getFullAnimation(fullAnimationIndex));
      }
      mustUpdateUI = true;
    }
    
    else if (name.startsWith("function")) {
      String[] m = match(name, "function(\\d+)");
      int animNum = parseInt(m[1]);
      Class<TimeFunction> tfclass = Animation.timeFunctions[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      int numberOfAnimations = selected.getAnimationList().size();
      if (animNum < numberOfAnimations) {
        // Transfer compatible parameters to new TimeFunction
        //for (TFParam param : selected.getAnimation(animNum).getFunction().getParams()) {
        //  Object payload = param.getValue();
        //  println(payload.getClass());
        //  //tf.setParam(param.name, param.getValue()); // BROKEN
        //}
        selected.getAnimation(animNum).setFunction(tf);
      } else {
        selected.addAnimation(new Animation(tf));
      }
      selected.resetAnimation();
      if (tf instanceof TFTimetable) {
        timeline = new Timeline(animNum);
        timeline.setFunction((TFTimetable) tf);
        timeline.show();
      }
      mustUpdateUI = true;
      playAnim = true;
      fullAnimationDirty = true;
    }
    else if (name.startsWith("axe")) {
      String[] m = match(name, "axe(\\d+)");
      int animNum = parseInt(m[1]);
      selected.getAnimation(animNum).setAxe((int) value);
      playAnim = true;
      fullAnimationDirty = true;
      if (timeline != null && animNum == timeline.getAnimNum())
        timeline.show();
    }
    
    else if (name.equals("pivotbutton")) {
      setPivot = ((Button) cp5.getController("pivotbutton")).isOn();
      avatar.resetAnimation();
      playAnim = false;
    }
    
    else if (name.startsWith("copybutton")) {
      String[] m = match(name, "copybutton(\\d+)");
      int animNum = parseInt(m[1]);
      animationClipboard = selected.getAnimation(animNum).copy();
      mustUpdateUI = true;
    }
    else if (name.startsWith("pastebutton")) {
      String[] m = match(name, "pastebutton(\\d+)");
      int animNum = parseInt(m[1]);
      if (animationClipboard != null) {
        selected.resetAnimation();
        if (animNum < selected.getAnimationList().size()) {
          selected.setAnimation(animNum, animationClipboard);
        } else {
          selected.addAnimation(animationClipboard);
        }
        mustUpdateUI = true;
        fullAnimationDirty = true;
      }
    }
    
    else if (name.startsWith("deletebutton")) {
      String[] m = match(name, "deletebutton(\\d+)");
      int animNum = parseInt(m[1]);
      selected.resetAnimation(); // So transform matrix is set to identity
      selected.removeAnimation(animNum);
      mustUpdateUI = true;
      fullAnimationDirty = true;
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
      fullAnimationDirty = true;
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
      fullAnimationDirty = true;
    }
    
    else if (name.startsWith("showtimeline")) {
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        int animNum = parseInt(m[2]);
        timeline.setFunction((TFTimetable) selected.getAnimation(animNum).getFunction());
      }
      timeline.show();
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
      timeline.show();
    }
    else {
      String[] m = match(name, "([a-z]+)(\\d+)");
      if (m != null) {
        String paramName = m[1];
        int animNum = parseInt(m[2]);
        TimeFunction fn = selected.getAnimation(animNum).getFunction();
        fn.setParam(paramName, value);
        fn.reset();
        playAnim = true;
        fullAnimationDirty = true;
        if (timeline != null && timeline.getFunction() == fn)
          timeline.show();
      }
    }
  }
}
