public class MainScreen extends Screen {
  PImage selectpart;
  Affine2 transform;
  Affine2 hardTransform;
  TimeFunction selectpartAnim;
  private boolean transportMoving = false;


  public MainScreen() {
    selectpart = loadImage("selectpart.png");
    selectpartAnim = new TFEaseFromTo(60, 0, 0.66f, 0.66f, "bounceOut", false, true);
    transform = new Affine2().setToTranslation(width/2, height/2);
    hardTransform = new Affine2();
  }


  public void resetView() {
    transform.setToTranslation(width/2, height/2);
  }


  public void draw() {
    if (avatar == null) {
      hideUI();
      currentScreen = welcomeScreen;
      return;
    }

    background(255);

    renderer.pushMatrix(transform);
    if (playing)
      avatar.updateAnimation(1/frameRate);
    avatar.draw(renderer);
    
    if (renderer.isRecording() && playing) {
      renderer.flush();
    } else {
      avatar.drawSelectedOnly(renderer);
    }

    if (showUI) {
      if (selected != null) {
        if (!hardTransform.isIdt()) {
          renderer.pushMatrix(hardTransform);
          selected.setColorMod(1f, 1f, 1f, 0.4f);
          selected.draw(renderer);
          selected.setColorMod(1f, 1f, 1f, 1f);
          renderer.drawPivot();
          renderer.popMatrix();
        } else {
          renderer.drawPivot();
        }
      } else {
        selectpartAnim.update(1/frameRate);
        if (selectpart != null)
          image(selectpart, partsList.getPosition()[0] + partsList.getWidth() + 4 + selectpartAnim.getValue(), partsList.getPosition()[1] + selectpartAnim.getValue()/3);
      }
      renderer.drawMarker(0, 0);
      renderer.drawAxes();
    }
    renderer.popMatrix();
    
    if (playing == false && (frameCount>>5)%2 == 0) {
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
  }
  

  void keyPressed(KeyEvent event) {
    if (avatar != null && key == CODED) {
      if (keyCode == UP) {  // Select next part
        selectedIndex = (selectedIndex-1);
        if (selectedIndex < 0)
          selectedIndex += avatar.getPartsList().length;
        partsList.setValue(selectedIndex);
      } else if (keyCode == DOWN) {  // Select previous part
        selectedIndex = (selectedIndex+1) % avatar.getPartsList().length;
        partsList.setValue(selectedIndex);
      } else if (keyCode == SHIFT && selected != null && !isNumberboxActive) {
        playing = false;
        avatar.resetAnimation();
      }
    } else if (!transport.postureName.isActive() && !isNumberboxActive) {
      switch (key) {
      case 'p':  // Play/Pause animation
        if (avatar != null)
          playing = !playing;
        break;
      case 'r':  // Reset animation
        if (avatar != null)
          avatar.resetAnimation();
        if (selected != null) mustUpdateUI = true;
        break;
      case 'd':  // Show/Hide UI
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
      case 't':  // Physics scren
        hideUI();
        currentScreen = new PhysicsScreen(transform);
        break;
      case 'h':  // Help screens
        hideUI();
        currentScreen = helpScreen1;
        break;
      case 'w':  // Wireframe
        renderer.toggleWireframe();
        break;
      case 15:  // CTRL+o, load a new file
        selectInput("Select a file", "inputFileSelected");
        loadScreen = new LoadScreen();
        break;
      case 19: // CTRL+s, save
        selectOutput("Select a file", "outputFileSelected");
        break;
      }
    }
  }


  void keyReleased(KeyEvent event) {
    if (key == CODED && keyCode == SHIFT && selected != null && !isNumberboxActive) {
      selected.hardTransform(hardTransform);
      // Transform physics shell if necessary
      if (selected == avatar.shape) {
        for (Shape shape : avatar.physicsShapes)
          shape.hardTransform(hardTransform);
      }
      hardTransform.idt();
      playing = true;
      mustUpdateUI = true;
    }
  }


  void mouseWheel(MouseEvent event) {
    pivotButton.hide();
    if (!partsList.isInside()) {
      float z = pow(1.1, -event.getCount());
      Affine2 unproject = new Affine2(transform).inv();
      Vector2 point = new Vector2(mouseX, mouseY);
      unproject.applyTo(point);
      if (keyPressed && keyCode == SHIFT && selected != null) {
        // scale translation by the zoom factor
        point = selected.getLocalOrigin();
        z = 1 + (z-1) * 0.1f;
        hardTransform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);
      } else {
        // scale translation by the zoom factor
        transform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);
      }
    }
  }
  
  
  void mousePressed(MouseEvent event) {
    if (transport.contains(mouseX, mouseY)) {
      transportMoving = true;
    }
  }
  
  
  void mouseReleased(MouseEvent event) {
    transportMoving = false;
  }


  void mouseClicked(MouseEvent event) {
    if (event.getButton() == LEFT) {
      if (setPivot && !cp5.getController("pivotbutton").isInside()) {
        Vector2 point = new Vector2(mouseX, mouseY);
        Affine2 t = new Affine2(transform).inv();
        t.applyTo(point);
        selected.setLocalOrigin(point.x, point.y);
        ((Button) cp5.getController("pivotbutton")).setOff();
        playing = true;
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
    } else if (transportMoving) {
      transport.move(mouseX-pmouseX, mouseY-pmouseY);
    }
  }
}
