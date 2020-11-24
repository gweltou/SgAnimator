////
////    EVENTS
////
void keyPressed(KeyEvent event) {
  if (rootShape != null && key == CODED) {
    if (keyCode == UP) {
      selected_idx = (selected_idx-1);
      if (selected_idx < 0)
        selected_idx += parts.size();
      partsList.setValue(selected_idx);
    } else if (keyCode == DOWN) {
      selected_idx = (selected_idx+1) % parts.size();
      partsList.setValue(selected_idx);
    }
  } else {
    switch (key) {
      case 'p':  // Toggle animation
        playAnim = !playAnim;
        if (rootShape != null)
          rootShape.resetAnimation();
        break;
      case 'r':  // Reset animation
        if (rootShape != null)
          rootShape.resetAnimation();
        break;
      case 'd':  // Edit animation mode
        if (rootShape != null) {
          if (showUI) {
            showUI = false;
            accordion.hide();
            partsList.hide();
            hingeButton.hide();
            renderer.setSelected(null);
          } else {
            showUI = true;
            accordion.show();
            partsList.show();
            hingeButton.show();
            renderer.setSelected(selected);
          }
        }
        break;
      case 15:  // CTRL+o, load a new file
        selectInput("Select a file", "fileSelected");
        break;
      case 19: // CTRL+s, save
        if (rootShape != null) {
          saveGeomAnim(rootShape);
        }
        break;
      default:
        break;
    }
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
    if (setHinge && !cp5.getController("hingebutton").isInside()) {
      Vector2 point = new Vector2(mouseX, mouseY);
      Affine2 t = new Affine2(transform).inv();
      t.applyTo(point);
      selected.setLocalOrigin(point.x, point.y);
      ((Button) cp5.getController("hingebutton")).setOff();
      playAnim = true;
    }
    hingeButton.hide();
  } else {
    // RIGHT CLICK opens context menu (hinge button)
    if (selected != null) {
      hingeButton.setPosition(mouseX, mouseY);
      hingeButton.show();
    }
  }
}


void mouseDragged(MouseEvent event) {
  hingeButton.hide();
  if (event.getButton() == RIGHT) {
    int dx = mouseX-pmouseX;
    int dy = mouseY-pmouseY;
    // scale translation by the zoom factor
    transform.translate(dx/transform.m00, dy/transform.m11);
  }
}



import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

void controlEvent(ControlEvent event) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException  {
  if (event.isController() && !paramLocked) {
    String name = event.getName();
    float value = event.getValue();
    //println("event", name, value);
    
    if (name.equals("partslist")) {
      select(parts.get(int(value)));
    }
    else if (name.startsWith("function")) {
      String[] m = match(name, "function(\\d)");
      int animNum = parseInt(m[1]);
      Class<TimeFunction> tfclass = Animation.timeFunctions[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      int numberOfAnimations = selected.getAnimationList().size();
      if (animNum < numberOfAnimations) {
        // Transfer compatible parameters to new TimeFunction
        for (TFParam param : selected.getAnimation(animNum).getFunction().getParams()) {
          tf.setParam(param.name, param.value);
        }
        selected.getAnimation(animNum).setFunction(tf);
      } else {
        selected.addAnimation(new Animation(tf));
      }
      selected.resetAnimation();
      mustUpdateUI = true;
      playAnim = true;
    }
    else if (name.startsWith("axe")) {
      String[] m = match(name, "axe(\\d)");
      int animNum = parseInt(m[1]);
      selected.getAnimation(animNum).setAxe((int) value);
      playAnim = true;
    }
    else if (name.equals("hingebutton")) {
      setHinge = ((Button) cp5.getController("hingebutton")).isOn();
      rootShape.resetAnimation();
      playAnim = false;
    }
    else if (name.startsWith("copybutton")) {
      String[] m = match(name, "copybutton(\\d)");
      int animNum = parseInt(m[1]);
      println("copybutton"+animNum);
      animationClipboard = selected.getAnimation(animNum).copy();
      mustUpdateUI = true;
    }
    else if (name.startsWith("pastebutton")) {
      String[] m = match(name, "pastebutton(\\d)");
      int animNum = parseInt(m[1]);
      println("pastebutton"+animNum);
      if (animationClipboard != null) {
        selected.resetAnimation();
        if (animNum < selected.getAnimationList().size()) {
          selected.setAnimation(animNum, animationClipboard);
        } else {
          selected.addAnimation(animationClipboard);
        }
        mustUpdateUI = true;
      }
    }
    else if (name.startsWith("deletebutton")) {
      String[] m = match(name, "deletebutton(\\d)");
      int animNum = parseInt(m[1]);
      selected.resetAnimation(); // So transform matrix is set to identity
      selected.removeAnimation(animNum);
      mustUpdateUI = true;
    }
    else {
      String[] m = match(name, "([a-z]+)(\\d)");
      if (m != null) {
        String paramName = m[1];
        int animNum = parseInt(m[2]);
         selected.getAnimation(animNum).getFunction().setParam(paramName, value);
        playAnim = true;
      }
    }
  }
}
