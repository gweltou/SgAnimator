ContextMenu contextMenu;
//ContextMenu partsMenu;
FunctionAccordion accordion;

public class MainScreen extends Screen {
  Affine2 transform; // Window view transform
  //private float[] selectedColorMod = new float[] {0.1f, 0.1f, 0.1f, 0.4f};
  
  private float defaultFramerate = frameRate;
  private float recordingFramerate = 25f;
  private float framerate = defaultFramerate;
  private int remainingFrames = 0;
  private boolean clearBackground = true;
  private float timeScale = 1f;
  
  private Camera camera = new Camera();
  
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
    private Vector2 NW, SE;
    private Vector2 screenNW, screenSE;
    private boolean isMoving = false;
    private Affine2 transform = new Affine2();
    private boolean resizeNW = false;
    private boolean resizeSE = false;
    private int bufferWidth, bufferHeight;
    private Slider pixelate;
    public boolean isRecording = false;
    
    public Camera() {
      pixelate = cp5.addSlider("campixelate")
        .setCaptionLabel("")
        .setPosition(100,50)
        .setSize(0, 12)
        .setRange(0.1, 2)
        .setValue(PPU)
        .plugTo(this, "setPPU")
        .hide()
        ;
    }
    
    public void resize() {
      bufferWidth = ceil((SE.x - NW.x) * PPU);
      bufferHeight = ceil((SE.y - NW.y) * PPU);
      bufferedRenderer.setBufferSize(bufferWidth, bufferHeight);
    }
    
    public void hide() {
      isVisible = false;
      pixelate.hide();
    }
    
    public void show() {
      isVisible = true;
      pixelate.show();
    }
    
    public void draw(Affine2 transform) {
      screenNW.set(NW);
      transform.applyTo(screenNW);
      camera.screenSE.set(SE);
      transform.applyTo(screenSE);
        
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
        
        fill(255);
        noStroke();
        rect(screenNW.x, screenNW.y, screenSE.x-screenNW.x, screenSE.y-screenNW.y);
        // Sets the texture filtering to NEAREST sampling
        ((PGraphicsOpenGL)g).textureSampling(2);
        image(bufferedRenderer.getBuffer(), screenNW.x, screenNW.y, bufferWidth*transform.m00/PPU, bufferHeight*transform.m11/PPU);
      }
      
      noFill();
      stroke(0, 64, 255);
      strokeWeight(2);
      rect(screenNW.x, screenNW.y, screenSE.x-screenNW.x, screenSE.y-screenNW.y);
      // Resize handles
      square(screenNW.x-4, screenNW.y-4, 8);
      square(screenSE.x-4, screenSE.y-4, 8);
      
      int w = ceil((SE.x - NW.x) * PPU);
      int h = ceil((SE.y - NW.y) * PPU);
      String strBufSize = str(w) + " × " + str(h);
      fill(0);
      textSize(14);
      text(strBufSize, screenSE.x + 12, screenSE.y + 16);
      
      pixelate.setPosition(screenNW.x, screenSE.y + 4)
        .setSize(floor(screenSE.x - screenNW.x), 12);
    }
    
    public void setPPU() {
      float newVal = pixelate.getValue();
      // event keeps getting fired
      if (newVal != PPU) {
        PPU = newVal;
        resize();
      }
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
        
    //partsMenu = new ContextMenu();
    /*
    partsList = (PartsList) new PartsList(cp5, "partslist")
      .setLabel("parts list")
      .setPosition(margin, margin)
      .setHeight(height-2*margin)
      .setItemHeight(menuBarHeight)
      .hide();
    ;
    */
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
    //bufferedRenderer.setBackgroundColor(1, 1, 1, 1);
    camera.show();
    camera.isRecording = true;
    //bufferedRenderer.startRecording(transport.getCounter());
  }
  
  
  public void stopRecording() {
    //bufferedRenderer.stopRecording();
    framerate = defaultFramerate;
    camera.isRecording = false;
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
        renderer.drawPivot();
        
        // Draw bounding box
        noFill();
        float green = (64 + 32 * MathUtils.sin(TWO_PI * (millis() % 600) / 600 ));
        stroke(255, green, 0);
        strokeWeight(2 + 0.6 * MathUtils.sin(TWO_PI * (millis() % 600) / 600 ));
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
        circle(bbSE.x, bbNW.y, 8);
        square(bbNW.x-4, bbNW.y-4, 8);
        square(bbSE.x-4, bbSE.y-4, 8);
        popMatrix();
      }
      
      if (camera.isVisible) {
        camera.draw(transform); //<>//
        
        if (camera.isRecording && playing) {
          println("rec");
          if (remainingFrames > 0) {
            PImage buffer = bufferedRenderer.getBuffer();
            buffer.save(String.format("frames/frame-%03d.png", transport.getCounter()));
            remainingFrames--;
            transport.increaseCounter();
            if (remainingFrames == 0) {
              stopRecording();
              transport.buttonRec.setOff();
            }
          }
        }
      } else {
        renderer.drawMarker(0, 0);
        renderer.drawAxes();
      }
    }
    renderer.popMatrix();
    
    if (playing == false && (frameCount>>5) % 2 == 0) {
      fill(255, 0, 0, 127);
      textSize(32);
      text("PAUSED", -60 + width/2, height - 80);
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
    //partsList.open().show();
    transport.show();
    renderer.setSelected(selected);
    if (timeline != null)
      timeline.show();
  }
  
  public void hideUI() {
    showUI = false;
    if (accordion != null)
      accordion.hide();
    //partsList.hide();
    camera.hide();
    contextMenu.hide();
    transport.hide();
    renderer.setSelected(null);
    if (timeline != null)
      timeline.hide();
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
      }
      else if (avatar != null && key == CODED) {
        if (keyCode == LEFT) {
          transport.prevPosture();
        } else if (keyCode == RIGHT) {
          transport.nextPosture();
        }
      }
      else {
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
        case 'a':  // Select root node
          if (avatar != null)
            select(avatar.getShape());
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
        case 'k':  // Camera
          if (!camera.isVisible) {
            if (camera.NW == null) {
              BoundingBox bb = avatar.getShape().getBoundingBox();
              camera.NW = new Vector2(bb.left, bb.top);
              camera.SE = new Vector2(bb.right, bb.bottom);
              camera.screenNW = new Vector2();
              camera.screenSE = new Vector2();
              camera.resize();
            }
            camera.show();
          } else {
            camera.hide();
          }
          break;
        case 's':  // Save file
          if (avatar != null && postureCollectionDirty) {
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
    //if (!partsList.isInside()) {
      float z = pow(1.12, -event.getCount());
      Vector2 point = getWorldPos(mouseX, mouseY);
      transform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);  // scale translation by the zoom factor
    //}
  }
  
  
  void mousePressed(MouseEvent event) {
    mouseClickBtn = event.getButton();
    mouseClickPos.set(mouseX, mouseY);
    Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
    if (transport.contains(mouseX, mouseY))
      transport.isMoving = true;
    else if (timeline != null && timeline.contains(mouseX, mouseY))  // Move timeline box
      timeline.isMoving = true;
    else if (camera.isVisible) {
      if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, camera.NW.x, camera.NW.y) < 10/transform.m00)
        camera.resizeNW = true;
      else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, camera.SE.x, camera.SE.y) < 10/transform.m00)
        camera.resizeSE = true;
      else if (isInsideBox(mouseX, mouseY, camera.screenNW, camera.screenSE))
        camera.isMoving = true;
    }
    else if (selected != null) {  // Scale or rotate part
      BoundingBox bb = selected.getBoundingBox();
      if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, bb.left, bb.top) < 10/transform.m00)
        partScalingNW = true;
      else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, bb.right, bb.bottom) < 10/transform.m00)
        partScalingSE = true;
      else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, bb.right, bb.top) < 10/transform.m00)
        partRotating = true;
    }
  }
  
  
  void mouseReleased(MouseEvent event) {
    transport.isMoving = false;
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
      camera.resize();
      camera.resizeNW = false;
      camera.resizeSE = false;
    }
    
    if (avatar != null)
      avatar.paused = false;
  }


  void mouseClicked(MouseEvent event) {
    if (event.getButton() == LEFT) {
      if (setPivot && !controllerClicked) {
        // Place new pivot
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        selected.getAbsoluteTransform().inv().applyTo(mouseWorldPos);
        selected.setLocalOrigin(mouseWorldPos);
        setPivot = false;
        playing = true; // Is this necessary ?
      }
      else if (!controllerClicked) {
        // Select a part
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        ComplexShape[] parts = avatar.getPartsList();
        selectedIndex = 0;
        ComplexShape clickedPart = null;

        for (int i = parts.length-1; i >= 0; i--) {
          if (parts[i].contains(mouseWorldPos)) {
            clickedPart = parts[i];
            break;
          }
        }
        select(clickedPart);
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
    float drag_distance = mouseClickPos.dst2(mouseX, mouseY);
    Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
    
    if (mouseClickBtn == LEFT) {      
      if (partMoving) {
        Affine2 tr = new Affine2();
        tr.setToTranslation(dx/transform.m00, dy/transform.m11);    // scale translation by the zoom factor
        selected.softTransform(tr);
        setFileDirty();
        
        // Transform physics shell if necessary
        /*
        if (selected == avatar.shape) {
          for (Shape shape : avatar.physicsShapes)
            shape.hardTransform(tr);
        }*/
      }
      else if (partScalingNW) {
        avatar.paused = true;
        avatar.resetAnimation();
        BoundingBox bb = selected.getBoundingBox();
        Vector2 dim = bb.getDimensions();
        float sx = max(0.2f, bb.right - mouseWorldPos.x) / dim.x;
        float sy = max(0.2f, bb.bottom - mouseWorldPos.y) / dim.y;
        Affine2 tr = new Affine2();
        tr.translate(bb.right, bb.bottom).scale(sx, sy).translate(-bb.right, -bb.bottom);
        selected.softTransform(tr);
        setFileDirty();
      }
      else if (partScalingSE) {
        avatar.paused = true;
        avatar.resetAnimation();
        BoundingBox bb = selected.getBoundingBox();
        Vector2 dim = bb.getDimensions();
        float sx = max(0.2f, mouseWorldPos.x - bb.left) / dim.x;
        float sy = max(0.2f, mouseWorldPos.y - bb.top) / dim.y;
        Affine2 tr = new Affine2();
        tr.translate(bb.left, bb.top).scale(sx, sy).translate(-bb.left, -bb.top);
        selected.softTransform(tr);
        setFileDirty();
      }
      else if (partRotating) {
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
      }
      else if (camera.isMoving) {
        camera.NW.add(dx/transform.m00, dy/transform.m11);
        camera.SE.add(dx/transform.m00, dy/transform.m11);
      }
      else if (camera.resizeNW) {
        if (keyPressed && keyCode == 16)
          println("keypressed", keyCode);
        camera.NW.add(dx/transform.m00, dy/transform.m11);
        camera.NW.x = min(camera.NW.x, camera.SE.x - 1);
        camera.NW.y = min(camera.NW.y, camera.SE.y - 1);
      }
      else if (camera.resizeSE) {
        camera.SE.add(dx/transform.m00, dy/transform.m11);
        camera.SE.x = max(camera.SE.x, camera.NW.x + 1);
        camera.SE.y = max(camera.SE.y, camera.NW.y + 1);
      }
      else if (!controllerClicked) {
        if (selected != null && isInsideBox(mouseClickPos.x, mouseClickPos.y, bbNW, bbSE) && drag_distance > 300) {
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
      } else if (timeline != null && timeline.isMoving) {
        timeline.move(dx, dy);
      }
    }
    
    else if (mouseClickBtn == RIGHT) {
        // scale translation by the zoom factor
        transform.translate(dx/transform.m00, dy/transform.m11);
    }
  }
}


boolean isInside(Vector2 pos, Vector2 nw, Vector2 se) {
  return isInsideBox(pos.x, pos.y, nw, se);
}

boolean isInsideBox(float x, float y, Vector2 nw, Vector2 se) {
  return x > nw.x && x < se.x && y > nw.y && y < se.y;
}
