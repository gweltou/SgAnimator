public class HelpScreen1 extends Screen {
  
  @Override
  public void draw() {
    background(255);
    fill(63);
    textSize(20);
    /*text("CTRL+o\n"+
      "CTRL+s\n"+
      "Up/Down\n"+
      "p\n"+
      "r\n"+
      "d\n"+
      "h\n"+
      "w\n"+
      "right click\n"+
      "MAJ + right drag/mouseWheel\n"+
      "Escape\n", width/4, height/4);*/
    int w = (width/2) - 120;
    int h = (height/4) - 2;
    int hStep = 30;
    int keySize = 24;
    drawKey(w, h - 2*keySize/3, "Ctrl", keySize);
    textSize(20);
    text("+", w + 40, h);
    drawKey(w + 60, h - 2*keySize/3, "O", keySize);
    h += hStep;
    
    drawKey(w, h - 2*keySize/3, "Ctrl", keySize);
    textSize(20);
    text("+", w + 40, h);
    drawKey(w + 60, h - 2*keySize/3, "S", keySize);
    h += hStep;
    
    w = (width/2) - 60;
    drawKey(w, h - 2*keySize/3, "S", keySize);
    h += hStep + 2;
    
    w = (width/2) - 120;
    drawKey(w, h - 2*keySize/3, "Up", keySize);
    textSize(20);
    text("/", w + 44, h);
    drawKey(w + 60, h - 2*keySize/3, "Dwn", keySize);
    h += hStep;
    
    w = (width/2) - 60;
    drawKey(w, h - 2*keySize/3, "P", keySize);
    h += hStep;
    
    drawKey(w, h - 2*keySize/3, "R", keySize);
    h += hStep;
    
    drawKey(w, h - 2*keySize/3, "D", keySize);
    h += hStep;
    
    drawKey(w, h - 2*keySize/3, "H", keySize);
    h += hStep;
    
    drawKey(w, h - 2*keySize/3, "W", keySize);
    
    textSize(20);
    text("Open file (svg or json)\n"+
      "Save json file (save as...)\n"+
      "Save json file\n"+
      "Select next/previous shape group\n"+
      "Play/Pause animation\n"+
      "Reset animation\n"+
      "Show/Hide UI\n"+
      "Help screen\n"+
      "Wireframe\n"+
      "Place pivot\n"+
      "Translate/scale geometry\n"+
      "Exit program\n", width/2, height/4);
    text("Ver. "+version, width-110, height-20);
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
