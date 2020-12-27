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
      "right click\n"+
      "MAJ + right drag\n", width/4, height/4);
    text("Open file (svg or json)\n"+
      "Save json file\n"+
      "Select next/previous shape group\n"+
      "play/pause animation\n"+
      "reset animation\n"+
      "show/hide UI\n"+
      "help screen\n"+
      "place pivot\n"+
      "translate geometry\n", width/2, height/4);
    text("Ver. "+version, width-110, height-20);
  }
  
  void keyPressed(KeyEvent event) {
    if (key == 'h') {
      currentScreen = helpScreenEasing;
    }
  }
}
