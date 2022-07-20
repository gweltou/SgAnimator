ControlP5 cp5; //<>//


int spacing = 4;
int margin = spacing;
int menuBarHeight = 18;
int groupBarHeight = 16;
int keepsOpenAnimNum = -1;
int axeWidth = 72;
boolean isNumberboxActive = false;
color backgroundColor = color(0, 100);



public class ContextMenu {
  List<Button> items = new ArrayList<>();
  List<Boolean> visible;
  int itemHeight = 20;
  int menuWidth = 90;
  Vector2 position;

  public ContextMenu() {
    position = new Vector2();
    visible = new ArrayList<>();

    addItem("Place pivot", "pivotbtn", "onPivot", "");
    addItem("Reset transform", "resettr", "onReset", "");
    addItem("Import", "importbtn", "onImport", "");
  }

  public void clear() {
    items.clear();
    visible.clear();
  }

  private void addItem(String label, String cp5name, String fn, String tip) {
    Button newItem = cp5.addButton(cp5name)
      .setSize(menuWidth, itemHeight)
      //.setSwitch(true)
      .activateBy(ControlP5.PRESS)
      .setLabel(label)
      .plugTo(this, fn)
      .hide()
      ;
    if (!tip.isEmpty()) {
      newItem.onEnter(new CallbackListener() {
        public void controlEvent(CallbackEvent theEvent) {
          tooltip.say(tip);
        }
      }
      );
    }

    items.add(newItem);
    visible.add(false);
  }

  public void onPivot(boolean value) {
    setPivot = true;
    avatar.resetAnimation();
    playing = false;
  }

  public void onReset(boolean value) {
    selected.resetTransform();
  }

  public void onImport(boolean value) {
    //hide();
    selectInput("Select a file", "inputFileSelected");
    //loadScreen = new LoadScreen();
  }

  public void setPosition(int x, int y) {
    position.set(x, y);
  }

  public void display(String name) {
    for (int i = 0; i < items.size(); i++) {
      if (items.get(i).getName() == name)
        visible.set(i, true);
    }
  }

  public void hide() {
    for (Button item : items)
      item.hide();
    Collections.fill(visible, false);
  }

  public void show() {
    int y = 0;
    for (int i = 0; i < items.size(); i++) {
      Button item = items.get(i);
      if (visible.get(i)) {
        item.setPosition(position.x, position.y + y);
        item.show();
        y += itemHeight;
      }
    }
  }
}



public class MoveableGroup {
  protected Group group;
  protected int barHeight = 10;
  protected int groupWidth = 20;
  protected int groupHeight = 20;
  protected int spacing = 2;
  protected int x;
  protected int y;
  public boolean isMoving = false;


  public boolean contains(int x, int y) {
    return (x >= this.x && x <= this.x+groupWidth
      && y >= this.y-barHeight && y <= this.y);
  }

  public void move(int dx, int dy) {
    group.open();
    x += dx;
    y += dy;
    x = max(1, min(sketchWidth() - group.getWidth() - 1, x));
    y = max(barHeight + 2, min(sketchHeight() - groupHeight - 1, y));
    group.bringToFront();
    group.setPosition(x, y);
  }

  public void setPosition(int x, int y) {
    this.x = x;
    this.y = y;
    group.setPosition(x, y);
  }

  public void show() {
    group.show();
  }

  public void hide() {
    group.hide();
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
  private String unit = "";
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
    }
    );

    onLeave(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        setActive( false );
        submit();
      }
    }
    );

    onChange(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        getValueLabel().setText("" + adjustValue(getValue()) + unit);
      }
    }
    );
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
      getValueLabel().setText(this.text + unit);
    }
  }

  public NumberboxInput setUnit(String unit) {
    this.unit = unit;
    return this;
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
        setValue(float(text));
      } else {
        setValue(0f);
      }
      text = "";
    }
    getValueLabel().setText("" + adjustValue(getValue()) + unit);
  }
}



void updateUI() {
  paramLocked = true;
  boolean visible = true;

  //partsList.open().show();

  // Remove accordion and create new one
  if (accordion != null) {
    if (!accordion.isVisible())
      visible = false;
    cp5.remove("accordion");
    accordion = null;
  }
  accordion = new FunctionAccordion(cp5, "accordion");
  accordion.setPosition(width-accordion.getWidth()-margin, 1);

  if (timeline != null)
    timeline.remove();

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
    cp5.addButton("delbtn"+animNum)
      .setLabel("x")
      .setColorBackground(0xffff0000)
      .setPosition(pos.x, pos.y)
      .setSize(menuBarHeight, menuBarHeight)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Delete this animation");
      }
    }
    )
    ;
    pos.set(spacing, 2*spacing + cp5.getController("axe"+animNum).getHeight());
    pos.add(0.f, spacing);


    // Draw specific parameters
    if (anim.getFunction() instanceof TFTimetable) {
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
      .setPosition(pos.x, pos.y)
      .setRange(0, 500)
      .setResolution(-500f)  // A negative resolution inverse the drag direction
      .setScrollSensitivity(0.0001f)
      .setValue(anim.getAmp())
      .setRadius(20)
      .setDragDirection(Knob.VERTICAL)
      .setGroup(g)
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Amplify the output value of the function");
      }
    }
    )
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
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Invert the output value of the function");
      }
    }
    )
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
  if (!visible)
    accordion.hide();
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
    cp5.addButton("copybtn"+animNum)
      .setLabel("copy")
      .setPosition(pos.x, pos.y)
      .setSize(40, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      ;
    pos.add(cp5.getController("copybtn"+animNum).getWidth()+spacing, 0);

    // Swap position buttons
    cp5.addButton("swapup"+animNum)
      .setLabel("up")
      .setPosition(accordion.getWidth()-42-margin, pos.y)
      .setSize(20, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Move the function up (can change the resulting animation, especially with rotations)");
      }
    }
    )
    ;
    if (animNum < 1)
      cp5.getController("swapup"+animNum).hide();

    cp5.addButton("swapdown"+animNum)
      .setLabel("dwn")
      .setPosition(accordion.getWidth()-20-margin, pos.y)
      .setSize(20, 20)
      .activateBy(ControlP5.PRESS)
      .setGroup(g)
      .onEnter(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        tooltip.say("Move the function down (can change the resulting animation, especially with rotations)");
      }
    }
    )
      ;
    if (animNum == selected.getAnimationList().length-1)
      cp5.getController("swapdown"+animNum).hide();

    bottomButtons = true;
  }

  if (animationClipboard != null) {
    // Paste animation
    cp5.addButton("pastebtn"+animNum)
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
