// TODO:
// Animation.fromJSON et Animation.toJSON
// Draw Coordinate's lines on editor
// Ability to scale Avatar to normalise objects sizes according to a standard ref (1m)
// Prompt to load Geometry and/or Animations when loading a file
// Elastic function
// Negate toggle in Animations
// Generalize stop status on TimeFunctions
// Arrondir à 2 décimales les floats à sauvegarder dans les json
// Option to duplicate previous AnimationCollection when new animCollection
// Record images key ('r')
// Help screens

// UV coords in polygon class

// Add a chart for every Animation to show function progression over time

/*
  BUGS:
 * Copy/paste for TFimetable
 * can't load json when animation array is empty
 * ordre de la pile d'animation de réordonne bizarrement (après avoir ouvert un scrollablelist)
 
 */

import com.badlogic.gdx.graphics.*;
import com.badlogic.gdx.math.*;
import com.badlogic.gdx.utils.*;
import gwel.spacegame.anim.*;
import gwel.spacegame.graphics.*;
import gwel.spacegame.entities.*;

import controlP5.*;

import java.util.Deque;
import java.util.ArrayDeque;
import java.util.*;
import java.lang.reflect.Field;


String version = "0.4";


Renderer renderer;
Avatar avatar;
String baseFilename;
Affine2 transform;
Affine2 hardTransform;
ComplexShape selected = null;
int selected_idx = 0;
String[] partsName;
String[] functionsName;
AnimationCollection animationCollection;
int fullAnimationIndex = 0;
boolean fullAnimationDirty = false;
Animation animationClipboard;
float lastTime;

boolean showUI = false;
boolean paramLocked = false;
boolean setPivot = false;
boolean playAnim = true;
boolean mustUpdateUI = false;


void settings() {
  size(1366, 704);
  //fullScreen();
}


void setup() {
  surface.setResizable(true);
  surface.setTitle("Avatar5");

  renderer = new Renderer(this);
  transform = new Affine2();
  hardTransform = new Affine2 ();

  //rootShape = buildBlob();

  int numFn = Animation.timeFunctions.length;
  functionsName = new String[numFn];
  for (int i=0; i<numFn; i++) {
    int idx = Animation.timeFunctions[i].getName().lastIndexOf('.');
    functionsName[i] = Animation.timeFunctions[i].getName().substring(idx+3);
  }

  setupUI();

  lastTime = (float) millis() / 1000.0f;

  // Load a default file
  File f = new File("/home/gweltaz/Bureau/ruz.json");
  avatar = loadAvatarFile(f);
  partsName = new String[avatar.getPartsList().length];
  for (int i=0; i<partsName.length; i++) {
    partsName[i] = avatar.getPartsList()[i].getId();
  }
  partsList.setItems(partsName);
  animName.setText(animationCollection.getFullAnimationName(fullAnimationIndex));
  baseFilename = "/home/gweltaz/Bureau/ruz";
  showUI();
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



void saveFullAnimation(String animName, int animIndex) {
  HashMap<String, Animation[]> fullAnimation = new HashMap();

  if (animName == null || animName.trim().isEmpty())
    animName = "anim"+animIndex;

  for (ComplexShape part : avatar.getPartsList()) {
    if (!part.getAnimationList().isEmpty())
      fullAnimation.put(part.getId(), part.getAnimationList().toArray(new Animation[0]));
  }

  if (animIndex >= animationCollection.size()) {
    animationCollection.addFullAnimation(animName, fullAnimation);
  } else {
    animationCollection.updateFullAnimation(animIndex, animName, fullAnimation);
  }

  fullAnimationDirty = false;
}



void draw() {
  float time = (float) millis() / 1000.0f;
  background(255);

  if (avatar != null) {
    renderer.pushMatrix(transform);
    if (playAnim)
      avatar.updateAnimation(time-lastTime);
    avatar.draw(renderer);
    avatar.drawSelectedOnly(renderer);
    
    if (showUI) {
      renderer.drawPivot();
      renderer.drawMarker(0, 0);
      if (!hardTransform.isIdt() && selected != null) {
        renderer.pushMatrix(hardTransform);
        selected.setColorMod(1f, 1f, 1f, 0.4f);
        selected.draw(renderer);
        selected.setColorMod(1f, 1f, 1f, 1f);
        renderer.popMatrix();
      }
    }
    renderer.popMatrix();
    if (playAnim == false && (frameCount>>5)%2 == 0) {
      fill(255, 0, 0, 127);
      textSize(32);
      text("PAUSED", -60+width/2, height-80);
    }
    if (timeline != null) {
      timeline.highlightSliders();
    }
  } else {
    fill(0);
    textSize(20);
    text("CTRL+o\n"+
      "CTRL+s\n"+
      "Up/Down\n"+
      "p\n"+
      "r\n"+
      "d\n"+
      "right click\n"+
      "MAJ + right drag\n", width/4, height/4);
    text("Open file (svg or json)\n"+
      "Save json file\n"+
      "Select next/previous shape group\n"+
      "play/pause animation\n"+
      "reset animation\n"+
      "show/hide UI\n"+
      "place pivot\n"+
      "translate shape\n", width/2, height/4);
    text("Ver. "+version, width-110, height-20);
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

  lastTime = time;
}
