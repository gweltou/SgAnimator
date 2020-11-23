PFont defaultFont;
int spacing = 4;
int margin = 2*spacing;
int barHeight = 18;
int accordionWidth = 250;
ScrollableList partsList;
Button hingeButton;


void setupUI() {
  //printArray(PFont.list());
  defaultFont = createFont("DejaVu Sans Mono", 12);

  cp5 = new ControlP5(this);
  
  partsList = cp5.addScrollableList("partslist")
     .setLabel("parts list")
     .setType(ScrollableList.LIST)
     .setFont(defaultFont)
     .setPosition(margin, margin)
     //.setBarHeight(barHeight)
     .setItemHeight(barHeight)
     .setBarVisible(false)
     .hide();
  
  hingeButton = cp5.addButton("hingebutton")
     .setPosition(300, 10)
     .setSize(80, 20)
     .setSwitch(true)
     .activateBy(ControlP5.PRESS)
     .setLabel("Set hinge point")
     .hide()
     ;
}


void updateUI() {
  paramLocked = true;
  
  partsList.open().show();
  hingeButton.show();
  
  // Remove accordion and create new one
  if (accordion != null) {
    cp5.remove("acc");
    accordion = null;
  }
  accordion = cp5.addAccordion("acc")
                 .setPosition(width-accordionWidth-margin, margin)
                 .setWidth(accordionWidth)
                 .setMinItemHeight(0)
                 .setCollapseMode(ControlP5.MULTI)
                 ;
  
  PVector pos = new PVector();
  ArrayList<Animation> animationList = selected.getAnimationList();
  int animNum = 0;
  Group g;
  
  for (Animation anim : animationList) {
    pos.set(spacing, spacing);
    
    g = cp5.addGroup("animation"+animNum)
           .setLabel("animation "+animNum)
           .setFont(defaultFont)
           .setBarHeight(barHeight)
           .setBackgroundColor(color(0, 100))
           ;
    
    cp5.addScrollableList("function"+animNum)
       .setLabel("function")
       .setFont(defaultFont)
       .setPosition(pos.x, pos.y)
       .setBarHeight(barHeight)
       .setItemHeight(barHeight)
       .onEnter(toFront)
       .onLeave(close)
       .addItems(functionsName)
       .setValue(Arrays.asList(Animation.timeFunctions).indexOf(anim.getFunction().getClass()))
       .moveTo(g)
       .close()
       ;
    pos.add(cp5.getController("function"+animNum).getWidth() + spacing, 0);
    
    cp5.addScrollableList("axe"+animNum)
       .setLabel("axe")
       .setFont(defaultFont)
       .setPosition(pos.x, pos.y)
       .setBarHeight(barHeight)
       .setItemHeight(barHeight)
       .onEnter(toFront)
       .onLeave(close)
       .addItems(Animation.axeName)
       .setValue(anim.getAxe() >= 0 ? anim.getAxe() : 0)
       .moveTo(g)
       .close()
       ;
    pos.set(spacing, 2*spacing + cp5.getController("axe"+animNum).getHeight());
    pos.add(0.f, spacing);
    
    for (TFParam param : anim.getFunction().getParams()) {
      switch (param.type) {
        case TFParam.SLIDER:
          cp5.addSlider(param.name+animNum)
             .setLabel(param.name)
             .setPosition(pos.x, pos.y)
             .setWidth(204)
             .setHeight(16)
             .setRange(param.min, param.max)
             .setValue(param.value)
             .setGroup(g)
             ;
          break;
        case TFParam.TOGGLE:
          cp5.addToggle(param.name+animNum)
             .setLabel(param.name)
             .setPosition(pos.x, pos.y)
             .setSize(50,20)
             .setValue(true)
             .setMode(ControlP5.SWITCH)
             .setGroup(g)
             ;
          break;
      }
      pos.add(0, cp5.getController(param.name+animNum).getHeight()+spacing);
    }
    pos.add(0.f, spacing);
    
    drawBottomButtons(g, animNum, pos);
    
    g.setBackgroundHeight((int) pos.y);
    accordion.addItem(g);
    animNum++;
  }
  
  // Add an empty accordion panel for new animations
  pos.set(spacing, spacing);
  g = cp5.addGroup("animation"+animNum)
         .setLabel("animation "+animNum)
         .setFont(defaultFont)
         .setBarHeight(barHeight)
         .setBackgroundColor(color(0, 100))
         ;
  
  cp5.addScrollableList("function"+animNum)
     .setLabel("function")
     .setFont(defaultFont)
     .setPosition(pos.x, pos.y)
     .setBarHeight(barHeight)
     .setItemHeight(barHeight)
     .onEnter(toFront)
     .onLeave(close)
     .addItems(functionsName)
     .moveTo(g)
     .close()
     ;
  pos.add(cp5.getController("function"+animNum).getWidth() + spacing, 0);
  
  cp5.addScrollableList("axe"+animNum)
     .setLabel("axe")
     .setFont(defaultFont)
     .setPosition(pos.x, pos.y)
     .setBarHeight(barHeight)
     .setItemHeight(barHeight)
     .onEnter(toFront)
     .onLeave(close)
     .addItems(Animation.axeName)
     .moveTo(g)
     .close()
     ;
  pos.set(spacing, 2*spacing + cp5.getController("axe"+animNum).getHeight());
  pos.add(0.f, spacing);
  
  drawBottomButtons(g, animNum, pos);
  
  g.setBackgroundHeight((int) pos.y);
  accordion.addItem(g)
           .open();
  
  
  paramLocked = false;
}


void drawBottomButtons(Group g, int animNum, PVector pos) {
  boolean bottomButtons = false;
  
  if (animNum < selected.getAnimationList().size()) {
    // Copy animation
    cp5.addButton("copybutton"+animNum)
       .setLabel("copy")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .activateBy(ControlP5.PRESS)
       .setGroup(g)
       ;
    pos.add(cp5.getController("copybutton"+animNum).getWidth()+spacing, 0);
    
    // Delete animation
    cp5.addButton("deletebutton"+animNum)
       .setLabel("delete")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .activateBy(ControlP5.PRESS)
       .setGroup(g)
       ;
    pos.add(cp5.getController("deletebutton"+animNum).getWidth()+5*spacing, 0);
    
    bottomButtons = true;
  }
    
  if (animationClipboard != null) {
    // Paste animation
    cp5.addButton("pastebutton"+animNum)
       .setLabel("paste")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .activateBy(ControlP5.PRESS)
       .setGroup(g)
       ;
    bottomButtons = true;
  }
  
  if (bottomButtons == true)
    pos.add(0, 20+2*spacing);
}



CallbackListener toFront = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
      theEvent.getController().bringToFront();
      ((ScrollableList)theEvent.getController()).open();
  }
};

CallbackListener close = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
      ((ScrollableList)theEvent.getController()).close();
  }
}; //<>//
