public class HelpScreen1 extends Screen {
  
  @Override
  public void draw() {
    background(255);
    fill(63);
    textSize(20);
    text("CTRL+o\n"+
      "CTRL+s\n"+
      "Up/Down\n"+
      "p\n"+
      "r\n"+
      "d\n"+
      "h\n"+
      "w\n"+
      "right click\n"+
      "MAJ + right drag/mouseWheel\n"+
      "Escape\n", width/4, height/4);
    text("Open file (svg or json)\n"+
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
