public final PFont BitFontStandard58 = new BitFont( CP.decodeBase64( BitFont.standard58base64 ) );


class Timeline {
  private int spacing = 2;
  private int sliderSpacing = 2;
  private int sliderHeight = 120;
  private int groupHeight = sliderHeight+40;
  private int groupWidth = 360;
  private int colorBackground = 0xff003652;
  private int colorActiveStep = 0xff00709B;
  private int colorSelected = 0xff9B7900;
  private int colorSelectedActive = 0xffFFC905;
  private int[][] colorMatrix = new int[][] {{colorBackground, colorActiveStep}, {colorSelected, colorSelectedActive}};
  Group group;
  Numberbox numSteps;
  Numberbox duration;
  Button lshift, rshift;
  Toggle loop, smoothend;
  ScrollableList easing;
  TFTimetable fn;

  Slider[] sliders;
  int selectedSlider = 0;
  int animNum;

  Timeline(int animNum) {
    paramLocked = true;

    this.animNum = animNum;

    group = cp5.addGroup("timeline")
      .setPosition(width-accordion.getWidth()-groupWidth-2*margin, margin+10)
      .setWidth(groupWidth)
      //.hideBar()
      .setBackgroundHeight(groupHeight)
      .setBackgroundColor(color(0, 100))
      ;

    numSteps = cp5.addNumberbox("tlnumsteps"+animNum)
      .setLabel("Num steps")
      .setPosition(spacing, spacing)
      .setSize(60, 20)
      .setRange(4, 32)
      .setDirection(Controller.HORIZONTAL)
      .setGroup(group)
      ;

    duration = cp5.addNumberbox("duration"+animNum)
      .setLabel("duration")
      .setPosition(numSteps.getPosition()[0]+numSteps.getWidth()+spacing, spacing)
      .setSize(60, 20)
      .setRange(0.5, 120)
      .setMultiplier(0.05)
      .setDirection(Controller.HORIZONTAL)
      .setGroup(group)
      ;

    cp5.addScrollableList("tleasing"+animNum)
      .setLabel("easing")
      .setPosition(duration.getPosition()[0]+duration.getWidth()+spacing, spacing)
      .setWidth(80)
      .setBarHeight(20)
      //.setItemHeight(barHeight)
      .onEnter(toFront)
      .onLeave(close)
      .addItems(Animation.interpolationNamesSimp)
      .setGroup(group)
      .close()
      ;

    lshift = cp5.addButton("tllshift"+animNum)
      .setLabel("<<")
      .setPosition(220, spacing)
      .setSize(20, 20)
      .setGroup(group)
      ;

    cp5.addTextlabel("shiftlabel"+animNum)
      .setPosition(lshift.getPosition()[0]+6, spacing+24)
      .setFont(BitFontStandard58)
      .setText("SHIFT")
      .setGroup(group)
      ;

    rshift = cp5.addButton("tlrshift"+animNum)
      .setLabel(">>")
      .setPosition(lshift.getPosition()[0]+lshift.getWidth()+spacing, spacing)
      .setSize(20, 20)
      .setGroup(group)
      ;

    smoothend = cp5.addToggle("smoothend"+animNum)
      .setLabelVisible(false)
      .setPosition(280, spacing)
      .setSize(20, 20)
      .setGroup(group)
      ;
    cp5.addTextlabel("smoothendlabel"+animNum)
      .setPosition(smoothend.getPosition()[0]-15, spacing+24)
      .setText("SMOOTHEND")
      .setFont(BitFontStandard58)
      .setGroup(group)
      ;

    loop = cp5.addToggle("loop"+animNum)
      .setLabelVisible(false)
      .setPosition(330, spacing)
      .setSize(20, 20)
      .setGroup(group)
      ;
    cp5.addTextlabel("looplabel"+animNum)
      .setPosition(loop.getPosition()[0]-2, spacing+24)
      .setFont(BitFontStandard58)
      .setText("LOOP")
      .setGroup(group)
      ;


    sliders = new Slider[32];
    for (int i=0; i<32; i++) {
      sliders[i] = new TimelineSlider(cp5, "tlslider"+i)
        .setRange(-180, 180)
        .setGroup(group)
        .setVisible(false)
        ;
    }

    paramLocked = false;
  }


  public void setFunction(TFTimetable fn) {
    this.fn = fn;
    update();
  }

  public TimeFunction getFunction() { 
    return fn;
  }


  public int getAnimNum() { 
    return animNum;
  }


  public void updateTable() {
    int size = (int) numSteps.getValue();
    FloatArray array = new FloatArray(size);
    for (int i=0; i<size; i++) {
      array.add(sliders[i].getValue());
    }
    fn.setTable(array);
    update();
  }


  public void setTableValue(int idx, float value) {
    fn.setTableValue(idx, value);
    selectedSlider = idx;
  }

  public void hide() {
    group.hide();
  }

  public void show() {
    group.show();
  }


  public void update() {
    // Update all controllers according to the function parameters
    paramLocked = true;

    numSteps.setValue(fn.getTable().length);
    duration.setValue((float) fn.getParam("duration").getValue());
    //easing.setValue((int) fn.getParam("easing").getValue());
    loop.setValue((boolean) fn.getParam("loop").getValue());
    smoothend.setValue((boolean) fn.getParam("smoothend").getValue());

    int numSliders = fn.getTable().length;
    float sliderWidthFloat = ((float) groupWidth - sliderSpacing*(numSliders-1)) / numSliders;
    int sliderMinWidth = floor(sliderWidthFloat);
    int sliderWidth;
    float widthRemains = sliderWidthFloat - sliderMinWidth;
    float widthRemainsCumul = 0f;
    float posX = 0f;
    for (int i=0; i<32; i++) {
      widthRemainsCumul += widthRemains;
      sliderWidth = sliderMinWidth+floor(widthRemainsCumul);
      sliders[i].setPosition(posX, 40)
        .setSize(sliderWidth, sliderHeight)
        .setVisible(i<numSliders)
        .setValue(i<numSliders ? fn.getTable()[i] : 0f)
        ;

      posX += sliderWidth+sliderSpacing;
      if (floor(widthRemainsCumul) > 0)
        widthRemainsCumul -= floor(widthRemainsCumul);
    }

    paramLocked = false;
  }

  public void highlightSliders() {
    int[] step = fn.getActiveStep();
    int n = (int) numSteps.getValue();
    int selected;
    int active;
    for (int i=0; i<n; i++) {
      selected = i==selectedSlider || i==selectedSlider+1 ? 1 : 0;
      active = i==step[0] || i==step[1] ? 1 : 0;
      sliders[i].setColorBackground(colorMatrix[selected][active])
        .setColorForeground(active==1 ? 0xff08a2cf : 0xff00698c);
    }
  }

  public void lshift() {
    int n = (int) numSteps.getValue();
    float first = sliders[0].getValue();
    for (int i=0; i<n-1; i++)
      sliders[i].setValue(sliders[i+1].getValue());
    sliders[n-1].setValue(first);
    updateTable();
  }

  public void rshift() {
    int n = (int) numSteps.getValue();
    float last = sliders[n-1].getValue();
    for (int i=n-1; i>0; i--)
      sliders[i].setValue(sliders[i-1].getValue());
    sliders[0].setValue(last);
    updateTable();
  }


  class TimelineSlider extends Slider {
    public TimelineSlider(ControlP5 theControlP5, String theName) {
      super(theControlP5, theName);
      setSliderMode(Slider.FLEXIBLE);
      setHandleSize(3);
      setLabelVisible(false);
    }

    @Override
      protected void onMove( ) {
      if (mousePressed) {
        float f = _myMin + (-(_myControlWindow.getPointer().getY() - (y(_myParent.getAbsolutePosition()) + y(position)) - getHeight())) * _myUnit;
        setValue( PApplet.map(f, 0, 1, _myMinReal, _myMaxReal ) );
      }
    }
  }
}
