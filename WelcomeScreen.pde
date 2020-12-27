public class WelcomeScreen extends Screen {

  @Override
  public void draw() {
    if (avatar != null) {
      showUI();
      currentScreen = mainScreen;
      return;
    }
    
    background(255);
    fill(127);
    textSize(32);
    text("Press CTRL+o  to load a file", width/3, height/2);
    fill(63);
    textSize(20);
    text("'h' to show help", (width/2) - 80, 50 + height/2);
    text("Ver. "+version, width-110, height-20);
  }

  @Override
  void mouseClicked(MouseEvent event) {
    selectInput("Select a file", "fileSelected");
  }

  @Override
  void keyPressed(KeyEvent event) {
    switch (key) {
    case 'h':  // Help screens
      currentScreen = helpScreen1;
      break;
    case 15:  // CTRL+o, load a new file
      selectInput("Select a file", "fileSelected");
      break;
    }
  }
}
