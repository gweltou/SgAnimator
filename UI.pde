ControlP5 cp5; //<>//
FunctionAccordion accordion;
MyScrollableList partsList;
Transport transport;
Button pivotButton;
Timeline timeline;

PFont defaultFont;
int spacing = 4;
int margin = spacing;
int menuBarHeight = 18;
int groupBarHeight = 16;
int keepsOpenAnimNum = -1;
int axeWidth = 72;
boolean isNumberboxActive = false;
color backgroundColor = color(0, 100);



class MyScrollableList extends ScrollableList {
  int oldItemHover = -1;

  public MyScrollableList(ControlP5 theControlP5, String theName) { 
    super(theControlP5, theName);
    setType(ScrollableList.LIST);
    setFont(defaultFont);
    //setBarHeight(0);
    //setBarVisible(false);
    setWidth(120);
  }

  public void highlightPart() {
    if (itemHover != oldItemHover) {
      if (itemHover >= 0 && itemHover < avatar.getPartsList().length) {
        renderer.setSelected(avatar.getPartsList()[itemHover]);
      }
    }
    oldItemHover = itemHover;
  }
  
  @Override ScrollableList setItems(String[] items) {
    // Set scrollableList width according to longest item
    int maxItemLength = 0;
    int length;
    int numSpaces;
    for (String s : items) {
      // Count number of spaces in item string
      numSpaces = 0;
      for (int i = 0; i < s.length(); i++) {
        if (s.charAt(i) == ' ')
          numSpaces++;
      }
      length = 7 * numSpaces + 8 * (s.length() - numSpaces);
      if (length > maxItemLength)
        maxItemLength = length;
    }
    setWidth(maxItemLength + 1);
    return super.setItems(items);
  }

  @Override protected void onEnter() {
    super.onEnter();
    highlightPart();
  }
  @Override protected void onLeave() {
    super.onLeave();
    renderer.setSelected(selected);
  }
  @Override protected void onMove() {
    super.onMove();
    highlightPart();
  }
}



public class FunctionAccordion extends Accordion {
  private int accordionWidth = 207;

  public FunctionAccordion(ControlP5 theControlP5, String theName) {
    super(theControlP5, theName);
    setWidth(accordionWidth);
    setMinItemHeight(0);
    setCollapseMode(ControlP5.SINGLE);
    spacing = 4;
  }

  // Stupid hack to fix a stupid bug
  // (groups used to collapse in wrong order after mouse hovered a scrollable list)
  @Override
  public void controlEvent( ControlEvent theEvent ) {
    super.controlEvent(theEvent);
    String[] m = match(theEvent.getName(), "animation(\\d+)");
    keepsOpenAnimNum = parseInt(m[1]);
    mustUpdateUI = true;
  }
}



public class NumberboxInput extends Numberbox {
  private String text = "";
  private boolean active;

  NumberboxInput(ControlP5 theControlP5, String theName) {
    super(theControlP5, theName);
    setLabel("");
    
    // control the active-status of the input handler when releasing the mouse button inside 
    // the numberbox. deactivate input handler when mouse leaves.
    onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        setActive( true );
      }
    });
    
    onLeave(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        setActive( false );
        submit();
      }
    });
  }

  public void keyEvent(KeyEvent k) {
    // only process key event if input is active 
    if (k.getAction() == KeyEvent.PRESS && active) {
      if (k.getKey() == '\n') { // confirm input with enter
        submit();
        return;
      } else if (k.getKeyCode() == BACKSPACE) { 
        text = text.isEmpty() ? "" : text.substring(0, text.length()-1);
      } else if (k.getKey() < 255) {
        // check if the input is a valid (decimal) number
        final String regex = "-?(\\d+(.\\d{0,3})?)?";
        String s = text + k.getKey();
        if ( java.util.regex.Pattern.matches(regex, s ) ) {
          text += k.getKey();
        }
      }
      getValueLabel().setText(this.text);
    }
  }

  public void setActive(boolean b) {
    active = b;
    isNumberboxActive = b;
    if (active) {
      getValueLabel().setText("");
      text = "";
    }
  }

  public void submit() {
    if (!text.isEmpty()) {
      final String regex = "-?\\d+(.\\d{0,3})?";
      if (java.util.regex.Pattern.matches(regex, text)) {
        setValue( float( text ) );
      } else {
        setValue(0f);
      }
      text = "";
    } else {
      getValueLabel().setText("" + getValue());
    }
  }
}



void setupUI() {
  //printArray(PFont.list());
  defaultFont = createFont("DejaVu Sans Mono", 12);

  cp5 = new ControlP5(this);

  partsList = (MyScrollableList) new MyScrollableList(cp5, "partslist")
    .setLabel("parts list")
    .setPosition(margin, margin)
    .setHeight(height-2*margin)
    .setItemHeight(menuBarHeight)
    .hide();
  ;

  transport = new Transport();
  accordion = new FunctionAccordion(cp5, "accordion");

  pivotButton = cp5.addButton("pivotbutton")
    .setPosition(300, 10)
    .setSize(70, 20)
    .setSwitch(true)
    .activateBy(ControlP5.PRESS)
    .setLabel("Set pivot")
    .hide()
    ;
}



void updateUI() {
  paramLocked = true;

  //partsList.open().show();

  // Remove accordion and create new one
  if (accordion != null) {
    cp5.remove("accordion");
    accordion = null;
  }
  accordion = new FunctionAccordion(cp5, "accordion");
  accordion.setPosition(width-accordion.getWidth()-margin, 1);

  PVector pos = new PVector();
  Animation[] animationList = selected.getAnimationList();
  int animNum = 0;
  Group g;

  for (Animation anim : animationList) {
    pos.set(spacing, spacing);

    g = cp5.addGroup("animation"+animNum)
      .setLabel("animation "+animNum)
      //.setFont(defaultFont)
      .setBarHeight(groupBarHeight)
      .setBackgroundColor(color(0, 100))
      ;

    cp5.addScrollableList("function"+animNum)
      .setLabel("function")
      .setFont(defaultFont)
      .setPosition(pos.x, pos.y)
      .setBarHeight(menuBarHeight)
      .setItemHeight(menuBarHeight)
      .onEnter(toFront)
      .onLeave(close)
      .addItems(functionsName)
      .setValue(Arrays.asList(Animation.timeFunctions).indexOf(anim.getFunction().getClass()))
      .setGroup(g)
      .close()
      ;
    pos.add(cp5.getController("function"+animNum).getWidth() + spacing, 0);

    cp5.addScrollableList("axe"+animNum)
      .setLabel("axe")
      .setFont(defaultFont)
      .setPosition(pos.x, pos.y)
      .setWidth(axeWidth)
      .setBarHeight(menuBarHeight)
      .setItemHeight(menuBarHeight)
      .onEnter(toFront)
      .onLeave(close)
      .addItems(Animation.axeNames)
      .setValue(anim.getAxe() >= 0 ? anim.getAxe() : 0)
      .setGroup(g)
      .close()
      ;
    pos.add(cp5.getController("axe"+animNum).getWidth() + spacing, 0);

    // Delete animation button
    cp5.addButton("deletebutton"+animNum)
      .setLabel("x")
      .setColorBackground(0xffff0000)
      .setPosition(pos.x, pos.y)
      .setSize(menuBarHeight, menuBarHeight)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      ;
    pos.set(spacing, 2*spacing + cp5.getController("axe"+animNum).getHeight());
    pos.add(0.f, spacing);


    // Draw specific parameters
    if (anim.getFunction() instanceof TFTimetable) {
      if (timeline == null) {
        timeline = new Timeline(animNum);
        timeline.setFunction((TFTimetable) anim.getFunction());
      }

      cp5.addButton("showtimeline"+animNum)
        .setLabel("Open Timeline")
        .setPosition(pos.x, pos.y)
        .setSize(60, 20)
        .activateBy(ControlP5.PRESS)
        .setGroup(g)
        ;
      pos.add(0.f, 20+spacing);
    } else {
      drawParams(g, animNum, pos);
    }
    pos.add(spacing, spacing);

    // Draw Animation general parameters
    cp5.addKnob("animamp"+animNum)
      .setLabel("")
      //.setLabelVisible(false)
      .setPosition(pos.x, pos.y)
      .setRange(0, 500)
      .setResolution(-500f)  // A negative resolution inverse the drag direction
      .setScrollSensitivity(0.0001f)
      .setValue(anim.getAmp())
      .setRadius(20)
      .setDragDirection(Knob.VERTICAL)
      .setGroup(g)
      ;
    cp5.addTextlabel("amp"+animNum+"label")
      .setPosition(pos.x + 35 + spacing, pos.y + 16)
      .setText("amp".toUpperCase())
      .setGroup(g)
      ;
    pos.set(accordion.getWidth()-82, pos.y);

    cp5.addToggle("animinv"+animNum)
      .setLabelVisible(false)
      .setPosition(pos.x, pos.y + 10)
      .setSize(40, 20)
      .setMode(ControlP5.SWITCH)
      .setValue(!anim.getInv())
      .setGroup(g)
      ;
    cp5.addTextlabel("inv"+animNum+"label")
      .setPosition(pos.x + 38 + spacing, pos.y + 15)
      .setText("invert".toUpperCase())
      .setGroup(g)
      ;
    pos.add(0, cp5.getController("animamp"+animNum).getHeight());

    pos.set(spacing, pos.y+spacing*2);
    drawBottomButtons(g, animNum, pos);

    g.setBackgroundHeight((int) pos.y);
    accordion.addItem(g);
    animNum++;
  }

  // Add an empty accordion panel for new animations
  pos.set(spacing, spacing);
  g = cp5.addGroup("animation"+animNum)
    .setLabel("animation "+animNum)
    //.setFont(defaultFont)
    .setBarHeight(groupBarHeight)
    .setBackgroundColor(color(0, 100))
    ;

  cp5.addScrollableList("function"+animNum)
    .setLabel("function")
    .setFont(defaultFont)
    .setPosition(pos.x, pos.y)
    .setBarHeight(menuBarHeight)
    .setItemHeight(menuBarHeight)
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
    .setWidth(axeWidth)
    .setBarHeight(menuBarHeight)
    .setItemHeight(menuBarHeight)
    .onEnter(toFront)
    .onLeave(close)
    .addItems(Animation.axeNames)
    .moveTo(g)
    .close()
    ;
  pos.set(spacing, 2*spacing + cp5.getController("axe"+animNum).getHeight());
  pos.add(0.f, spacing);

  drawBottomButtons(g, animNum, pos);

  g.setBackgroundHeight((int) pos.y);
  accordion.addItem(g);

  if (keepsOpenAnimNum >= 0 && keepsOpenAnimNum <= animationList.length) {
    accordion.open(keepsOpenAnimNum);
  } else {
    accordion.open(0);
  }

  paramLocked = false;
}



void drawParams(Group g, int animNum, PVector pos) {
  Animation anim = selected.getAnimationList()[animNum];

  for (TFParam param : anim.getFunction().getParams()) {
    switch (param.type) {
    case TFParam.SLIDER:
      cp5.addSlider(param.name+animNum)
        .setLabel(param.name)
        .setPosition(pos.x, pos.y)
        .setWidth(accordion.getWidth()-40)
        .setHeight(16)
        .setRange(param.min, param.max)
        .setValue((float) param.getValue())
        .setGroup(g)
        ;
      break;

    case TFParam.CHECKBOX:
      cp5.addToggle(param.name+animNum)
        .setLabelVisible(false)
        .setPosition(pos.x, pos.y)
        .setSize(20, 20)
        .setValue((boolean) param.getValue())
        .setGroup(g)
        ;
      cp5.addTextlabel(param.name+animNum+"label")
        .setPosition(pos.x + 20 + spacing, pos.y + 4)
        .setText(param.name.toUpperCase())
        .setGroup(g)
        ;
      break;

    case TFParam.TOGGLE:
      cp5.addToggle(param.name+animNum)
        .setLabelVisible(false)
        .setPosition(pos.x, pos.y)
        .setSize(40, 20)
        .setMode(ControlP5.SWITCH)
        .setValue((int) param.getValue() == 1 ? true : false)
        .setGroup(g)
        ;
      cp5.addTextlabel(param.name+animNum+"label")
        .setPosition(pos.x + 40 + spacing, pos.y + 4)
        .setText(param.name.toUpperCase())
        .setGroup(g)
        ;
      break;

    case TFParam.NUMBERBOX:
      new NumberboxInput(cp5, param.name+animNum)
        //.setLabelVisible(false) // doesn't work
        .setPosition(pos.x, pos.y)
        .setSize(60, 20)
        .setRange(param.min, param.max)
        .setMultiplier(0.1) // set the sensitifity of the numberbox
        .setDirection(Controller.HORIZONTAL) // change the control direction to left/right
        .setValue((float) param.getValue())
        .setGroup(g)
        ;
      cp5.addTextlabel(param.name+animNum+"label")
        .setPosition(pos.x + 60 + spacing, pos.y + 4)
        .setText(param.name.toUpperCase() + (param.unit.equals("") ? "" : "  ("+param.unit+")"))
        .setGroup(g)
        ;
      break;

    case TFParam.EASING:
      int easingNum = 0;
      for (int i=0; i<Animation.interpolationNamesSimp.length; i++) {
        if (Animation.interpolationNamesSimp[i].equals((String) param.getValue())) {
          easingNum = i;
          break;
        }
      }
      cp5.addScrollableList(param.name+animNum)
        .setLabel("easing function")
        .setPosition(pos.x, pos.y)
        .setBarHeight(menuBarHeight)
        .setItemHeight(menuBarHeight)
        .onEnter(toFront)
        .onLeave(close)
        .addItems(Animation.interpolationNamesSimp)
        .setValue(easingNum)
        .setGroup(g)
        .close()
        ;
      break;
    }
    pos.add(0, cp5.getController(param.name+animNum).getHeight()+spacing);
  }
}



void drawBottomButtons(Group g, int animNum, PVector pos) {
  boolean bottomButtons = false;

  if (animNum < selected.getAnimationList().length) {
    // Copy animation
    cp5.addButton("copybutton"+animNum)
      .setLabel("copy")
      .setPosition(pos.x, pos.y)
      .setSize(40, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      ;
    pos.add(cp5.getController("copybutton"+animNum).getWidth()+spacing, 0);

    // Swap position buttons
    cp5.addButton("swapup"+animNum)
      .setLabel("up")
      .setPosition(accordion.getWidth()-42-margin, pos.y)
      .setSize(20, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      ;
    if (animNum < 1)
      cp5.getController("swapup"+animNum).hide();

    cp5.addButton("swapdown"+animNum)
      .setLabel("dwn")
      .setPosition(accordion.getWidth()-20-margin, pos.y)
      .setSize(20, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      ;
    if (animNum == selected.getAnimationList().length-1)
      cp5.getController("swapdown"+animNum).hide();

    bottomButtons = true;
  }

  if (animationClipboard != null) {
    // Paste animation
    cp5.addButton("pastebutton"+animNum)
      .setLabel("paste")
      .setPosition(pos.x, pos.y)
      .setSize(42, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      ;
    bottomButtons = true;
  }

  if (bottomButtons == true)
    pos.add(0, 20+2*spacing);
}



void showUI() {
  showUI = true;
  accordion.show();
  partsList.open().show();
  transport.show();
  renderer.setSelected(selected);
}

void hideUI() {
  showUI = false;
  accordion.hide();
  partsList.hide();
  pivotButton.hide();
  transport.hide();
  renderer.setSelected(null);
}



CallbackListener toFront = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    theEvent.getController().getParent().bringToFront();
    theEvent.getController().bringToFront();
    ((ScrollableList)theEvent.getController()).open();
  }
};

CallbackListener close = new CallbackListener() {
  public void controlEvent(CallbackEvent theEvent) {
    ((ScrollableList)theEvent.getController()).close();
  }
};
