class FunctionAccordion extends Accordion {
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
