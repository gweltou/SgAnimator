class PartsList extends MoveableGroup {
  private class ScrollablePartsList extends ScrollableList {
    private int oldItemHover = -1;

    public ScrollablePartsList(ControlP5 theControlP5, String theName) {
      super(theControlP5, theName);
      setType(ScrollableList.LIST);
      setFont(defaultFontSmall);
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

  private ScrollablePartsList list;

  public PartsList() {
    group = cp5.addGroup("partslistgroup")
      .setBarHeight(barHeight)
      .setBackgroundHeight(groupHeight + 1)
      .setBackgroundColor(backgroundColor)
      .setCaptionLabel("parts")
      ;

    list = new ScrollablePartsList(cp5, "partslist");
    list.setLabel("parts list")
      .setGroup(group)
      //.setHeight(height-2*margin)
      .setItemHeight(menuBarHeight)
      .onClick(new CallbackListener() {
      public void controlEvent(CallbackEvent theEvent) {
        select(avatar.getPartsList()[int(list.getValue())]);
      }
    }
    );
  }
  
  public void selectItem(int n) {
    list.setValue(n);
  }

  public void setItems(String[] items) {
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
    list.setWidth(maxItemLength + 1);
    list.setHeight(items.length * menuBarHeight);
    group.setWidth(maxItemLength + 1);
    group.setBackgroundHeight(items.length * menuBarHeight);
    list.setItems(items);
  }
}
