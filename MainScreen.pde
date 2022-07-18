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
  
  // Camera
  private boolean showCamera = false;
  private int camPPU = 1; // Pixels per unit
  private Vector2 camNW, camSE;
  private Vector2 camScreenNW, camScreenSE;
  private boolean camMoving = false;
  private Affine2 camTransform = new Affine2();
  private boolean camResizeNW = false;
  private boolean camResizeSE = false;
  
  private PShader pixelate = loadShader("pixelate.glsl");
  
  private int mouseClickBtn;
  private Vector2 mouseClickPos = new Vector2();
  private boolean partMoving = false;
  private boolean partScalingNW = false;
  private boolean partScalingSE = false;
  private boolean partRotating = false;
  private float partRotation = 0f;
  
  private Vector2 bbNW, bbSE; // Selection's bounding box
  

  public MainScreen() {
    transform = new Affine2().setToTranslation(width/2, height/2);
    bbNW = new Vector2();
    bbSE = new Vector2();
    
    // CP5 UI
    transport = new Transport();
    accordion = new FunctionAccordion(cp5, "accordion"); 
    contextMenu = new ContextMenu();
        
    //partsMenu = new ContextMenu();
    
    partsList = (PartsList) new PartsList(cp5, "partslist")
      .setLabel("parts list")
      .setPosition(margin, margin)
      .setHeight(height-2*margin)
      .setItemHeight(menuBarHeight)
      .hide();
    ;
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
    bufferedRenderer.setBackgroundColor(1, 1, 1, 1);
    bufferedRenderer.startRecording(transport.getCounter());
  }
  
  
  public void stopRecording() {
    bufferedRenderer.stopRecording();
    framerate = defaultFramerate;
  }
  
  
  public void draw() {
    if (clearBackground || showUI)
      background(255);
    
    renderer.pushMatrix(transform);
    
    if (avatar != null) {
      if (playing)
        avatar.update(1f/framerate);
      avatar.draw(renderer);
      
      if (bufferedRenderer.isRecording() && playing) {
        bufferedRenderer.flush();
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
      
      if (showCamera) {
        /*Affine2 unproject = new Affine2(transform).inv();
        Vector2 screenTopLeft = new Vector2(0, 0);
        unproject.applyTo(screenTopLeft);
        screenTopLeft.sub(camNW);*/
        
        Vector2 translation = new Vector2(-camNW.x, -camNW.y);
        camTransform.setToTranslation(translation);
        
        bufferedRenderer.pushMatrix(camTransform);
        bufferedRenderer.beginDraw();
        bufferedRenderer.clear();
        avatar.draw(bufferedRenderer); //<>//
        bufferedRenderer.endDraw();
        bufferedRenderer.popMatrix();
        
        //int w = round(se.x-nw.x);
        //int h = round(se.y-nw.y);
        //pixelate.set("resolution", w, h);
        //pixelate.set("aspect_ratio", h/float(w));
        //pixelate.set("amount", 32f);
        //PImage imgBuffer = get(round(nw.x), round(nw.y), w, h);
        //pixelate.set("tex", imgBuffer);
        //shader(pixelate);
        //noStroke();
        //rect(nw.x, nw.y, se.x-nw.x, se.y-nw.y);
        //resetShader();
        
        camScreenNW.set(camNW);
        transform.applyTo(camScreenNW);
        camScreenSE.set(camSE);
        transform.applyTo(camScreenSE);
        //image(bufferedRenderer.getBuffer(), camScreenNW.x, camScreenNW.y);
        int camHeight = ceil((camSE.y - camNW.y) * camPPU);
        image(bufferedRenderer.getBuffer(), 0, height-camHeight);
        
        noFill();
        stroke(0, 64, 255);
        strokeWeight(2);
        rect(camScreenNW.x, camScreenNW.y, camScreenSE.x-camScreenNW.x, camScreenSE.y-camScreenNW.y);
        // Resize handles
        square(camScreenNW.x-4, camScreenNW.y-4, 8);
        square(camScreenSE.x-4, camScreenSE.y-4, 8);
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
  

  void keyPressed(KeyEvent event) {
    if (avatar != null && key == CODED) {
      /*if (keyCode == UP) {  // Select next part
        selectedIndex = (selectedIndex-1);
        if (selectedIndex < 0)
          selectedIndex += avatar.getPartsList().length;
        partsList.setValue(selectedIndex);
      } else if (keyCode == DOWN) {  // Select previous part
        selectedIndex = (selectedIndex+1) % avatar.getPartsList().length;
        partsList.setValue(selectedIndex);
      } else*/ if (keyCode == LEFT) {
        transport.prevPosture();
      } else if (keyCode == RIGHT) {
        transport.nextPosture();
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
        if (showCamera == false) {
          if (camNW == null) {
            BoundingBox bb = avatar.getShape().getBoundingBox();
            camNW = new Vector2(bb.left, bb.top);
            camSE = new Vector2(bb.right, bb.bottom);
            camScreenNW = new Vector2();
            camScreenSE = new Vector2();
            int bufferWidth = ceil((camSE.x - camNW.x) * camPPU);
            int bufferHeight = ceil((camSE.y - camNW.y) * camPPU);
            println(bufferWidth, bufferHeight);
            bufferedRenderer.setBufferSize(bufferWidth, bufferHeight);
          }
          showCamera = true;
        } else {
          showCamera = false;
        }
        break;
      case 15:  // CTRL+o, load a new file
        selectInput("Select a file", "inputFileSelected");
        //loadScreen = new LoadScreen();
        break;
      case 19: // CTRL+s, save
        selectOutput("Select a file", "outputFileSelected");
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


  void keyReleased(KeyEvent event) {
    if (key == CODED && keyCode == SHIFT && selected != null && !isNumberboxActive) {
      //playing = true;
      mustUpdateUI = true;
      setPostureCollectionDirty();
    }
  }



  void mouseWheel(MouseEvent event) {
    contextMenu.hide();
    if (!partsList.isInside()) {
      float z = pow(1.12, -event.getCount());
      Vector2 point = getWorldPos(mouseX, mouseY);
      transform.translate(point.x, point.y).scale(z, z).translate(-point.x, -point.y);  // scale translation by the zoom factor
    }
  }
  
  
  void mousePressed(MouseEvent event) {
    mouseClickBtn = event.getButton();
    mouseClickPos.set(mouseX, mouseY);
    Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
    if (transport.contains(mouseX, mouseY))
      transport.isMoving = true;
    else if (timeline != null && timeline.contains(mouseX, mouseY))  // Move timeline box
      timeline.isMoving = true;
    else if (showCamera) {
      if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, camNW.x, camNW.y) < 10/transform.m00)
        camResizeNW = true;
      else if (Vector2.dst(mouseWorldPos.x, mouseWorldPos.y, camSE.x, camSE.y) < 10/transform.m00)
        camResizeSE = true;
      else if (isInsideBox(mouseX, mouseY, camScreenNW, camScreenSE))
        camMoving = true;
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
    camMoving = false;
    partScalingNW = false;
    partScalingSE = false;
    partRotating = false;
    partRotation = 0f;
    
    if (camResizeNW || camResizeSE) {
      int bufferWidth = ceil((camSE.x - camNW.x) * camPPU);
      int bufferHeight = ceil((camSE.y - camNW.y) * camPPU);
      println(bufferWidth, bufferHeight);
      bufferedRenderer.setBufferSize(bufferWidth, bufferHeight);
      camResizeNW = false;
      camResizeSE = false;
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
        setPostureCollectionDirty();
        
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
        setPostureCollectionDirty();
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
        setPostureCollectionDirty();
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
        setPostureCollectionDirty();
      }
      else if (camMoving) {
        camNW.add(dx/transform.m00, dy/transform.m11);
        camSE.add(dx/transform.m00, dy/transform.m11);
      }
      else if (camResizeNW) {
        camNW.add(dx/transform.m00, dy/transform.m11);
      }
      else if (camResizeSE) {
        camSE.add(dx/transform.m00, dy/transform.m11);
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
