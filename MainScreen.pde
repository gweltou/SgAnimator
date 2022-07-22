ContextMenu contextMenu; //<>//
//ContextMenu partsMenu;
FunctionAccordion accordion;


public class MainScreen extends Screen {
  Affine2 transform; // Window view transform
  
  private boolean setPivot = false;
  private boolean playing = false;
  private float defaultFramerate = frameRate;
  //private float recordingFramerate = 25f;
  private float framerate = defaultFramerate;
  private int remainingFrames = 0;
  private boolean clearBackground = true;
  private float timeScale = 1f;

  private Transport transport;

  private Camera camera = new Camera();
  private PGraphics spritesheetBuffer;
  private int spritesheetWidth, spritesheetHeight;
  
  private PartsList partsList;

  private int mouseClickBtn;
  private Vector2 mouseClickPos = new Vector2();
  private boolean partMoving = false;
  private boolean partScalingNW = false;
  private boolean partScalingSE = false;
  private boolean partRotating = false;
  private float partRotation = 0f;

  private Vector2 bbNW, bbSE; // Selection's bounding box


  private class Camera {
    private boolean isVisible = false;
    private float PPU = 0.5; // Pixels per unit
    public Vector2 NW, SE;
    private Vector2 pNW, pSE;
    public Vector2 screenNW, screenSE;
    private boolean isMoving = false;
    private Affine2 transform = new Affine2();
    private boolean resizeNW = false;
    private boolean resizeSE = false;
    public int bufferWidth, bufferHeight;
    public boolean isRecording = false;
    public boolean isSpritesheet = true;

    private Slider pixelate;
    private Icon bgIcon;
    private MyColorPicker colorPicker;
    private NumberboxInput framerate;
    private Icon spritesheetToggle;


    public class MyColorPicker extends ColorPicker {
      public MyColorPicker( ControlP5 theControlP5, String theName ) {
        super( theControlP5, theControlP5.getDefaultTab(), theName, 0, 0, 100, 10 );
        currentColor = null;
        //theControlP5.register( theControlP5.papplet, theName, this );
      }

      //@Override
      public void controlEvent( ControlEvent theEvent ) {
        _myArrayValue[ theEvent.getId( ) ] = theEvent.getValue( );
        float r = _myArrayValue[0] / 255.0;
        float g = _myArrayValue[1] / 255.0;
        float b = _myArrayValue[2] / 255.0;
        float a = _myArrayValue[3] / 255.0;
        if (bufferedRenderer != null)
          bufferedRenderer.setBackgroundColor(r, g, b, a);
      }
    }


    public Camera() {
      pixelate = cp5.addSlider("campixelate")
        .setCaptionLabel("")
        .setSize(0, 12)
        .setRange(0.1, 2)
        .setValue(PPU)
        .plugTo(this, "setPPU")
        .hide()
        ;
      pixelate.onEnter(new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
          tooltip.say("Change frame resolution");
        }
      }
      );

      bgIcon = cp5.addIcon("icon", 0)
        .setPosition(-50, -50)
        .setSize(20, 20)
        .setFont(iconFont)
        .setFontIcons(#00f53f, #00f53f)
        .setSwitch(true)
        .plugTo(this, "onBgIcon")
        .hide()
        ;
      bgIcon.onEnter(new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
          tooltip.say("Set background color");
        }
      }
      );

      colorPicker = new MyColorPicker(cp5, "picker");
      colorPicker
        .setColorValue(color(255, 255, 255, 0))
        .hide()
        ;

      framerate = new NumberboxInput(cp5, "camframerate");
      framerate
        .setUnit(" fps")
        .setPosition(-100, -100)
        .setRange(1, 30)
        .setValue(12)
        .setDecimalPrecision(0)
        .setWidth(40)
        .hide();
      framerate.getValueLabel().setText("12 fps");
      framerate.onEnter(new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
          tooltip.say("Set camera framerate");
        }
      }
      );

      spritesheetToggle = cp5.addIcon("spritesheettoggle", 1)
        .setPosition(-100, -100)
        .setSize(20, 20)
        .setFont(iconFont)
        .setFontIcons(#00f84c, #00f84c)
        .setSwitch(true)
        .plugTo(this, "onSpritesheetToggle")
        .hide()
        ;
      spritesheetToggle.onEnter(new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
          tooltip.say("Toggle spritesheet mode (draw every frame in a single file)");
        }
      }
      );
      if (isSpritesheet)
        spritesheetToggle.setOn();

      set(-5, -5, 5, 5);
    }

    /**
     Sets camera view in world coordinates
     
     parameters:
     - worldX1, worldY1 (upper-left corner)
     - worldX2, worldY2 (bottom-right corner)
     */
    public void set(float worldX1, float worldY1, float worldX2, float worldY2) {
      NW = new Vector2(worldX1, worldY1);
      SE = new Vector2(worldX2, worldY2);
      pNW = new Vector2();
      pSE = new Vector2();
      screenNW = new Vector2();
      screenSE = new Vector2();
      resizeBuffer();
    }

    public void resizeBuffer() {
      bufferWidth = ceil((SE.x - NW.x) * PPU);
      bufferHeight = ceil((SE.y - NW.y) * PPU);
      bufferedRenderer.setBufferSize(bufferWidth, bufferHeight);
    }

    public void hide() {
      isVisible = false;
      pixelate.hide();
      bgIcon.hide();
      bgIcon.setOff();
      colorPicker.hide();
      framerate.hide();
      spritesheetToggle.hide();
    }

    public void show() {
      isVisible = true;
      pixelate.show();
      bgIcon.show();
      framerate.show();
      spritesheetToggle.show();
    }

    public float getFramerate() {
      return framerate.getValue();
    }

    public void draw(Affine2 transform) {
      boolean hasMoved = !(NW.equals(pNW) && SE.equals(pSE));
      if (hasMoved) {
        screenNW.set(NW);
        transform.applyTo(screenNW);
        screenSE.set(SE);
        transform.applyTo(screenSE);
      }

      if (!(resizeNW || resizeSE)) {
        Vector2 translation = new Vector2(-NW.x, -NW.y);
        this.transform.idt();
        this.transform.scale(PPU, PPU);
        this.transform.translate(translation);

        bufferedRenderer.pushMatrix(this.transform);
        bufferedRenderer.beginDraw();
        bufferedRenderer.clear();
        avatar.draw(bufferedRenderer);
        bufferedRenderer.endDraw();
        bufferedRenderer.popMatrix();

        noStroke();
        beginShape();
        texture(checkboard);
        vertex(screenNW.x, screenNW.y, 0, 0);
        vertex(screenSE.x, screenNW.y, screenSE.x-screenNW.x, 0);
        vertex(screenSE.x, screenSE.y, screenSE.x-screenNW.x, screenSE.y-screenNW.y);
        vertex(screenNW.x, screenSE.y, 0, screenSE.y-screenNW.y);
        endShape();
        image(bufferedRenderer.getBuffer(), screenNW.x, screenNW.y, bufferWidth*transform.m00/PPU, bufferHeight*transform.m11/PPU);
      }

      noFill();
      stroke(0, 64, 255);
      strokeWeight(2);
      rect(screenNW.x, screenNW.y, screenSE.x-screenNW.x, screenSE.y-screenNW.y);

      // Resize handles
      strokeWeight(2.4f + 0.6 * MathUtils.sin(TWO_PI * (millis() % 600) / 600 ));
      square(screenNW.x-5, screenNW.y-5, 10);
      square(screenSE.x-5, screenSE.y-5, 10);

      int w = ceil((SE.x - NW.x) * PPU);
      int h = ceil((SE.y - NW.y) * PPU);
      String strBufSize = str(w) + " × " + str(h) + " px";
      fill(0);
      textFont(defaultFontSmall);
      text(strBufSize, screenSE.x + 12, screenSE.y + 15);

      if (hasMoved) {
        pixelate.setPosition(screenNW.x, screenSE.y + 4)
          .setSize(floor(screenSE.x - screenNW.x), 12)
          ;

        framerate.setPosition(screenSE.x + 2, screenNW.y);

        spritesheetToggle.setPosition(screenSE.x + 2, screenNW.y + 22);

        bgIcon.setPosition(screenSE.x + 2, screenNW.y + 44);
        colorPicker.setPosition(screenSE.x + 26, screenNW.y + 44);

        controllerClicked = false;
      }
    }

    public void setPPU() {
      float newVal = pixelate.getValue();
      // event keeps getting fired
      if (newVal != PPU) {
        PPU = newVal;
        resizeBuffer();
      }
    }

    public void onBgIcon(boolean val) {
      if (val)
        colorPicker.show();
      else
        colorPicker.hide();
    }

    public void onSpritesheetToggle(boolean val) {
      isSpritesheet = val;
    }
  }

  public MainScreen() {
    transform = new Affine2().setToTranslation(width/2, height/2);
    bbNW = new Vector2();
    bbSE = new Vector2();

    // CP5 UI
    transport = new Transport();
    accordion = new FunctionAccordion(cp5, "accordion");
    contextMenu = new ContextMenu();
    partsList = new PartsList();
    partsList.setPosition(margin, margin + 44);

    //partsMenu = new ContextMenu();
  }


  public void resetView() {
    transform.setToTranslation(width/2, height/2);
    if (timeline != null)
      timeline.remove();
  }


  public void startRecording() {
    framerate = camera.getFramerate();
    remainingFrames = floor(transport.animDuration.getValue() * framerate);
    if (camera.isSpritesheet) {
      spritesheetWidth = floor(sqrt(remainingFrames));
      spritesheetHeight = ceil(remainingFrames / float(spritesheetWidth));
      println("Spritesheet cells :", spritesheetWidth, "×", spritesheetHeight);
      spritesheetBuffer = createGraphics(spritesheetWidth * camera.bufferWidth, spritesheetHeight * camera.bufferHeight);
      spritesheetBuffer.beginDraw();
      spritesheetBuffer.background(bufferedRenderer.getBackgroundColor());
    }

    avatar.resetAnimation();
    camera.show();
    camera.isRecording = true;
  }


  public void stopRecording() {
    framerate = defaultFramerate;
    camera.isRecording = false;
    if (camera.isSpritesheet) {
      spritesheetBuffer.endDraw();
      String filename = String.format("frames/%s.png", transport.postureName.getText());
      spritesheetBuffer.save(filename);
      println("Spritesheet saved to", filename);
    }
  }


  public void draw() {
    if (clearBackground || showUI)
      background(255);

    renderer.pushMatrix(transform);

    if (avatar != null) {
      if (playing)
        avatar.update(1f/framerate);

      avatar.draw(renderer);
      avatar.drawSelectedOnly(renderer);
    }

    if (showUI) {
      if (selected != null) {
        selected.drawPivot(renderer);

        if (!playing) {
          // Draw bounding box
          noFill();
          stroke(255, 127, 0);
          strokeWeight(2);
          pushMatrix();
          if (!partRotating) {
            BoundingBox bb = selected.getBoundingBox();
            bbNW.set(bb.left, bb.top);
            bbSE.set(bb.right, bb.bottom);
            transform.applyTo(bbNW);
            transform.applyTo(bbSE);
          } else {
            translate((bbNW.x+bbSE.x)*0.5, (bbNW.y+bbSE.y)*0.5);
            rotate(partRotation);
            translate(-(bbNW.x+bbSE.x)*0.5, -(bbNW.y+bbSE.y)*0.5);
          }
          rect(bbNW.x, bbNW.y, bbSE.x-bbNW.x, bbSE.y-bbNW.y);
          line(bbNW.x, bbNW.y, bbSE.x, bbSE.y);
          line(bbNW.x, bbSE.y, bbSE.x, bbNW.y);

          // Handles
          stroke(255, 63, 0);
          strokeWeight(2.4f + 0.6 * MathUtils.sin(TWO_PI * (millis() % 600) / 600 ));
          circle(bbSE.x, bbNW.y, 10);
          square(bbNW.x-5, bbNW.y-5, 10);
          square(bbSE.x-5, bbSE.y-5, 10);
          popMatrix();
        }
      }

      if (camera.isVisible) {
        camera.draw(transform);

        if (camera.isRecording && playing) {
          if (remainingFrames > 0) {
            PImage buffer = bufferedRenderer.getBuffer();
            if (camera.isSpritesheet) {
              int nFrame = floor(transport.animDuration.getValue() * framerate) - remainingFrames;
              int cellX = nFrame % spritesheetWidth;
              int cellY = floor(nFrame / spritesheetWidth);
              spritesheetBuffer.image(buffer, camera.bufferWidth * cellX, camera.bufferHeight * cellY);
            } else {
              buffer.save(String.format("frames/frame-%03d.png", transport.getCounter()));
            }
            remainingFrames--;
            transport.increaseCounter();
            if (remainingFrames == 0) {
              stopRecording();
              transport.buttonRec.setOff();
            }
          }
        }
      } else {
        Vector2 origin = new Vector2();
        transform.applyTo(origin);
        fill(0, 0, 255);
        stroke(0, 0, 255);
        strokeWeight(1);
        line(origin.x-6, origin.y, origin.x+6, origin.y);
        line(origin.x, origin.y-6, origin.x, origin.y+6);
        textFont(defaultFontSmall);
        text("0,0", origin.x + 4, origin.y + 12);

        renderer.drawAxes();
      }
    }

    renderer.popMatrix();

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


  Vector2 getWorldPos(Vector2 v) {
    return getWorldPos(v.x, v.y);
  }

  Vector2 getWorldPos(float x, float y) {
    Vector2 pos = new Vector2(x, y);
    Affine2 t = new Affine2(transform).inv();
    t.applyTo(pos);
    return pos;
  }


  public void showUI() {
    showUI = true;
    if (accordion != null)
      accordion.show();
    partsList.show();
    transport.show();
    renderer.setSelected(selected);
    if (timeline != null)
      timeline.show();

    controllerClicked = false;
  }

  public void hideUI() {
    showUI = false;
    if (accordion != null)
      accordion.hide();
    partsList.hide();
    camera.hide();
    contextMenu.hide();
    transport.hide();
    renderer.setSelected(null);
    if (timeline != null)
      timeline.hide();

    controllerClicked = false;
  }

  void keyPressed(KeyEvent event) {
    if (!transport.postureName.isActive() && !isNumberboxActive) {
      if (event.isControlDown()) {
        switch (event.getKeyCode()) {
        case 79:  // CTRL+o, load a new file
          selectInput("Select a file", "inputFileSelected");
          loadScreen = new LoadScreen();
          break;
        case 83: // CTRL+s, save
          selectOutput("Select a file", "outputFileSelected");
          break;
        }
      } else if (avatar != null && key == CODED) {
        if (keyCode == LEFT) {
          transport.prevPosture();
        } else if (keyCode == RIGHT) {
          transport.nextPosture();
        }
      } else {
        switch (key) {
        case 'p':  // Play/Pause animation
          if (playing) {
            transport.playToggle.setOff();
          } else {
            transport.playToggle.setOn();
          }
          break;
        case 'r':  // Reset animation
          if (avatar != null) {
            avatar.resetAnimation();
            background(255);
          }
          break;
        case 'a':  // Select root node
          if (avatar != null) {
            select(avatar.getShape());
            partsList.selectItem(0);
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
        case 'w':  // Wireframe
          renderer.toggleWireframe();
          break;
        case 'k':  // Camera
          if (!camera.isVisible) {
            transport.cameraToggle.setOn();
          } else {
            transport.cameraToggle.setOff();
          }
          break;
        case 'g':
          if (partsList.isVisible)
            partsList.hide();
          else
            partsList.show();
          break;
        case 'x':  // Physics scren
          hideUI();
          currentScreen = new PhysicsScreen(transform);
          break;
        case 'h':  // Help screens
          hideUI();
          currentScreen = helpScreen1;
          break;
        case 's':  // Save file
          if (avatar != null && fileDirty) {
            savePosture();
            avatar.saveFile(baseFilename + ".json");
            windowTitle(appName + " - " + baseFilename + ".json");
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
      controllerClicked = false;
    }
  }


  void keyReleased(KeyEvent event) {
    if (key == CODED && keyCode == SHIFT && selected != null && !isNumberboxActive) {
      //playing = true;
      mustUpdateUI = true;
      setFileDirty();
    }
  }


  void mouseWheel(MouseEvent event) {
    contextMenu.hide();
    if (!partsList.list.isInside()) {
      float z = pow(1.12, -event.getCount());
      Vector2 point = getWorldPos(mouseX, mouseY);
      transform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);  // scale translation by the zoom factor
    }
  }


  void mousePressed(MouseEvent event) {
    mouseClickBtn = event.getButton();
    mouseClickPos.set(mouseX, mouseY);
    Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
    if (transport.contains(mouseX, mouseY)) {
      transport.isMoving = true;
      return;
    }
    if (partsList.isVisible && partsList.contains(mouseX, mouseY)) {
      partsList.isMoving = true;
      return;
    }
    if (timeline != null && timeline.contains(mouseX, mouseY)) {
      // Move timeline box
      timeline.isMoving = true;
      return;
    }
    if (camera.isVisible) {
      if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, camera.NW.x, camera.NW.y) < 10/transform.m00) {
        camera.resizeNW = true;
        tooltip.say("Resize camera (hold MAJ key to preserve ratio)");
        return;
      } else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, camera.SE.x, camera.SE.y) < 10/transform.m00) {
        camera.resizeSE = true;
        tooltip.say("Resize camera (hold MAJ key to preserve ratio)");
        return;
      } else if (isInsideBox(mouseX, mouseY, camera.screenNW, camera.screenSE)) {
        camera.isMoving = true;
        tooltip.say("Drag mouse to move camera");
        return;
      }
    }
    if (selected != null && !playing) {  // Scale or rotate part only when animation is stopped
      BoundingBox bb = selected.getBoundingBox();
      if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, bb.left, bb.top) < 10/transform.m00) {
        partScalingNW = true;
        tooltip.say("Resize geometry (hold MAJ key to preserve ratio)");
        return;
      } else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, bb.right, bb.bottom) < 10/transform.m00) {
        partScalingSE = true;
        tooltip.say("Resize geometry (hold MAJ key to preserve ratio)");
        return;
      } else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, bb.right, bb.top) < 10/transform.m00) {
        partRotating = true;
        tooltip.say("Rotate geometry");
        return;
      }
    }
  }


  void mouseReleased(MouseEvent event) {
    transport.isMoving = false;
    partsList.isMoving = false;
    if (timeline != null)
      timeline.isMoving = false;

    mouseClickBtn = 0;

    partMoving = false;
    camera.isMoving = false;
    partScalingNW = false;
    partScalingSE = false;
    partRotating = false;
    partRotation = 0f;

    if (camera.resizeNW || camera.resizeSE) {
      camera.resizeBuffer();
      camera.resizeNW = false;
      camera.resizeSE = false;
    }

    if (avatar != null)
      avatar.paused = false; // ???
  }


  void mouseClicked(MouseEvent event) {
    if (event.getButton() == LEFT) {
      if (setPivot && !controllerClicked) {
        // Place new pivot
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        selected.getAbsoluteTransform().inv().applyTo(mouseWorldPos);
        selected.setLocalOrigin(mouseWorldPos);
        setPivot = false;
        setFileDirty();
      } else if (camera.isVisible && isInsideBox(mouseX, mouseY, camera.screenNW, camera.screenSE)) {
        // Nothing happens when clicking inside the camera window
        return;
      } else if (!controllerClicked) {
        // Select a part
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        ComplexShape[] parts = avatar.getPartsList();
        ComplexShape clickedPart = null;
        //avatar.getShape().invalidateBoundingBox();
        int i;
        for (i = parts.length-1; i >= 0; i--) {
          if (parts[i].contains(mouseWorldPos)) {
            clickedPart = parts[i];
            break;
          }
        }
        select(clickedPart);
        if (clickedPart != null)
          partsList.selectItem(i);
      }
      contextMenu.hide();
    } else {
      // RIGHT CLICK opens context menu
      if (selected == null) {
        //contextMenu.display("importbtn");
      } else {
        contextMenu.display("pivotbtn");
        contextMenu.display("resettr");
      }
      contextMenu.setPosition(mouseX, mouseY);
      contextMenu.show();
    }

    controllerClicked = false;
  }


  void mouseDragged(MouseEvent event) {
    contextMenu.hide();

    int dx = mouseX-pmouseX;
    int dy = mouseY-pmouseY;
    float wdx = dx/transform.m00;
    float wdy = dy/transform.m11;
    float drag_distance = mouseClickPos.dst2(mouseX, mouseY);
    Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);

    if (mouseClickBtn == LEFT) {
      if (partMoving) {
        Affine2 tr = new Affine2();
        tr.setToTranslation(wdx, wdy);
        selected.softTransform(tr);
        setFileDirty();

        // Transform physics shell if necessary
        /*
        if (selected == avatar.shape) {
         for (Shape shape : avatar.physicsShapes)
         shape.hardTransform(tr);
         }*/
      } else if (partScalingNW) {
        //avatar.paused = true;
        //avatar.resetAnimation();
        BoundingBox bb = selected.getBoundingBox();
        Vector2 dim = bb.getDimensions();
        float sx = max(0.2f, bb.right - mouseWorldPos.x) / dim.x;
        float sy = max(0.2f, bb.bottom - mouseWorldPos.y) / dim.y;
        if (keyPressed && keyCode == 16) {
          sx = max(sx, sy);
          sy = sx;
        }
        Affine2 tr = new Affine2();
        tr.translate(bb.right, bb.bottom).scale(sx, sy).translate(-bb.right, -bb.bottom);
        selected.softTransform(tr);
        setFileDirty();
      } else if (partScalingSE) {
        avatar.paused = true;
        avatar.resetAnimation();
        BoundingBox bb = selected.getBoundingBox();
        Vector2 dim = bb.getDimensions();
        float sx = max(0.2f, mouseWorldPos.x - bb.left) / dim.x;
        float sy = max(0.2f, mouseWorldPos.y - bb.top) / dim.y;
        if (keyPressed && keyCode == 16) {
          sx = max(sx, sy);
          sy = sx;
        }
        Affine2 tr = new Affine2();
        tr.translate(bb.left, bb.top).scale(sx, sy).translate(-bb.left, -bb.top);
        selected.softTransform(tr);
        setFileDirty();
      } else if (partRotating) {
        avatar.paused = true;
        avatar.resetAnimation();
        Vector2 pMouseWorldPos = getWorldPos(pmouseX, pmouseY);
        Vector2 center = getWorldPos((bbNW.x+bbSE.x)*0.5, (bbNW.y+bbSE.y)*0.5);
        pMouseWorldPos.sub(center);
        mouseWorldPos.sub(center);
        float angle = mouseWorldPos.angleRad(pMouseWorldPos);
        partRotation += angle;
        Affine2 tr = new Affine2();
        tr.translate(center).rotateRad(angle).translate(-center.x, -center.y);
        selected.softTransform(tr);
        setFileDirty();
      } else if (camera.isMoving) {
        camera.NW.add(wdx, wdy);
        camera.SE.add(wdx, wdy);
      } else if (camera.resizeNW) {
        camera.NW.set(mouseWorldPos);
        if (keyPressed && keyCode == 16) {
          // "MAJ" to preserve ratio
          float desiredRatio = camera.bufferWidth / float(camera.bufferHeight);
          float camWidth = camera.SE.x-camera.NW.x;
          float camHeight = camera.SE.y-camera.NW.y;
          float currentRatio = camWidth / camHeight;
          if (currentRatio >= desiredRatio)
            camera.NW.y = camera.SE.y - camWidth / desiredRatio;
          else
            camera.NW.x = camera.SE.x - camHeight * desiredRatio;
        }
        camera.NW.x = min(camera.NW.x, camera.SE.x - 1);
        camera.NW.y = min(camera.NW.y, camera.SE.y - 1);
      } else if (camera.resizeSE) {
        camera.SE.set(mouseWorldPos);
        if (keyPressed && keyCode == 16) {
          // "MAJ" to preserve ratio
          float desiredRatio = camera.bufferWidth / float(camera.bufferHeight);
          float camWidth = camera.SE.x-camera.NW.x;
          float camHeight = camera.SE.y-camera.NW.y;
          float currentRatio = camWidth / camHeight;
          if (currentRatio >= desiredRatio)
            camera.SE.y = camera.NW.y + camWidth / desiredRatio;
          else
            camera.SE.x = camera.NW.x + camHeight * desiredRatio;
        }
        camera.SE.x = max(camera.SE.x, camera.NW.x + 1);
        camera.SE.y = max(camera.SE.y, camera.NW.y + 1);
      } else if (!controllerClicked) {
        if (selected != null && !playing && isInsideBox(mouseClickPos.x, mouseClickPos.y, bbNW, bbSE) && drag_distance > 200) {
          // Move part
          avatar.paused = true;
          avatar.resetAnimation();
          partMoving = true;
          Affine2 tr = new Affine2();
          tr.setToTranslation((mouseX - mouseClickPos.x)/transform.m00,
            (mouseY - mouseClickPos.y)/transform.m11);    // scale translation by the zoom factor
          selected.softTransform(tr);

          // Transform physics shell if necessary
          /*
          if (selected == avatar.shape) {
           for (Shape shape : avatar.physicsShapes)
           shape.hardTransform(tr);
           }*/
        }
      }

      if (transport.isMoving) {
        transport.move(dx, dy);
      } else if (partsList.isMoving) {
        println("move");
        partsList.move(dx, dy);
      } else if (timeline != null && timeline.isMoving) {
        timeline.move(dx, dy);
      }
    } else if (mouseClickBtn == RIGHT) {
      transform.translate(wdx, wdy);
    }
  }
}


public boolean isInside(Vector2 pos, Vector2 nw, Vector2 se) {
  return isInsideBox(pos.x, pos.y, nw, se);
}

public boolean isInsideBox(float x, float y, Vector2 nw, Vector2 se) {
  return x > nw.x && x < se.x && y > nw.y && y < se.y;
}
