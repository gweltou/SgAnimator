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
      rootShape = (ComplexShape) pShapeToComplexShape(loadShape(filename));
      selected_idx = 0;
      selected = null;
      parts = rootShape.getPartsList();
      partsName = new String[parts.size()];
      for (int i=0; i<parts.size(); i++) {
        partsName[i] = parts.get(i).getId();
      }
      partsList.setItems(partsName);
      baseFilename = filename.substring(0, filename.length()-4);
      cp5.getController("parts list").show();
    } 
    else if (filename.endsWith("tdat")) {
      rootShape = loadGeometry(selection);
      File animFile = new File(filename.replace(".tdat", ".json"));
      if (animFile.exists()) {
        JSONObject rootElement = loadJSONObject(selection);
        loadAnimation(rootElement.getJSONObject("animation"), rootShape);
      }
    } else if (filename.endsWith("json")) {
      rootShape = loadGeomAnim(selection);
      selected_idx = 0;
      selected = null;
      parts = rootShape.getPartsList();
      partsName = new String[parts.size()];
      for (int i=0; i<parts.size(); i++) {
        partsName[i] = parts.get(i).getId();
      }
      partsList.setItems(partsName);
      baseFilename = filename.substring(0, filename.length()-4);
      cp5.getController("parts list").show();
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
  } else if (family == PShape.PATH) {
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
    poly.setColor(pColorToGDXColor(svgShape.getFill(999)));
    shape = poly;
  } else if (family == PShape.PRIMITIVE && kind == PShape.ELLIPSE) {
    float[] params = svgShape.getParams();
    float r = params[2];
    // params[0], params[1] is top-left coordinate
    PVector center = matrix.mult(new PVector(params[0]+r/2, params[1]+r/2), null);
    PVector radiusPoint = matrix.mult(new PVector(params[0]+ r, 0), null);
    Circle c = new Circle(center.x, center.y, radiusPoint.x-center.x);
    c.setColor(pColorToGDXColor(svgShape.getFill(999)));
    shape = c;
  }
  println(prefix.toString(), shape);
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


ComplexShape loadGeomAnim(File file) {
  ComplexShape cs = null;
  JSONObject rootElement = loadJSONObject(file);
  // Load shape first
  if (rootElement.hasKey("geometry")) {
    cs = JSONToComplexShape(rootElement.getJSONObject("geometry"));
  }
  if (rootElement.hasKey("animation")) {
    loadAnimation(rootElement.getJSONObject("animation"), cs);
  }
  return cs;
}


void saveGeomAnim(ComplexShape shape) {
  String filename = baseFilename.concat(".json");

  JSONObject root = new JSONObject();
  root.setJSONObject("geometry", complexShapeToJSON(shape));
  
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
  JSONObject jsonAnim = new JSONObject();
  jsonAnim.setJSONArray("groups", groups);
  jsonAnim.setString("name", "noname");
  root.setJSONObject("animation", jsonAnim);
  
  //saveJSONObject(root, filename, "compact");
  saveJSONObject(root, filename);
  println("File saved to " + filename);
}


ComplexShape loadGeometry(File shapeFile) {
  ComplexShape shape = pp.parse(shapeFile);
  return shape;
}


void loadAnimation(JSONObject json, ComplexShape shape) {
  // Load JSON file
  JSONArray groups = json.getJSONArray("groups");
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
    } 
    catch (Exception e) {
      println("Could not recreate animation function from json file");
    }
  }
}
