PFont defaultFont;
int spacing = 4;
int margin = 2*spacing;
int barHeight = 18;
int accordionWidth = 250;
ScrollableList partsList;


void setupUI() {
  //printArray(PFont.list());
  defaultFont = createFont("DejaVu Sans Mono", 12);

  cp5 = new ControlP5(this);
  
  partsList = cp5.addScrollableList("parts list")
     .setType(ScrollableList.LIST)
     .setFont(defaultFont)
     .setPosition(margin, margin)
     //.setBarHeight(barHeight)
     .setItemHeight(barHeight)
     .setBarVisible(false)
     .hide();
}


void updateUI() {
  boolean bottomButtons = false;
  
  paramLocked = true;
  
  // Remove accordion and create new one
  if (accordion != null) {
    cp5.remove("acc");
    accordion = null;
  }
  
  PVector pos = new PVector(spacing, spacing);
  Group g;
  g = cp5.addGroup("animation")
         .setFont(defaultFont)
         .setBarHeight(barHeight)
         .setBackgroundColor(color(0, 100))
         ;
  
  cp5.addScrollableList("function")
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
  pos.add(cp5.getController("function").getWidth() + spacing, 0);
  
  cp5.addScrollableList("axe")
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
  pos.set(spacing, 2*spacing + cp5.getController("axe").getHeight());
  pos.add(0.f, spacing);
  
  // Hinge selection bang
  cp5.addButton("hingebutton")
     .setPosition(pos.x, pos.y)
     .setSize(80, 20)
     .setSwitch(true)
     .activateBy(ControlP5.PRESS)
     .setLabel("Set hinge point")
     .setGroup(g)
     ;
  pos.add(0, cp5.getController("hingebutton").getHeight()+2*spacing);
  
  if (selected.getAnimation() != null) {
    Animation anim = selected.getAnimation();
    
    cp5.getController("function")
       .setValue(Arrays.asList(Animation.timeFunctions).indexOf(anim.getFunction().getClass()));
    cp5.getController("axe").setValue(anim.getAxe() >= 0 ? anim.getAxe() : 0);    
    
    for (TFParam param : anim.getFunction().getParams()) {
      switch (param.type) {
        case TFParam.SLIDER:
          cp5.addSlider(param.name)
             .setPosition(pos.x, pos.y)
             .setWidth(204)
             .setHeight(16)
             .setRange(param.min, param.max)
             .setValue(param.value)
             .setGroup(g)
             ;
          break;
        case TFParam.TOGGLE:
          cp5.addToggle(param.name)
             .setPosition(pos.x, pos.y)
             .setSize(50,20)
             .setValue(true)
             .setMode(ControlP5.SWITCH)
             .setGroup(g)
             ;
          break;
      }
      pos.add(0, cp5.getController(param.name).getHeight()+spacing);
    }
    pos.add(0.f, spacing);
    
    // Copy animation
    cp5.addButton("copybutton")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .activateBy(ControlP5.PRESS)
       .setLabel("Copy")
       .setGroup(g)
       ;
    pos.add(cp5.getController("copybutton").getWidth()+spacing, 0);
    
    // Delete animation
    cp5.addButton("deletebutton")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .activateBy(ControlP5.PRESS)
       .setLabel("Delete")
       .setGroup(g)
       ;
    pos.add(cp5.getController("deletebutton").getWidth()+5*spacing, 0);
    
    bottomButtons = true;
  }
  if (animationClipboard != null) {
    // Paste animation
    cp5.addButton("pastebutton")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .activateBy(ControlP5.PRESS)
       .setLabel("Paste")
       .setGroup(g)
       ;
    bottomButtons = true;
  }
  
  if (bottomButtons == true)
    pos.add(0, 20+2*spacing);
  
  g.setBackgroundHeight((int) pos.y);
  
  accordion = cp5.addAccordion("acc")
                 .setPosition(width-accordionWidth-margin, margin)
                 .setWidth(accordionWidth)
                 .setMinItemHeight(0)
                 .setCollapseMode(ControlP5.SINGLE)
                 .addItem(g)
                 .open(0)
                 ;
  
  paramLocked = false;
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
