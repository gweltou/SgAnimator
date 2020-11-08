//
// File INPUT/OUTPUT
//
void fileSelected(File selection) throws IOException {
  ComplexShape shape;
  
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    String filename = selection.getAbsolutePath();
    if (filename.endsWith("tdat")) {
      shape = loadGeometry(selection);
      animFile = new File(filename.replace(".tdat", ".json"));
      if (animFile.exists()) {
        loadAnimation(animFile, shape);
      }
    } else if (filename.endsWith("json")) {
      // Load shape first
      File shapeFile = new File(filename.replace(".json", ".tdat"));
      if (shapeFile.exists()) {
        shape = loadGeometry(shapeFile);
        loadAnimation(selection, shape);
      } else {
        println("Could not find shape file", shapeFile.getName());
        return;
      }
    } else {
      println("Bad filename");
    }
  }
}


ComplexShape loadGeometry(File shapeFile) {
  ComplexShape shape = pp.parse(shapeFile);
  return shape;
}

void saveAnimation(ComplexShape shape) {
  if (animFile == null)
    return;
    
  println(animFile.getAbsolutePath());
  
  // Create empty anim file
  JSONObject root = new JSONObject();
  JSONArray groups = new JSONArray();
  int i = 0;
  for (String id : shape.getIdList()) {
    ComplexShape part = shape.getById(id);
    Animation anim = part.getAnimation();
    if (anim != null) {
      JSONObject group = new JSONObject();
      group.setString("id", id);
      group.setString("function", anim.getFunction().getClass().getName());
      group.setString("axe", Animation.axeName[anim.getAxe()]);
      for (TFParam param : anim.getFunction().getParams()) {
        group.setFloat(param.name, param.value);
      }
      groups.setJSONObject(i++, group);
    }
  }
  root.setJSONArray("groups", groups);
  saveJSONObject(root, animFile.getAbsolutePath());
  println("Animation saved to", animFile.getAbsolutePath());
}


void loadAnimation(File animFile, ComplexShape shape) {
  // Load JSON file
  animJson = loadJSONObject(animFile);
  JSONArray groups = animJson.getJSONArray("groups");
  for (int i = 0; i < groups.size(); i++) {
    JSONObject group = groups.getJSONObject(i);
    String id = group.getString("id");
    int axe = Arrays.asList(Animation.axeName).indexOf(group.getString("axe"));
    try {
      Class c = Class.forName(group.getString("function"));
      TimeFunction fn = (TimeFunction) c.newInstance();
      for (TFParam param : fn.getParams()) {
        float value = group.getFloat(param.name);
        fn.setParam(param.name, value);
      }
      Animation anim = new Animation(fn, axe);
      shape.getById(id).setAnimation(anim);
    } catch (Exception e) {
      println("Could not recreate animation function from json file");
    }
  }
}
