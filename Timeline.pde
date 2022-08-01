Timeline timeline;
public final PFont BitFontStandard58 = new BitFont( CP.decodeBase64( BitFont.standard58base64 ) );


class Timeline extends MoveableGroup {
  private int sliderSpacing = 3;
  private int sliderHeight = 120;
  private int colorBackground = 0xff003652;
  private int colorActiveStep = 0xff00709B;
  private int colorSelected = 0xff9B7900;
  private int colorSelectedActive = 0xffFFC905;
  private int[][] colorMatrix = new int[][] {{colorBackground, colorActiveStep}, {colorSelected, colorSelectedActive}};
  private Numberbox numSteps;
  private Numberbox duration;
  private Button lshift, rshift;
  private Toggle loop, smoothend;
  private ScrollableList easing;
  private TFTimetable fn;

  Slider[] sliders;
  int selectedSlider = 0;

  Timeline(int animNum) {
    barHeight = 12;
    groupHeight = sliderHeight + 40;
    groupWidth = 360;
    x = width - accordion.getWidth() - groupWidth - 2*margin;
    y = margin + barHeight + 1;
    
    this.fn = (TFTimetable) selectedPostureTree.getAnimations().get(animNum).getFunction();
    
    paramLocked = true;

    group = cp5.addGroup("timeline")
      .setPosition(x, y)
      .setWidth(groupWidth)
      //.hideBar()
      .setBarHeight(barHeight)
      .setBackgroundHeight(groupHeight)
      .setBackgroundColor(color(0, 100))
      ;

    //numSteps = cp5.addNumberbox("tlnumsteps"+animNum)
    numSteps = new NumberboxInput(cp5, "tlnumsteps"+animNum)
      .setLabel("Num steps")
      .setPosition(spacing, spacing)
      .setSize(60, 20)
      .setRange(4, 32)
      .setDirection(Controller.HORIZONTAL)
      .setGroup(group)
      ;

    duration = new NumberboxInput(cp5, "duration"+animNum)
      .setLabel("duration")
      .setPosition(numSteps.getPosition()[0]+numSteps.getWidth()+spacing, spacing)
      .setSize(60, 20)
      .setRange(0.5, 120)
      .setMultiplier(0.05)
      .setDirection(Controller.HORIZONTAL)
      .setGroup(group)
      ;

    easing = cp5.addScrollableList("easing"+animNum)
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
        .setGroup(group)
        .setVisible(false)
        ;
    }

    paramLocked = false;
    update();
  }


  public void setFunction(TFTimetable fn) {
    this.fn = fn;
    update();
  }

  public TimeFunction getFunction() { 
    return fn;
  }

  /*
  public void setEasing(float idx) {
   println("setEasing", idx);
   fn.setEasing(Animation.interpolationNamesSimp[int(idx)]);
   }*/

  /*
  public int getAnimNum() { 
    return animNum;
  }*/


  /* Change the size of the timeline table and update its values
  */
  public void updateTable() {
    int size = (int) numSteps.getValue();
    float[] array = new float[size];
    for (int i=0; i<size; i++) {
      array[i] = sliders[i].getValue();
    }
    fn.setTable(array);
    update();
  }


  public void setTableValue(int idx, float value) {
    fn.setTableValue(idx, value);
    selectedSlider = idx;
  }
  
  /*
  public void hide() {
    group.hide();
  }

  public void show() {
    group.open().show();
  }*/


  public void update() {
    // Update all controllers according to the function parameters
    paramLocked = true;

    numSteps.setValue(fn.getTable().length);
    duration.setValue((float) fn.getParam("duration").getValue());

    int easingNum = 0;
    String easingName = (String) fn.getParam("easing").getValue();
    for (int i=0; i<Animation.interpolationNamesSimp.length; i++) {
      if (Animation.interpolationNamesSimp[i].equals(easingName)) {
        easingNum = i;
        break;
      }
    }
    easing.setValue(easingNum);
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
  
  
  public void remove() {
    group.remove();
    timeline = null;
  }


  class TimelineSlider extends Slider {
    public TimelineSlider(ControlP5 theControlP5, String theName) {
      super(theControlP5, theName);
      setRange(-1, 1);
      setSliderMode(Slider.FLEXIBLE);
      setHandleSize(5);
      setNumberOfTickMarks(3);
      snapToTickMarks(false);
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
