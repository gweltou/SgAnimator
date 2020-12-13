class FunctionAccordion extends Accordion {
  private int accordionWidth = 207;
  
  public FunctionAccordion(ControlP5 theControlP5, String theName) { 
    super(theControlP5, theName);
    setWidth(accordionWidth);
    setMinItemHeight(0);
    setCollapseMode(ControlP5.SINGLE);
    spacing = 4;
  }  
}
