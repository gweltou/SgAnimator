// programme python "key-mon" pour afficher les touches du clavier

// TODO:
// Lib : Points de pivots différents par postures
// Elastic function
// Option to duplicate previous AnimationCollection when new animCollection
// UV coords in polygon class
// Add a chart for every Animation to show function progression over time
// Lib : avatar.playSequentially()
// Ouverture de plusieurs fichiers avec Tabs
// Librairie d'Avatars à l'ouverture d'un fichier

/*
  BUGS:
 * fullscreen 
 * Can't select axe before function
 * Resize window doesn't resize UI immediately (click on displaced controls are missed)
 * Part list disapearing (Remove part list header Bar)
 */


import com.badlogic.gdx.math.*;
import com.badlogic.gdx.utils.*;
import gwel.game.anim.*;
import gwel.game.graphics.*;
import gwel.game.entities.*;

import controlP5.*;

import java.util.Deque;
import java.util.ArrayDeque;
import java.util.*;
import java.lang.reflect.Field;


String version = "0.7.0";
String appName = "SgAnimator " + version;


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
String[] functionsName;
PostureCollection postures;
int postureIndex = 0;
boolean animationCollectionDirty = false;
Animation animationClipboard;

boolean showUI = false;
boolean paramLocked = false;
boolean setPivot = false;
boolean playing = true;
boolean mustUpdateUI = false;
File mustLoad = null; // Change current screen to loadScreen


void settings() {
  //fullScreen();
  size(1024, 700);
  //size(800, 600, P2D);
}


void setup() {
  surface.setResizable(true);
  surface.setTitle(appName);

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


void savePosture() {
  Posture posture = new Posture();

  String postureName = transport.postureName.getText();
  if (postureName == null || postureName.trim().isEmpty())
    postureName = "posture" + postureIndex;
  posture.name = postureName;

  posture.duration = transport.animDuration.getValue();

  Animation[][] groups = new Animation[avatar.getPartsList().length][];
  Arrays.fill(groups, null);
  for (int i = 0; i < groups.length; i++) {
    ComplexShape part = avatar.getPartsList()[i];
    if (part.getAnimationList().length > 0)
      groups[i] = part.getAnimationList();
  }
  posture.groups = groups;

  if (postureIndex >= postures.size()) {
    postures.addPosture(posture);
  } else {
    postures.updatePosture(postureIndex, posture);
  }

  avatar.postures = postures;

  animationCollectionDirty = false;
}


void drawKey(int x, int y, String k, float height) {
  textSize(floor(height * 0.5f));
  float margin = 0.1f * height;
  float wi = max(height - 2*margin, textWidth(k) + 10);
  float w = wi + 2*margin;
  fill(180);
  stroke(63);
  rect(x, y, w, height, 0.15f * height);
  fill(220);
  stroke(240);
  float hi = height * 0.8f;
  rect(x + margin, y + 0.8f*margin, wi, hi, 0.15f * hi);

  fill(0);
  text(k, x + 2*margin, y + hi - 1.5f*margin);
}


void draw() {
  if (mustLoad != null) {
    loadScreen.setupUI(mustLoad);
    currentScreen = loadScreen;
    mustLoad = null;
  }
  currentScreen.draw();
}


public void keyPressed(KeyEvent event) { 
  currentScreen.keyPressed(event);
}
public void keyReleased(KeyEvent event) { 
  currentScreen.keyReleased(event);
}
public void mousePressed(MouseEvent event) {
  currentScreen.mousePressed(event);
}
public void mouseReleased(MouseEvent event) {
  currentScreen.mouseReleased(event);
}
public void mouseClicked(MouseEvent event) {
  currentScreen.mouseClicked(event);
}
public void mouseWheel(MouseEvent event) { 
  currentScreen.mouseWheel(event);
}
public void mouseDragged(MouseEvent event) { 
  currentScreen.mouseDragged(event);
}


public abstract class Screen {
  public void draw() {
  }
  public void keyPressed(KeyEvent event) {
  }
  public void keyReleased(KeyEvent event) {
  }
  public void mousePressed(MouseEvent event) {
  }
  public void mouseReleased(MouseEvent event) {
  }
  public void mouseClicked(MouseEvent event) {
  }
  public void mouseWheel(MouseEvent event) {
  }
  public void mouseDragged(MouseEvent event) {
  }
}
