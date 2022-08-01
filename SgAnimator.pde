// programme python "key-mon" pour afficher les touches du clavier

// TODO:
// Rotation softtransform autour du point de pivot avec Maj
// Revoir la fenêtre de sur-chargement de fichier (pour la version 0.8)
// Editor : Part selection menu when click on many overlaping parts
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

/* IDÉES ABANDONNÉES :
 * Lib : Points de pivots différents par postures
*/

/*
  BUGS:
   * controllerClicked is not reseted after a mouse drag on a controller (eg. timeline sliders)
   * Check physics shapes after soft-transforming
   * Resize window doesn't resize UI immediately (click on displaced controls are missed)
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


String version = "1.0_a";
String appName = "SgAnimator " + version;


MainScreen mainScreen;
LoadScreen loadScreen;
Screen welcomeScreen;
Screen helpScreen1;
Screen helpScreenEasing;
Screen currentScreen;
Screen previousScreen;
Tooltip tooltip;

PRenderer renderer;
PGraphicsRenderer cameraRenderer;
Avatar avatar;
String baseFilename;  // Used for window title and to save file (independent of its source format)

ComplexShape selected = null;
PostureTree selectedPostureTree;
String[] functionsName;

//PostureCollection postures;
int postureIndex = 0;
boolean fileDirty = false;  // When true, postures in editor are yet to be saved in avatar
Animation animationClipboard;

boolean showUI = false;
boolean paramLocked = false;
boolean mustUpdateUI = false;
File fileToLoad = null; // Change current screen to loadScreen

PFont defaultFont, defaultFontSmall;
PFont titleFont;
PFont tooltipFont, tooltipFontSmall;
PFont iconFont;
PImage checkboard;


void settings() {
  //fullScreen();
  size(1024, 700);  // P2D renderer is needed to draw the chessboard texture under the camera, but it breaks SVG imports
  noSmooth();  // Needed for the camera view
}


void setup() {
  windowResizable(true);
  windowTitle(appName);
  
  // Sets the texture filtering to NEAREST sampling
  // Used by camera pixelisation with P2D renderer
  //((PGraphicsOpenGL) g).textureSampling(2);
  
  // Used for checkboard pattern
  textureWrap(REPEAT);
  
  cp5 = new ControlP5(this);
  titleFont = createFont("PrintBold-J5o.ttf", 48);
  defaultFont = createFont("DejaVu Sans Mono", 24);
  defaultFontSmall = createFont("DejaVu Sans Mono", 12);
  tooltipFont = createFont("PrintClearly-GGP.ttf", 32);
  tooltipFontSmall = createFont("PrintClearly-GGP.ttf", 25);
  iconFont = createFont("fa-solid-900.ttf", 20);
  checkboard = loadImage("checkboard.png");
  
  renderer = new PRenderer(this);
  cameraRenderer = new PGraphicsRenderer(this);
  
  tooltip = new Tooltip();
  mainScreen = new MainScreen();
  mainScreen.hideUI();
  welcomeScreen = new WelcomeScreen();
  helpScreen1 = new HelpScreen1();
  helpScreenEasing = new HelpScreenEasing();
  currentScreen = welcomeScreen;
  
  int numFn = TimeFunction.functionClasses.length;
  functionsName = new String[numFn];
  for (int i=0; i<numFn; i++) {
    int idx = TimeFunction.functionClasses[i].getName().lastIndexOf('.');
    functionsName[i] = TimeFunction.functionClasses[i].getName().substring(idx+3);
  }
  
  File toLoad = new File("/home/gweltaz/Bureau/svg/tete.json");
  loadJsonFile(toLoad);
}


void select(ComplexShape part) {
  showUI = true;
  selected = part;  
  //renderer.setSelected(part);
  if (selected == null) {
    cp5.remove("accordion");
    accordion = null;
  } else {
    selectedPostureTree = avatar.getCurrentPosture().getPostureTree().findByShape(selected);
    updateUI();
  }
}


void savePosture() {
  Posture posture = new Posture();

  String postureName = mainScreen.transport.postureName.getText();
  if (postureName == null || postureName.trim().isEmpty())
    postureName = "posture" + postureIndex;
  posture.setName(postureName);
  posture.setDuration(mainScreen.transport.animDuration.getValue());

  fileDirty = false;
}


void draw() {
  if (fileToLoad != null) {
    loadScreen.createModalBox(fileToLoad);
    previousScreen = currentScreen;
    currentScreen = loadScreen;
    fileToLoad = null;
  }
  currentScreen.draw();
  tooltip.update(17); // 17ms steps
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


void drawKey(int x, int y, String k, float height) {
  int fontSize = floor(height * 0.5f);
  if (fontSize <= 12)
    textFont(defaultFontSmall);
  else
    textFont(defaultFont);
  textSize(fontSize);
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


public class Tooltip {
  private String tip;
  private int textOffset;
  private int timer;
  private int duration;
  private final int fadeout = 600;
  private boolean error = false;
  private boolean small = false;
  
  public Tooltip() {
    timer = 0;
    duration = -999;
  }
  
  public void update(int timedelta) {
    timer += timedelta;
    int fadetime = max(0, duration+fadeout - timer);
    
    if (timer < duration) {
      fill(error ? #ff0000 : 0);
      if (small)
        textFont(tooltipFontSmall);
      else
        textFont(tooltipFont);
      text(tip, textOffset, height-20);
    } else if (fadetime > 0) {
      int alpha = round(map(fadetime, 0, fadeout, 0, 255));
      fill(error ? #ff0000 : 0, alpha);
      if (small)
        textFont(tooltipFontSmall);
      else
        textFont(tooltipFont);
      text(tip, textOffset, height-20);
    }
  }
  
  public void say(String s) {
    tip = s;
    timer = 0;
    duration = s.length() * 60;
    textFont(tooltipFont);
    int textWidth = floor(textWidth(s));
    textOffset = floor((width-textWidth) / 2);
    small = false;
    error = false;
    if (textOffset < 0) {
      small = true;
      textFont(tooltipFontSmall);
      textWidth = floor(textWidth(s));
      textOffset = floor((width-textWidth) / 2);
    }
  }
  
  public void warn(String s) {
    say(s);
    error = true;
  }
}
