PFont defaultFont;

void displayUI() {
  int spacing = 4;
  int barHeight = 18;
  
  paramLocked = true;
  partLabel.setText(selected.getId());
  
  // Remove accordion and create new one
  if (accordion != null) {
    cp5.remove("acc");
    accordion = null;
  }
  
  Group g;
  ArrayList<Group> groups = new ArrayList();
  PVector pos = new PVector(spacing, spacing);
  if (selected.getAnimation() == null) {
    g = cp5.addGroup("anim"+(groups.size()+1))
           .setFont(defaultFont)
           .setBarHeight(barHeight)
           .setBackgroundHeight(18)
           .setBackgroundColor(color(0, 100))
           ;
           
    cp5.addScrollableList("function")
       .setFont(defaultFont)
       .setPosition(pos.x, pos.y)
       .setBarHeight(barHeight)
       .setItemHeight(barHeight)
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
       .addItems(new String[] {"x", "y", "z", "rotation", "scale X", "scale Y"})
       .moveTo(g)
       .close()
       ;
    pos.set(spacing, 2*spacing + cp5.getController("axe").getHeight());
    g.setBackgroundHeight((int) pos.y + spacing);
    groups.add(g);
  } else {
    Animation anim = selected.getAnimation();
    g = cp5.addGroup("anim"+(groups.size()+1))
         .setFont(defaultFont)
         .setBarHeight(barHeight)
         .setBackgroundColor(color(0, 100))
         ;
    cp5.addScrollableList("function")
       .setPosition(pos.x, pos.y)
       .setFont(defaultFont)
       .setBarHeight(barHeight)
       .setItemHeight(barHeight)
       .onEnter(toFront)
       .onLeave(close)
       .addItems(functionNames)
       .setValue(Arrays.asList(Animation.timeFunctions).indexOf(anim.getFunction().getClass()))
       .moveTo(g)
       .close()
       ;
    pos.add(cp5.getController("function").getWidth() + spacing, 0);
    
    cp5.addScrollableList("axe")
       .setPosition(pos.x, pos.y)
       .setFont(defaultFont)
       .setBarHeight(barHeight)
       .setItemHeight(barHeight)
       .onEnter(toFront)
       .onLeave(close)
       .addItems(Animation.axeName)
       .setValue(anim.getAxe() >= 0 ? anim.getAxe() : 0)
       .moveTo(g)
       .close()
       ;
    pos.set(spacing, 2*spacing + cp5.getController("axe").getHeight());
    pos.add(0.f, 2*spacing);
    
    int i=0;
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
    // Hinge selection bang
    cp5.addButton("hingebutton")
       .setPosition(pos.x, pos.y)
       .setSize(80, 20)
       .setSwitch(true)
       .activateBy(ControlP5.PRESS)
       .setLabel("Set hinge point")
       .setGroup(g)
       ;
    pos.add(0, cp5.getController("hingebutton").getHeight() + 20 + spacing);
    g.setBackgroundHeight((int) pos.y + spacing);
    groups.add(g);
  }
  accordion = cp5.addAccordion("acc")
                 .setPosition(20, 20)
                 .setWidth(250)
                 //.setBarHeight(20)
                 .setMinItemHeight(0)
                 .setCollapseMode(ControlP5.SINGLE)
                 //.setMoveable(true)
                 ;
  for (Group group : groups)
    accordion.addItem(group);
  accordion.open(0);
  
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
      Class<TimeFunction> tfclass = Animation.timeFunctions[(int) event.getValue()];
      Constructor<TimeFunction> ctor = tfclass.getConstructor();
      TimeFunction tf = ctor.newInstance();
      if (selected.getAnimation() == null) {
        selected.setAnimation(new Animation(tf));
        displayUI();
      } else {
        // Transfer compatible parameters to new TimeFunction
        for (TFParam param : selected.getAnimation().getFunction().getParams()) {
          tf.setParam(param.name, param.value);
        }
        selected.getAnimation().setFunction(tf);
        // BUG INSOLUBLE
        //displayUI(); //<>//
      }
    } else if (name.equals("axe")) {
      selected.getAnimation().setAxe((int) value);
    } else if (name.equals("hingebutton")) {
      setHinge = ((Button) cp5.getController("hingebutton")).isOn();
      println(setHinge);
    } else {
      println("control event", event);
      println("== ", event.getName());
      println("== ", event.getValue());
      selected.getAnimation().getFunction().setParam(name, value);
    }
  }
}
