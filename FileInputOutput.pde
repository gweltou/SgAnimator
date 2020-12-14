//
// File INPUT/OUTPUT
//


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
      
      selected_idx = 0;
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
      showUI();
    /*} else if (filename.endsWith("tdat")) {
      rootShape = loadGeometry(selection);
      File animFile = new File(filename.replace(".tdat", ".json"));
      if (animFile.exists()) {
        JSONObject rootElement = loadJSONObject(selection);
        loadAnimation(rootElement.getJSONArray("animation"));
      }*/
    } else if (filename.endsWith("json")) {
      selected_idx = 0;
      selected = null;
      avatar = loadAvatarFile(selection);
      partsName = new String[avatar.getPartsList().length];
      for (int i=0; i<partsName.length; i++) {
        partsName[i] = avatar.getPartsList()[i].getId();
      }
      partsList.setItems(partsName);
      animName.setText(animationCollection.getFullAnimationName(fullAnimationIndex));
      baseFilename = filename.substring(0, filename.length()-5);
      showUI();
    } else {
      println("Bad filename");
    }
  }
}


Avatar loadAvatarFile(File file) {
  Avatar avatar = new Avatar();
  JSONObject rootElement = loadJSONObject(file);
  
  // Load shape first
  if (rootElement.hasKey("geometry"))
    avatar.setShape(ComplexShape.fromJSON(rootElement.getJSONObject("geometry")));
  
  // AnimationCollection is kept separated for simplicity
  // rather than storing and retrieving it from the Avatar class
  fullAnimationIndex = 0;
  if (rootElement.hasKey("animation")) {
    animationCollection = loadAnimation(rootElement.getJSONArray("animation"));
    //avatar.setAnimationCollection(animationCollection));
    avatar.setFullAnimation(animationCollection.getFullAnimation(fullAnimationIndex));
  } else {
    animationCollection = new AnimationCollection();
  }
  
  return avatar;
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


AnimationCollection loadAnimation(JSONArray jsonFullAnimationArray) {
  AnimationCollection animCollection = new AnimationCollection();
  
  for (int k=0; k<jsonFullAnimationArray.size(); k++) {
    HashMap<String, Animation[]> fullAnimation = new HashMap();
    JSONObject jsonFullAnimation = jsonFullAnimationArray.getJSONObject(k);
    String animName = jsonFullAnimation.getString("name");
    JSONArray groups = jsonFullAnimation.getJSONArray("groups");
    for (int i=0; i<groups.size(); i++) {
      JSONObject group = groups.getJSONObject(i);
      String id = group.getString("id");
      JSONArray functions = group.getJSONArray("functions");
      ArrayList<Animation> animationList = new ArrayList();
      for (int j=0; j<functions.size(); j++) {
        JSONObject jsonFuncAxe = functions.getJSONObject(j);
        int axe = Arrays.asList(Animation.axeNames).indexOf(jsonFuncAxe.getString("axe"));
        try {
          Class c = Class.forName(jsonFuncAxe.getString("function"));
          TimeFunction fn = (TimeFunction) c.newInstance();
          if (fn instanceof TFTimetable) {
            float[] table = jsonFuncAxe.getJSONArray("table").getFloatArray();
            ((TFTimetable) fn).setTable(FloatArray.with(table));
          }
          for (TFParam param : fn.getParams()) {
            if (param.value instanceof Float) {
              param.value = jsonFuncAxe.getFloat(param.name);
            } else if (param.getValue() instanceof Boolean) {
              param.value = jsonFuncAxe.getBoolean(param.name);
            } else if (param.getValue() instanceof Integer) {
              param.value = jsonFuncAxe.getFloat(param.name);
            }
          }
          animationList.add(new Animation(fn, axe));
        } catch (Exception e) {
          e.printStackTrace();
          println("Could not recreate animation function from json file");
          println(jsonFuncAxe);
        }
      }
      fullAnimation.put(id, animationList.toArray(new Animation[0]));
    }
    animCollection.addFullAnimation(animName, fullAnimation);
  }
  return animCollection;
}
