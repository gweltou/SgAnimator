PartsList partsList;


class PartsList extends ScrollableList {
  int oldItemHover = -1;

  public PartsList(ControlP5 theControlP5, String theName) {
    super(theControlP5, theName);
    setType(ScrollableList.LIST);
    setFont(defaultFont);
    setBarHeight(0);
    setBarVisible(false);
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
