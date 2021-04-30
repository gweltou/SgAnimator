public class MainScreen extends Screen {
  PImage selectpart;
  Affine2 transform;
  Affine2 hardTransform;
  TimeFunction selectpartAnim;
  private float[] selectedColorMod = new float[] {0.1f, 0.1f, 0.1f, 0.4f};
  
  private float defaultFramerate = frameRate;
  private float recordingFramerate = 25f;
  private float framerate = defaultFramerate;
  private int remainingFrames = 0;
  private boolean clearBackground = true;
  private float timeScale = 1f;


  public MainScreen() {
    selectpart = loadImage("selectpart.png");
    selectpartAnim = new TFEaseFromTo(60, 0, 0.66f, 0.66f, "bounceOut", false, true);
    transform = new Affine2().setToTranslation(width/2, height/2);
    hardTransform = new Affine2();
  }


  public void resetView() {
    transform.setToTranslation(width/2, height/2);
    if (timeline != null)
      timeline.remove();
  }
  
  
  public void startRecording() {
    framerate = recordingFramerate;
    remainingFrames = floor(transport.animDuration.getValue() * framerate);
    avatar.resetAnimation();
    renderer.setBackgroundColor(1, 1, 1, 1);
    renderer.startRecording(transport.getCounter());
  }
  
  
  public void stopRecording() {
    renderer.stopRecording();
    framerate = defaultFramerate;
  }


  public void draw() {
    if (avatar == null) {
      hideUI();
      currentScreen = welcomeScreen;
      return;
    }

    if (clearBackground || showUI)
      background(255);

    renderer.pushMatrix(transform);
    if (playing)
      avatar.update(1f/framerate);
    avatar.draw(renderer);
    
    if (renderer.isRecording() && playing) {
      renderer.flush();
      if (remainingFrames > 0) {
        remainingFrames--;
        transport.increaseCounter();
        if (remainingFrames == 0) {
          stopRecording();
          transport.buttonRec.setOff();
        }
      }
    } else {
      avatar.drawSelectedOnly(renderer);
    }

    if (showUI) {
      if (selected != null) {
        if (!hardTransform.isIdt()) {
          renderer.pushMatrix(hardTransform);
          renderer.pushColorMod(selectedColorMod);
          selected.draw(renderer);
          renderer.popColorMod();
          renderer.drawPivot();
          renderer.popMatrix();
        } else {
          renderer.drawPivot();
        }
      } else {
        selectpartAnim.update(1/framerate);
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
        if (avatar != null) {
          avatar.resetAnimation();
          background(255);
        }
        break;
      case 'd':  // Show/Hide UI
        if (avatar != null) {
          if (showUI) {
            hideUI();
            background(255);
            avatar.timeScale(timeScale);
            avatar.resetAnimation();
          } else {
            showUI();
            avatar.timeScale(1.0f);
          }
        }
        break;
      case 'x':  // Physics scren
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
      case 's':  // Save file
        if (avatar != null && animationCollectionDirty) {
          savePosture();
          avatar.saveFile(baseFilename + ".json");
          surface.setTitle(appName + " - " + baseFilename + ".json");
        }
        break;
      case 'b':  // Background clear, trail effect
        if (!showUI) {
          if (clearBackground ) {
            timeScale = 0.16f;
          } else {
            timeScale = 1.0f;
          }
          avatar.timeScale(timeScale);
          avatar.resetAnimation();
          background(255);
          clearBackground = !clearBackground;
        }
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
      //playing = true;
      mustUpdateUI = true;
      setAnimationCollectionDirty();
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
    if (transport.contains(mouseX, mouseY))
      transport.isMoving = true;
    else if (timeline != null && timeline.contains(mouseX, mouseY))
      timeline.isMoving = true;
  }
  
  
  void mouseReleased(MouseEvent event) {
    transport.isMoving = false;
    if (timeline != null)
      timeline.isMoving = false;
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
    int dx = mouseX-pmouseX;
    int dy = mouseY-pmouseY;
    if (event.getButton() == RIGHT) {
      if (keyPressed && keyCode == SHIFT && selected != null) {
        // scale translation by the zoom factor
        hardTransform.translate(dx/transform.m00, dy/transform.m11);
      } else {
        // scale translation by the zoom factor
        transform.translate(dx/transform.m00, dy/transform.m11);
      }
    } else if (transport.isMoving) {
      transport.move(dx, dy);
    } else if (timeline.isMoving) {
      timeline.move(dx, dy);
    }
  }
}
