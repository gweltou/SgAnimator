// TODO:
// programme python "key-mon" pour afficher les touches du clavier

// Record images key ('r')
// Draw Coordinate's lines on editor
// Ability to scale Avatar to normalise objects sizes according to a standard ref (1m)
// Elastic function
// Arrondir à 2 décimales les floats à sauvegarder dans les json
// Option to duplicate previous AnimationCollection when new animCollection
// UV coords in polygon class
// Add a chart for every Animation to show function progression over time
// Lib : avatar.playSequencialy()

/*
  BUGS:
 * Seule la première animation est sauvegardée
 * Can't select axe before function
 * Resize window doesn't resize UI immediately
 
 Done:

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


String version = "0.6.4";


MainScreen mainScreen;
LoadScreen loadScreen;
Screen welcomeScreen;
Screen helpScreen1;
Screen helpScreenEasing;
Screen currentScreen;

MyRenderer renderer;
Avatar avatar;
String baseFilename;

ComplexShape selected = null;
int selectedIndex = 0;
String[] partsName;
String[] functionsName;
AnimationCollection animationCollection;
int postureIndex = 0;
boolean fullAnimationDirty = false;
Animation animationClipboard;
float lastTime;

boolean showUI = false;
boolean paramLocked = false;
boolean setPivot = false;
boolean playAnim = true;
boolean mustUpdateUI = false;
File mustLoad = null; // Change current screen to loading screen


void settings() {
  //size(1200, 700);
  size(800, 600);
  //fullScreen();
}


void setup() {
  surface.setResizable(true);
  surface.setTitle("Avatar5");

  mainScreen = new MainScreen();
  welcomeScreen = new WelcomeScreen();
  helpScreen1 = new HelpScreen1();
  helpScreenEasing = new HelpScreenEasing();
  currentScreen = welcomeScreen;
  
  renderer = new MyRenderer(this);

  int numFn = Animation.timeFunctions.length;
  functionsName = new String[numFn];
  for (int i=0; i<numFn; i++) {
    int idx = Animation.timeFunctions[i].getName().lastIndexOf('.');
    functionsName[i] = Animation.timeFunctions[i].getName().substring(idx+3);
  }

  setupUI();

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
    segment.addShape(new DrawableCircle(x, 0, 20));
    float[] verts = {x, 10, x+50, 6, x+50, -6, x, -10};
    segment.addShape(new DrawablePolygon(verts, null));
    segment.setLocalOrigin(x, 0);
    Animation[] anims = new Animation[1];
    anims[0] = new Animation(new TFSin(0.2f, 0.3f, 0f, x*0.012f), Animation.AXE_ROT);
    segment.setAnimationList(anims);
    parent.addShape(segment);
    parent = segment;
    x += 50;
  }
  return root;
}



void select(ComplexShape part) {
  showUI = true;
  selected = part;
  updateUI();
  renderer.setSelected(part);
}



void savePosture(String postureName, int animIndex) {
  HashMap<String, Animation[]> posture = new HashMap();

  if (postureName == null || postureName.trim().isEmpty())
    postureName = "posture"+animIndex;

  for (ComplexShape part : avatar.getPartsList()) {
    if (part.getAnimationList().length > 0)
      posture.put(part.getId(), part.getAnimationList());
  }

  if (animIndex >= animationCollection.size()) {
    animationCollection.addPosture(postureName, posture);
  } else {
    animationCollection.updatePosture(animIndex, postureName, posture);
  }

  fullAnimationDirty = false;
}


void draw() {
  if (mustLoad != null) {
    loadScreen.setupUI(mustLoad);
    currentScreen = loadScreen;
    mustLoad = null;
  }

  currentScreen.draw();
}


public void keyPressed(KeyEvent event) { currentScreen.keyPressed(event); }
public void keyReleased(KeyEvent event) { currentScreen.keyReleased(event); }
public void mouseClicked(MouseEvent event) {currentScreen.mouseClicked(event); }
public void mouseWheel(MouseEvent event) { currentScreen.mouseWheel(event); }
public void mouseDragged(MouseEvent event) { currentScreen.mouseDragged(event); }


public abstract class Screen {
  public void draw() { }
  
  public void keyPressed(KeyEvent event) { }
  public void keyReleased(KeyEvent event) { }
  public void mouseClicked(MouseEvent event) { }
  public void mouseWheel(MouseEvent event) { }
  public void mouseDragged(MouseEvent event) { }
}
