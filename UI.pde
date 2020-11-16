PFont defaultFont;


void updateUI() {
  int spacing = 4;
  int barHeight = 18;
  
  paramLocked = true;
  partLabel.setText(selected.getId());
  
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
     .addItems(functionNames)
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
  pos.add(0, cp5.getController("hingebutton").getHeight()+spacing);
  
  if (selected.getAnimation() != null) {
    Animation anim = selected.getAnimation();
    
    cp5.getController("function")
       .setValue(Arrays.asList(Animation.timeFunctions).indexOf(anim.getFunction().getClass()));
    cp5.getController("axe").setValue(anim.getAxe() >= 0 ? anim.getAxe() : 0);    
    
    pos.add(0, spacing);
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
      pos.add(0, cp5.getController(param.name).getHeight() + spacing);
    }
    pos.add(0.f, 2*spacing);
    
    // Copy animation
    cp5.addButton("copybutton")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .setSwitch(true)
       .activateBy(ControlP5.PRESS)
       .setLabel("Copy")
       .setGroup(g)
       ;
    pos.add(cp5.getController("copybutton").getWidth()+spacing, 0);
    
    // Paste animation
    cp5.addButton("pastebutton")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .setSwitch(true)
       .activateBy(ControlP5.PRESS)
       .setLabel("Paste")
       .setGroup(g)
       ;
    pos.add(cp5.getController("pastebutton").getWidth()+spacing, 0);
    
    // Delete animation
    cp5.addButton("deletebutton")
       .setPosition(pos.x, pos.y)
       .setSize(60, 20)
       .setSwitch(true)
       .activateBy(ControlP5.PRESS)
       .setLabel("Delete")
       .setGroup(g)
       ;
    pos.add(0, cp5.getController("pastebutton").getHeight()+spacing);
  }
  
  g.setBackgroundHeight((int) pos.y + 2*spacing);
  
  accordion = cp5.addAccordion("acc")
                 .setPosition(20, 20)
                 .setWidth(250)
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
};



import java.lang.reflect.Constructor;
import java.lang.reflect.InvocationTargetException;

void controlEvent(ControlEvent event) throws InstantiationException, IllegalAccessException, NoSuchMethodException, InvocationTargetException  {
  if (event.isController() && !paramLocked) {
    String name = event.getName();
    float value = event.getValue();
    
    if (name.equals("function")) {
      playAnim = true;
      Class<TimeFunction> tfclass = Animation.timeFunctions[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      if (selected.getAnimation() == null) {
        selected.setAnimation(new Animation(tf));
        mustUpdateUI = true;
      } else {
        // Transfer compatible parameters to new TimeFunction
        for (TFParam param : selected.getAnimation().getFunction().getParams()) {
          tf.setParam(param.name, param.value);
        }
        selected.getAnimation().setFunction(tf); //<>//
        mustUpdateUI = true;
      }
    } else if (name.equals("axe")) {
      playAnim = true;
      selected.getAnimation().setAxe((int) value);
    } else if (name.equals("hingebutton")) {
      playAnim = false;
      setHinge = ((Button) cp5.getController("hingebutton")).isOn();
      rootShape.resetAnimation();
    } else {
      playAnim = true;
      println("control event", event);
      println("== ", event.getName());
      println("== ", event.getValue());
      selected.getAnimation().getFunction().setParam(name, value);
    }
  }
}
