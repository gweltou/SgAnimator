// TODO:
//    Delete function button
//    Copy and Paste buttons


import com.badlogic.gdx.graphics.*;
import com.badlogic.gdx.math.*;
import com.badlogic.gdx.utils.*;
import gwel.spacegame.anim.*;
import gwel.spacegame.graphics.*;

import controlP5.*;

import java.util.Deque;
import java.util.ArrayDeque;
import java.util.*;


boolean DEBUG = false;

Renderer renderer;
PolygonParser pp;
ControlP5 cp5;
Accordion accordion;
Textlabel partLabel;
ComplexShape rootShape;
File animFile = new File("/home/gweltaz/Dropbox/Projets/art generatif/processing/SgAnimator/anim.json");
String baseFilename;
Affine2 transform;
ComplexShape selected = null;
int selected_idx = 0;
ArrayList<ComplexShape> parts;
String[] functionNames;
float lastTime;

boolean showUI = false;
boolean paramLocked = true;
boolean setHinge = false;
boolean playAnim = true;
boolean mustUpdateUI = false;



void setup() {
  size(680, 600);
  
  renderer = new Renderer(this);
  transform = new Affine2();
  
  pp = new PolygonParser();
  
  //rootShape = buildAnimMesh();
  //rootShape = buildBlob();
  //parts = rootShape.getPartsList();
  
  int numFn = Animation.timeFunctions.length;
  functionNames = new String[numFn];
  for (int i=0; i<numFn; i++) {
    int idx = Animation.timeFunctions[i].getName().lastIndexOf('.');
    functionNames[i] = Animation.timeFunctions[i].getName().substring(idx+3);
  }
  
  //printArray(PFont.list());
  defaultFont = createFont("DejaVu Sans Mono", 12);

  cp5 = new ControlP5(this);
  partLabel = cp5.addTextlabel("label")
    .setPosition(width-80, 20)
    .setFont(createFont("DejaVu Sans Mono", 24))
    .setColorValue(0x00000000);
  
  lastTime = (float) millis() / 1000.0f;
  
  textSize(20);
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
    segment.addShape(new Polygon(verts));
    segment.setLocalOrigin(x, 0);
    segment.setAnimation(new Animation(new TFSin(0.2f, 0.3f, 0f, x*0.012f), Animation.AXE_ROT));
    parent.addShape(segment);
    parent = segment;
    x += 50;
  }
  return root;
}


ComplexShape buildAnimMesh() {
  ComplexShape shape = loadGeometry(sketchFile("dessin.tdat"));
  
  float phase = random(PI);
  float phase2 = random(PI);
  
  Animation animHead = new Animation(new TFSin(2.1f, 0.05f, 0f, phase2), Animation.AXE_ROT);
  shape.getById("head").setAnimation(animHead);
  Animation animOg = new Animation(new TFRandomSmooth(4f, 0.1f, -0.18f, 0.1f, .1f), Animation.AXE_ROT);
  shape.getById("og").setAnimation(animOg);
  Animation animOd = new Animation(new TFRandomSmooth(4f, 0.1f, 0.18f, -0.1f, .1f), Animation.AXE_ROT);
  shape.getById("od").setAnimation(animOd);
  Animation animNpd = new Animation(new TFSin(3f, 0.05f, 0f, phase+3.6f), Animation.AXE_ROT);
  shape.getById("npd").setAnimation(animNpd);
  Animation animNpg = new Animation(new TFSin(3f, -0.05f, 0f, phase+3.6f), Animation.AXE_ROT);
  shape.getById("npg").setAnimation(animNpg);
  Animation animEyes = new Animation(new TFEyes(7f, 0.05f, 0.8f, 0.2f, 1), Animation.AXE_SY);
  shape.getById("eyes").setAnimation(animEyes);
  Animation animBody = new Animation(new TFSin(3f, 2f, 0f, phase), Animation.AXE_Y);
  shape.getById("body").setAnimation(animBody);
    
  return shape;
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
    text("CTRL+o\n"+
         "CTRL+s\n"+
         "p\n"+
         "r\n"+
         "d\n", width/4, height/4);
    text("Open file (svg or json)\n"+
         "Save json file\n"+
         "play/pause animation\n"+
         "reset animation\n"+
         "display/hide UI\n", width/2, height/4);
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
