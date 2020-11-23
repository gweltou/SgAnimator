// TODO:
  // Prompt to load Geometry and/or Animations when loading a file
  
  // Add a chart for every Animation to show function progression over time
  
  // Animation swap bar
  // Add a textField to name Animations
  

import com.badlogic.gdx.graphics.*;
import com.badlogic.gdx.math.*;
import com.badlogic.gdx.utils.*;
import gwel.spacegame.anim.*;
import gwel.spacegame.graphics.*;

import controlP5.*;

import java.util.Deque;
import java.util.ArrayDeque;
import java.util.*;


String version = "0.1";


Renderer renderer;
PolygonParser pp;
ControlP5 cp5;
Accordion accordion;
ComplexShape rootShape;
String baseFilename;
Affine2 transform;
ComplexShape selected = null;
int selected_idx = 0;
ArrayList<ComplexShape> parts;
String[] partsName;
String[] functionsName;
Animation animationClipboard;
float lastTime;

boolean showUI = false;
boolean paramLocked = false;
boolean setHinge = false;
boolean playAnim = true;
boolean mustUpdateUI = false;



void settings() {
  size(800, 600);
}


void setup() {
  surface.setResizable(true);
  
  renderer = new Renderer(this);
  transform = new Affine2();
  
  pp = new PolygonParser();
  
  //rootShape = buildAnimMesh();
  //rootShape = buildBlob();
  //parts = rootShape.getPartsList();
  
  int numFn = Animation.timeFunctions.length;
  functionsName = new String[numFn];
  for (int i=0; i<numFn; i++) {
    int idx = Animation.timeFunctions[i].getName().lastIndexOf('.');
    functionsName[i] = Animation.timeFunctions[i].getName().substring(idx+3);
  }
  
  setupUI();
  textSize(20);
  
  lastTime = (float) millis() / 1000.0f;
}


ComplexShape buildBlob() {
  // A try at a generative rigging
  int n = 10;
  
  ComplexShape root = new ComplexShape();
  ComplexShape parent = root;
  float x = 0;
  for (int i=0; i<n; i++) {
    ComplexShape segment = new ComplexShape();
    segment.addShape(new Circle(x, 0, 20));
    float[] verts = {x, 10, x+50, 6, x+50, -6, x, -10};
    segment.addShape(new Polygon(verts, null));
    segment.setLocalOrigin(x, 0);
    ArrayList<Animation> anims = new ArrayList();
    anims.add(new Animation(new TFSin(0.2f, 0.3f, 0f, x*0.012f), Animation.AXE_ROT));
    segment.setAnimationList(anims);
    parent.addShape(segment);
    parent = segment;
    x += 50;
  }
  return root;
}


void select(ComplexShape part) {
  println(part);
  showUI = true;
  selected = part;
  updateUI();
  renderer.setSelected(part);
}


void draw() {
  float time = (float) millis() / 1000.0f;
  background(255);
  
  if (rootShape != null) {
    renderer.pushMatrix(transform);
    if (playAnim)
      rootShape.updateAnimation(time-lastTime);
    rootShape.draw(renderer); //<>//
    if (showUI) {
      renderer.drawPivot();
      renderer.drawMarker(0, 0);
    }
    renderer.popMatrix();
  } else {
    fill(0);
    text("CTRL+o\n"+
         "CTRL+s\n"+
         "Up/Down\n"+
         "p\n"+
         "r\n"+
         "d\n"+
         "right click\n", width/4, height/4);
    text("Open file (svg or json)\n"+
         "Save json file\n"+
         "Select next/previous shape group\n"+
         "play/pause animation\n"+
         "reset animation\n"+
         "display/hide UI\n"+
         "show context menu\n", width/2, height/4);
    text("Ver. "+version, width-110, height-20);
  }
  
  stroke(0, 0, 255);
  noFill();
  if (setHinge) {
    fill(255, 0, 0);
    noStroke();
    ellipse(mouseX, mouseY, 8, 8);
  }
  
  if (mustUpdateUI == true) {
    updateUI();
    mustUpdateUI = false;
  }
  
  lastTime = time;
}
