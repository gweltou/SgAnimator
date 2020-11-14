////
////    EVENTS
////
void keyPressed(KeyEvent event) {
  if (rootShape != null && key == CODED) {
    if (keyCode == LEFT || keyCode == DOWN) {
      selected_idx = (selected_idx-1);
      if (selected_idx < 0)
        selected_idx += parts.size();
      select(parts.get(selected_idx));
    } else if (keyCode == RIGHT || keyCode == UP) {
      selected_idx = (selected_idx+1) % parts.size();
      select(parts.get(selected_idx));
    }
  } else {
    println((int) key);
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
      case 'm':  // Edit animation mode
        if (edit) {
          edit = false;
          //accordion.hide();
        } else {
          edit = true;
          //accordion.show();
        }
        break;
      case 15:  // CTRL+o, load a new file
        selectInput("Select a file", "fileSelected");
        break;
      case 19: // CTRL+s, save
        if (rootShape != null) {
          saveGeomAnim(rootShape);
          //saveAnimation(rootShape);
        }
        break;
      default:
        break;
    }
  }
}


void mouseWheel(MouseEvent event) {
  float z = pow(1.1, -event.getCount());
  Affine2 unproject = new Affine2(transform).inv();
  Vector2 point = new Vector2(mouseX, mouseY);
  unproject.applyTo(point);
  transform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);
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
