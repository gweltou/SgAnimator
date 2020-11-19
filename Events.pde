////
////    EVENTS
////
void keyPressed(KeyEvent event) {
  if (rootShape != null && key == CODED) {
    if (keyCode == LEFT) {
      selected_idx = (selected_idx-1);
      if (selected_idx < 0)
        selected_idx += parts.size();
      select(parts.get(selected_idx));
    } else if (keyCode == RIGHT) {
      selected_idx = (selected_idx+1) % parts.size();
      select(parts.get(selected_idx));
    /*} else if (keyCode == DOWN) {
      for (ComplexShape shape : parts) {
        Animation anim = new Animation(new TFFixed());
        shape.transitionAnimation(anim, 0.2f);
      }
    }*/}
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
            renderer.setSelected(null);
          } else {
            showUI = true;
            accordion.show();
            partsList.show();
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
  if (!cp5.getController("parts list").isInside()) {
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
    }
  }
}


void mouseDragged(MouseEvent event) {
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
    
    if (name.equals("parts list")) {
      select(parts.get(int(value)));
    } else if (name.equals("function")) {
      playAnim = true;
      Class<TimeFunction> tfclass = Animation.timeFunctions[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      if (selected.getAnimation() == null) {
        selected.setAnimation(new Animation(tf));
        mustUpdateUI = true;
      } else {
        // Transfer compatible parameters to new TimeFunction
        for (TFParam param : selected.getAnimation().getFunction().getParams()) {
          tf.setParam(param.name, param.value);
        }
        selected.getAnimation().setFunction(tf);
        mustUpdateUI = true;
      }
    } else if (name.equals("axe")) {
      playAnim = true;
      selected.getAnimation().setAxe((int) value);
    } else if (name.equals("hingebutton")) {
      playAnim = false;
      setHinge = ((Button) cp5.getController("hingebutton")).isOn();
      rootShape.resetAnimation();
    } else if (name.equals("copybutton")) {
      println("copybutton");
      animationClipboard = selected.getAnimation();
      mustUpdateUI = true;
    } else if (name.equals("pastebutton")) {
      println("pastebutton");
      if (animationClipboard != null) {
        selected.setAnimation(animationClipboard);
        mustUpdateUI = true;
      }
    } else if (name.equals("deletebutton")) {
      selected.resetAnimation(); // So transform matrix is set to identity
      selected.setAnimation(null);
      mustUpdateUI = true;
    } else {
      playAnim = true;
      println("control event", event);
      selected.getAnimation().getFunction().setParam(name, value);
    }
  }
}
