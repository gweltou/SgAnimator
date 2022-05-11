ContextMenu contextMenu;
//ContextMenu partsMenu;
FunctionAccordion accordion;

public class MainScreen extends Screen {
  Affine2 transform;
  //private float[] selectedColorMod = new float[] {0.1f, 0.1f, 0.1f, 0.4f};
  
  private float defaultFramerate = frameRate;
  private float recordingFramerate = 25f;
  private float framerate = defaultFramerate;
  private int remainingFrames = 0;
  private boolean clearBackground = true;
  private float timeScale = 1f;
  
  private int mouseClickBtn;
  private Vector2 mouseClickPos = new Vector2();
  private boolean partMoving = false;
  private boolean partScalingNW = false;
  private boolean partScalingSE = false;
  private boolean partRotating = false;
  private float partRotation = 0f;
  
  Vector2 bb_nw, bb_se; // Selection's bounding box
  

  public MainScreen() {
    transform = new Affine2().setToTranslation(width/2, height/2);
    bb_nw = new Vector2();
    bb_se = new Vector2();
    
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
    renderer.setBackgroundColor(1, 1, 1, 1);
    renderer.startRecording(transport.getCounter());
  }
  
  
  public void stopRecording() {
    renderer.stopRecording();
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
          bb_nw.set(bb.left, bb.top);
          bb_se.set(bb.right, bb.bottom);
          transform.applyTo(bb_nw);
          transform.applyTo(bb_se);
        } else {
          translate((bb_nw.x+bb_se.x)*0.5, (bb_nw.y+bb_se.y)*0.5);
          rotate(partRotation);
          translate(-(bb_nw.x+bb_se.x)*0.5, -(bb_nw.y+bb_se.y)*0.5);
        }
        rect(bb_nw.x, bb_nw.y, bb_se.x-bb_nw.x, bb_se.y-bb_nw.y);
        line(bb_nw.x, bb_nw.y, bb_se.x, bb_se.y);
        line(bb_nw.x, bb_se.y, bb_se.x, bb_nw.y);
        circle(bb_se.x, bb_nw.y, 8);
        square(bb_nw.x-4, bb_nw.y-4, 8);
        square(bb_se.x-4, bb_se.y-4, 8);
        popMatrix();
      }
      
      renderer.drawMarker(0, 0);
      renderer.drawAxes();
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
      if (keyCode == UP) {  // Select next part
        selectedIndex = (selectedIndex-1);
        if (selectedIndex < 0)
          selectedIndex += avatar.getPartsList().length;
        partsList.setValue(selectedIndex);
      } else if (keyCode == DOWN) {  // Select previous part
        selectedIndex = (selectedIndex+1) % avatar.getPartsList().length;
        partsList.setValue(selectedIndex);
      } else if (keyCode == LEFT) {
        transport.prevPosture();
      } else if (keyCode == RIGHT) {
        transport.nextPosture();
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
      //playing = true;
      mustUpdateUI = true;
      setAnimationCollectionDirty();
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
    if (transport.contains(mouseX, mouseY))
      transport.isMoving = true;
    else if (timeline != null && timeline.contains(mouseX, mouseY))
      timeline.isMoving = true;
    else if (selected != null) {
      BoundingBox bb = selected.getBoundingBox();
      Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
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
    if (partMoving)
      println(selected.getBoundingBox());
    partMoving = false;
    partScalingNW = false;
    partScalingSE = false;
    partRotating = false;
    partRotation = 0f;
    
    if (avatar != null)
      avatar.paused = false;
  }


  void mouseClicked(MouseEvent event) {
    if (event.getButton() == LEFT) {
      // TODO : rewrite this shit
      if (setPivot && !cp5.getController("pivotbtn").isInside()) {
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        selected.setLocalOrigin(mouseWorldPos.x, mouseWorldPos.y);
        ((Button) cp5.getController("pivotbtn")).setOff();
        playing = true;
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
        contextMenu.display("importbtn");
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
    
    if (mouseClickBtn == LEFT) {      
      if (partMoving) {
        Affine2 tr = new Affine2();
        tr.setToTranslation(dx/transform.m00, dy/transform.m11);    // scale translation by the zoom factor
        selected.softTransform(tr);
        
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
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        BoundingBox bb = selected.getBoundingBox();
        Vector2 dim = bb.getDimensions();
        float sx = max(0.2f, bb.right - mouseWorldPos.x) / dim.x;
        float sy = max(0.2f, bb.bottom - mouseWorldPos.y) / dim.y;
        Affine2 tr = new Affine2();
        tr.translate(bb.right, bb.bottom).scale(sx, sy).translate(-bb.right, -bb.bottom);
        selected.softTransform(tr);
      }
      else if (partScalingSE) {
        avatar.paused = true;
        avatar.resetAnimation();
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        BoundingBox bb = selected.getBoundingBox();
        Vector2 dim = bb.getDimensions();
        float sx = max(0.2f, mouseWorldPos.x - bb.left) / dim.x;
        float sy = max(0.2f, mouseWorldPos.y - bb.top) / dim.y;
        Affine2 tr = new Affine2();
        tr.translate(bb.left, bb.top).scale(sx, sy).translate(-bb.left, -bb.top);
        selected.softTransform(tr);
      }
      else if (partRotating) {
        avatar.paused = true;
        avatar.resetAnimation();
        Vector2 pMouseWorldPos = getWorldPos(pmouseX, pmouseY);
        Vector2 mouseWorldPos = getWorldPos(mouseX, mouseY);
        //BoundingBox bb = selected.getBoundingBox();
        Vector2 center = getWorldPos((bb_nw.x+bb_se.x)*0.5, (bb_nw.y+bb_se.y)*0.5);
        pMouseWorldPos.sub(center);
        mouseWorldPos.sub(center);
        float angle = mouseWorldPos.angleRad(pMouseWorldPos);
        partRotation += angle;
        Affine2 tr = new Affine2();
        tr.translate(center).rotateRad(angle).translate(-center.x, -center.y);
        selected.softTransform(tr);
      }
      else {
        if (selected != null && isInsideBox(mouseClickPos.x, mouseClickPos.y, bb_nw, bb_se) && drag_distance > 300) {
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
