//
// File INPUT/OUTPUT
//


EarClippingTriangulator triangulator = new EarClippingTriangulator();


void fileSelected(File selection) throws IOException { 
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    String filename = selection.getAbsolutePath();
    if (filename.endsWith("svg")) {
      ComplexShape shape = (ComplexShape) pShapeToComplexShape(loadShape(filename));
      if (shape == null)
        return;
      
      // Go down the complexShape tree if the root is empty
      while (shape.getShapes().size() == 1)
        shape = (ComplexShape) shape.getShapes().get(0);
      
      animationCollection = new AnimationCollection();
      avatar = new Avatar();
      avatar.setShape(shape);
      partsName = new String[avatar.getPartsList().length];
      for (int i=0; i<partsName.length; i++) {
        partsName[i] = avatar.getPartsList()[i].getId();
      }
      partsList.setItems(partsName);
      selected_idx = 0;
      selected = null;
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
      avatar = loadAvatarFile(selection);
      selected_idx = 0;
      selected = null;
      partsName = new String[avatar.getPartsList().length];
      for (int i=0; i<partsName.length; i++) {
        partsName[i] = avatar.getPartsList()[i].getId();
      }
      partsList.setItems(partsName);
      baseFilename = filename.substring(0, filename.length()-5);
      showUI();
    } else {
      println("Bad filename");
    }
  }
}


class DummyPShape extends PShape {
  // This class exists only to access PShape private matrix variable
  DummyPShape(PShape parent) {
    super();
    copyMatrix(parent, this);
  }
  
  public PMatrix getMatrix() {
    return matrix;
  }
}


Color pColorToGDXColor(int c) {
  return new Color(red(c)/255.0, green(c)/255.0, blue(c)/255.0, alpha(c)/255.0);
}


Drawable pShapeToComplexShape(PShape svgShape) {
  return pShapeToComplexShape(svgShape, new PMatrix3D(), 0);
}


Drawable pShapeToComplexShape(PShape svgShape, PMatrix3D matrix, int depth) {
  StringBuilder prefix = new StringBuilder();
  for (int i=0; i<depth; i++)
    prefix.append('-');
  
  Drawable shape = null;
  int family = svgShape.getFamily();
  int kind = svgShape.getKind();
  int childCount = svgShape.getChildCount();
  PMatrix3D mat = (PMatrix3D) (new DummyPShape(svgShape)).getMatrix();
  if (mat != null)
    matrix.apply(mat);
  
  if (childCount > 0) {
    ComplexShape cs = new ComplexShape();
    cs.setId(svgShape.getName());
    for (PShape child : svgShape.getChildren()) {
      Drawable childShape = pShapeToComplexShape(child, matrix.get(), depth+1);
      if (childShape != null)
        cs.addShape(childShape);
    }
    shape = cs;
  }
  else if (family == PShape.PATH) {
    int vertexCount = svgShape.getVertexCount();
    Polygon poly = new Polygon();
    float[] verts = new float[vertexCount*2];
    for (int i=0; i<vertexCount; i++) {
      PVector vertex = new PVector(svgShape.getVertexX(i), svgShape.getVertexY(i));
      vertex = matrix.mult(vertex, null);
      verts[2*i] = vertex.x;
      verts[2*i + 1] = vertex.y;
    }
    poly.setVertices(verts);
    poly.setTriangles(triangulator.computeTriangles(verts).toArray());
    try { poly.setColor(pColorToGDXColor(svgShape.getFill(999))); }
    catch (Exception e) { poly.setColor(0.f, 0.f, 0.f, 1.f); e.printStackTrace(); }
    shape = poly;
  }
  else if (family == PShape.PRIMITIVE ) {
    float[] params = svgShape.getParams();
    if (kind == PShape.ELLIPSE) {
      float r = params[2];
      // params[0], params[1] is top-left coordinate
      PVector center = matrix.mult(new PVector(params[0]+r/2, params[1]+r/2), null);
      PVector radiusPoint = matrix.mult(new PVector(params[0]+ r, 0), null);
      Circle c = new Circle(center.x, center.y, radiusPoint.x-center.x);
      try { c.setColor(pColorToGDXColor(svgShape.getFill(0))); }
      catch (Exception e) { c.setColor(0.f, 0.f, 0.f, 1.f); e.printStackTrace(); }
      shape = c;
    }
    else if (kind == PShape.RECT) {
      float x = params[0];
      float y = params[1];
      float width = params[2];
      float height = params[3];
      PVector p0 = matrix.mult(new PVector(x, y), null);
      PVector p1 = matrix.mult(new PVector(x+width, y), null);
      PVector p2 = matrix.mult(new PVector(x+width, y+height), null);
      PVector p3 = matrix.mult(new PVector(x, y+height), null);
      float[] verts = new float[] {p0.x, p0.y, p1.x, p1.y, p2.x, p2.y, p3.x, p3.y};
      Polygon poly = new Polygon();
      poly.setVertices(verts);
      poly.setTriangles(triangulator.computeTriangles(verts).toArray());
      try { poly.setColor(pColorToGDXColor(svgShape.getFill(999))); }
      catch (Exception e) { poly.setColor(0.f, 0.f, 0.f, 1.f); e.printStackTrace(); }
      shape = poly;
      for (float f:params)
        println(f);
    }
  }
  println(prefix.toString(), shape, family, kind);
  return shape;
}


ComplexShape JSONToComplexShape(JSONObject element) {
  ComplexShape cs = new ComplexShape();

  cs.setId(element.getString("id"));
  println("id", cs.getId());

  JSONArray shapes = element.getJSONArray("shapes");
  if (shapes != null) {
    for (int i=0; i<shapes.size(); i++) {
      JSONObject jsonChild = shapes.getJSONObject(i);
      if (jsonChild.hasKey("type")) {  // Treat as simple shape
        String type = jsonChild.getString("type");
        if (type.equals("polygon")) {
          Polygon p = new Polygon();
          p.setVertices(jsonChild.getJSONArray("vertices").getFloatArray());
          
          int[] triangles = jsonChild.getJSONArray("triangles").getIntArray();
          short[] trianglesShort = new short[triangles.length];
          for (int j=0; j<triangles.length; j++)
            trianglesShort[j] = (short) triangles[j];
          p.setTriangles(trianglesShort);
          
          float[] c = jsonChild.getJSONArray("color").getFloatArray();
          p.setColor(c[0], c[1], c[2], c[3]);
          cs.addShape(p);
          println(p);
        } else if (type.equals("circle")) {
          float[] params = jsonChild.getJSONArray("params").getFloatArray();
          Circle c = new Circle(params[0], params[1], params[2]);
          float[] co = jsonChild.getJSONArray("color").getFloatArray();
          c.setColor(co[0], co[1], co[2], co[3]);
          cs.addShape(c);
          println(c);
        }
      } else if (jsonChild.hasKey("id")) {  // Treat as ComplexShape
        cs.addShape(JSONToComplexShape(jsonChild));
        println("child", cs.getShapes().get(cs.getShapes().size()-1));
      }
    }
  }
  
  JSONArray origin = element.getJSONArray("origin");
  if (origin != null) {
    float[] coord = origin.getFloatArray();
    cs.setLocalOrigin(coord[0], coord[1]);
  }
  
  return cs;
}


JSONObject complexShapeToJSON(ComplexShape cs) {
  JSONObject element = new JSONObject();
  element.setString("id", cs.getId());

  JSONArray localOrigin = new JSONArray();
  localOrigin.append(cs.getLocalOrigin().x);
  localOrigin.append(cs.getLocalOrigin().y);
  element.setJSONArray("origin", localOrigin);

  JSONArray shapes = new JSONArray();
  for (Drawable shape : cs.getShapes()) {
    if (shape instanceof ComplexShape) {
      shapes.append(complexShapeToJSON((ComplexShape) shape));
    } else if (shape instanceof Polygon) {
      Polygon p = (Polygon) shape;
      JSONObject s = new JSONObject();
      s.setString("type", "polygon");

      JSONArray colorArray = new JSONArray();
      colorArray.append(p.getColor().r);
      colorArray.append(p.getColor().g);
      colorArray.append(p.getColor().b);
      colorArray.append(p.getColor().a);
      s.setJSONArray("color", colorArray);

      JSONArray verticesArray = new JSONArray();
      for (float vert : p.getVertices()) {
        verticesArray.append(vert);
      }
      s.setJSONArray("vertices", verticesArray);

      JSONArray trianglesArray = new JSONArray();
      for (short triangle : p.getTriangles()) {
        trianglesArray.append(triangle);
      }
      s.setJSONArray("triangles", trianglesArray);
      shapes.append(s);
    } else if (shape instanceof Circle) {
      Circle c = (Circle) shape;
      JSONObject s = new JSONObject();
      s.setString("type", "circle");
      
      JSONArray colorArray = new JSONArray();
      colorArray.append(c.getColor().r);
      colorArray.append(c.getColor().g);
      colorArray.append(c.getColor().b);
      colorArray.append(c.getColor().a);
      s.setJSONArray("color", colorArray);
      
      JSONArray paramsArray = new JSONArray();
      paramsArray.append(c.getCenter().x);
      paramsArray.append(c.getCenter().y);
      paramsArray.append(c.getRadius());
      s.setJSONArray("params", paramsArray);
      
      s.setInt("segments", 8); 
      
      shapes.append(s);
    }
  }

  if (shapes.size() > 0)
    element.setJSONArray("shapes", shapes);
  //if (children.size() > 0)
  //  element.setJSONArray("children", children);

  return element;
}


Avatar loadAvatarFile(File file) {
  Avatar avatar = new Avatar();
  JSONObject rootElement = loadJSONObject(file);
  
  // Load shape first
  if (rootElement.hasKey("geometry"))
    avatar.setShape(JSONToComplexShape(rootElement.getJSONObject("geometry")));
  
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
  root.setJSONObject("geometry", complexShapeToJSON(avatar.getShape()));
  
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
        // Function parameters
        for (TFParam param : anim.getFunction().getParams()) {
          jsonFuncAxe.setFloat(param.name, param.value);
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


ComplexShape loadGeometry(File shapeFile) {
  ComplexShape shape = pp.parse(shapeFile);
  return shape;
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
          for (TFParam param : fn.getParams()) {
            float value = jsonFuncAxe.getFloat(param.name);
            fn.setParam(param.name, value);
          }
          animationList.add(new Animation(fn, axe));
        } catch (Exception e) {
          println("Could not recreate animation function from json file");
        }
      }
      fullAnimation.put(id, animationList.toArray(new Animation[0]));
    }
    animCollection.addFullAnimation(animName, fullAnimation);
  }
  return animCollection;
}
