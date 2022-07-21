public class HelpScreen1 extends Screen {
  
  @Override
  public void draw() {
    background(255);
    fill(100);
    textFont(titleFont);
    int offset = floor(textWidth("Keyboard shortcuts"));
    text("Keyboard shortcuts", (width/2)-offset/2, -20+height/6);
    
    int w = (width/2) - 120;
    float h = (height/4) - 2;
    float hStep = 32.8f;
    int keySize = 24;
    drawKey(w, round(h - 2*keySize/3), "Ctrl", keySize);
    //textSize(20);
    textFont(tooltipFontSmall);
    text("+", w + 46, h + 4);
    drawKey(w + 60, round(h - 2*keySize/3), "O", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "Ctrl", keySize);
    textFont(tooltipFontSmall);
    text("+", w + 46, h + 4);
    drawKey(w + 60, round(h - 2*keySize/3), "S", keySize);
    h += hStep;
    
    w = (width/2) - 60;
    drawKey(w, round(h - 2*keySize/3), "S", keySize);
    h += hStep + 2;
    
    w = (width/2) - 100;
    drawKey(w, round(h - 2*keySize/3), "<", keySize);
    drawKey(w + 40, round(h - 2*keySize/3), ">", keySize);
    h += hStep;
    
    w = (width/2) - 60;
    drawKey(w, round(h - 2*keySize/3), "A", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "P", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "R", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "D", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "H", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "W", keySize);
    h += hStep;
    
    drawKey(w, round(h - 2*keySize/3), "K", keySize);
    h += hStep;
    
    h += hStep;
    drawKey(w, round(h - 2*keySize/3), "Esc", keySize);
    
    textFont(tooltipFontSmall);
    text("Open file (svg or json)\n"+
      "Save json file (save as...)\n"+
      "Save json file\n"+
      "Select next/previous posture\n"+
      "Select root node\n"+
      "Play / Pause animation\n"+
      "Reset animation\n"+
      "Show / Hide UI\n"+
      "Help screen\n"+
      "Wireframe\n"+
      "Camera\n"+
      "Context menu\n"+
      "Exit program\n", width/2, height/4);
  }
  
  void keyPressed(KeyEvent event) {
    if (key == 'h') {
      currentScreen = helpScreenEasing;
    }
  }
  
  @Override
  void mouseClicked(MouseEvent event) {
    currentScreen = helpScreenEasing;
  }
}
