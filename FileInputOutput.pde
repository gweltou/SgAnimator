//
// File INPUT/OUTPUT
//

import java.io.FileInputStream;


void fileSelected(File selection) throws IOException { 
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    String filename = selection.getAbsolutePath();
    if (filename.endsWith("svg")) {
      ComplexShape shape = ComplexShape.fromPShape(loadShape(filename));
      if (shape == null)
        return;
      
      selectedIndex = 0;
      selected = null;
      // Go down the complexShape tree if the root is empty
      while (shape.getShapes().size() == 1 && shape.getChildren().size() == 1)
        shape = (ComplexShape) shape.getShapes().get(0);
      
      animationCollection = new AnimationCollection();
      avatar = new Avatar();
      avatar.setShape(shape);
      partsName = new String[avatar.getPartsList().length];
      for (int i=0; i<partsName.length; i++) {
        partsName[i] = avatar.getPartsList()[i].getId();
      }
      partsList.setItems(partsName);
      baseFilename = filename.substring(0, filename.length()-4);
      // Reset coordinates transformation matrix
      transform.setToTranslation(width/2, height/2);
      animName.setText("anim0");
      screenIndex = 0;
      currentScreen = screens[screenIndex];
      showUI();
      accordion.hide();
      
    /*} else if (filename.endsWith("tdat")) {
      rootShape = loadGeometry(selection);
      File animFile = new File(filename.replace(".tdat", ".json"));
      if (animFile.exists()) {
        JSONObject rootElement = loadJSONObject(selection);
        loadAnimation(rootElement.getJSONArray("animation"));
      }*/
    } else if (filename.endsWith("json")) {
      mustLoad = selection;
    } else {
      println("Bad filename");
    }
  }
}



void saveAvatarFile(Avatar avatar) {
  String filename = baseFilename.concat(".json");

  JSONObject root = new JSONObject();
  root.setJSONObject("geometry", ((ComplexShape) avatar.getShape()).toJSON());
  
  // Animations Collection
  JSONArray jsonAnimCollection = new JSONArray();
  for (String fullAnimName : animationCollection.getFullAnimationsNameList()) {
    JSONArray groups = new JSONArray();
    HashMap<String, Animation[]> fullAnimation = animationCollection.getFullAnimation(fullAnimName);
    // Every part in a fullAnimation
    for (Map.Entry<String, Animation[]> entry : fullAnimation.entrySet()) {
      JSONObject group = new JSONObject();
      JSONArray animationArray = new JSONArray();
      // Animations linked to a single part
      for (Animation anim : entry.getValue()) {
        JSONObject jsonFuncAxe = new JSONObject();
        jsonFuncAxe.setString("function", anim.getFunction().getClass().getName());
        jsonFuncAxe.setString("axe", Animation.axeNames[anim.getAxe()]);
        if (anim.getFunction() instanceof TFTimetable) {
          JSONArray table = new JSONArray();
          for (float value : ((TFTimetable) anim.getFunction()).getTable())
            table.append(value);
          jsonFuncAxe.setJSONArray("table", table);
        }
        // Function parameters
        for (TFParam param : anim.getFunction().getParams()) {
          if (param.getValue() instanceof Float) {
            jsonFuncAxe.setFloat(param.name, (float) param.getValue());
          } else if (param.getValue() instanceof Boolean) {
            jsonFuncAxe.setBoolean(param.name, (boolean) param.getValue());
          } else if (param.getValue() instanceof Integer) {
            jsonFuncAxe.setFloat(param.name, (int) param.getValue());
          } else if (param.getValue() instanceof String) {
            jsonFuncAxe.setString(param.name, (String) param.getValue());
          }
        }
        animationArray.append(jsonFuncAxe);
      }
      group.setString("id", entry.getKey());
      group.setJSONArray("functions", animationArray);
      groups.append(group);
    }
    JSONObject jsonFullAnimation = new JSONObject();
    jsonFullAnimation.setJSONArray("groups", groups);
    jsonFullAnimation.setString("name", fullAnimName);
    jsonAnimCollection.append(jsonFullAnimation);
  }
  root.setJSONArray("animation", jsonAnimCollection);
  
  //saveJSONObject(root, filename, "compact");
  saveJSONObject(root, filename);
  println("File saved to " + filename);
}
