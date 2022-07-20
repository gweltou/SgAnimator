// programme python "key-mon" pour afficher les touches du clavier

// TODO:
// Revoir la fenêtre de sur-chargement de fichier (pour la version 1.8)
// Editor : Part selection menu when click on many overlaping parts
// Lib : Points de pivots différents par postures
// Lib : Part affine transform per posture
// Display bones (connected pivots)
// Option to reset control values (by double clicking on them ?)
// Elastic function
// Option to duplicate previous AnimationCollection when new animCollection
// UV coords in polygon class
// Lib : avatar.playSequentially()
// Ouverture de plusieurs fichiers avec Tabs
// Librairie d'Avatars à l'ouverture d'un fichier
// Add a chart for every Animation to show function progression over time

/*
  BUGS:
   * controllerClicked is not reseted after a mouse drag on a controller (eg. timeline sliders)
   * Check physics shapes after soft-transforming
   * fullscreen 
   * Resize window doesn't resize UI immediately (click on displaced controls are missed)
   * Part list disapearing (Remove part list header Bar)
 */


import com.badlogic.gdx.math.*;
import com.badlogic.gdx.utils.*;
import gwel.game.anim.*;
import gwel.game.graphics.*;
import gwel.game.entities.*;
import gwel.game.utils.*;

import controlP5.*;

import java.util.Deque;
import java.util.ArrayDeque;
import java.util.Collections;
import java.util.*;
import java.lang.reflect.Field;


String version = "0.8";
String appName = "SgAnimator " + version;


MainScreen mainScreen;
LoadScreen loadScreen;
Screen welcomeScreen;
Screen helpScreen1;
Screen helpScreenEasing;
Screen currentScreen;
Screen previousScreen;

MyRenderer renderer;
Avatar avatar;
String baseFilename;  // Used for window title and to save file (independent of its source format)

ComplexShape selected = null;
int selectedIndex = 0;
String[] functionsName;

PostureCollection postures;
int postureIndex = 0;
boolean postureCollectionDirty = false;  // When true, postures in editor are yet to be saved in avatar
Animation animationClipboard;

boolean showUI = false;
boolean paramLocked = false;
boolean setPivot = false;
boolean playing = true;
boolean mustUpdateUI = false;
File fileToLoad = null; // Change current screen to loadScreen

PFont defaultFont;


void settings() {
  //fullScreen();
  size(1024, 700);
  //size(800, 600, P2D);
}


void setup() {
  windowResizable(true);
  windowTitle(appName);
  
  cp5 = new ControlP5(this);
  defaultFont = createFont("DejaVu Sans Mono", 12);

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
}


void select(ComplexShape part) {
  showUI = true;
  selected = part;
  renderer.setSelected(part);
  if (selected == null) {
    cp5.remove("accordion");
    accordion = null;
  } else {
    avatar.getShape().invalidateBoundingBox(); // Fixes bb not updated between parts selection (which moves when playing)
    updateUI();
  }
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
  postureCollectionDirty = false;
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
  if (fileToLoad != null) {
    loadScreen.createModalBox(fileToLoad);
    previousScreen = currentScreen;
    currentScreen = loadScreen;
    fileToLoad = null;
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