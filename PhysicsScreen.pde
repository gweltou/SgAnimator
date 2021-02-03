public class PhysicsScreen extends Screen {
  private final Affine2 transform;
  private color colorSelected = color(255, 127, 0);

  private ArrayList<Shape2D> clicked = new ArrayList();
  private Shape2D selectedShape;
  private int selectedHandle = -1;
  private boolean computeConvexHull = false;
  private final Affine2 unproject = new Affine2();
  private final Vector2 tmpVec = new Vector2();
  private final ConvexHull convexHull;

  private int MAX_POINTS = 8;
  private float HANDLE_RADIUS = 10;


  public PhysicsScreen(Affine2 transform) {
    this.transform = transform;
    unproject.set(transform).inv();
    convexHull = new ConvexHull();
    avatar.resetAnimation();
    Json json = new Json();
    println(json.toJson(avatar.physicsShapes));
  }


  void draw() {
    background(240);

    renderer.pushMatrix(transform);
    avatar.draw(renderer);
    renderer.popMatrix();
    
    for (Shape2D shape : avatar.physicsShapes)
      drawShape(shape);

    if (selectedHandle >= 0) {
      // Draw selected handle
      stroke(colorSelected);
      strokeWeight(2);
      if (selectedShape.getClass() == DrawablePolygon.class) {
        float[] vertices = ((DrawablePolygon) selectedShape).getVertices();
        tmpVec.set(vertices[selectedHandle], vertices[selectedHandle + 1]);
        transform.applyTo(tmpVec);
        circle(tmpVec.x, tmpVec.y, HANDLE_RADIUS);
      } else if (selectedShape.getClass() == DrawableCircle.class) {
        DrawableCircle c = (DrawableCircle) selectedShape;
        tmpVec.set(c.getCenter());
        transform.applyTo(tmpVec);
        noFill();
        circle(tmpVec.x, tmpVec.y, 2 * c.getRadius() * transform.m00);
      }
    }
    
    //textSize(12);
    strokeWeight(0.5f);
    drawKey(16, 20, "P", 28);
    text("create a Polygon shape", 100, 20+18);
    drawKey(16, 54, "MAJ", 28);
    text("+Click  add a point to selected polygon", 60, 54+18);
    drawKey(16, 88, "C", 28);
    text("create a Circle shape", 100, 88+18);
    drawKey(16, 122, "Suppr", 28);
    text("Delete selected shape", 100, 122+18);
    drawKey(16, 156, "Q", 28);
    text("Quit physics mode", 100, 156+18);
  }


  private void computeConvexPolygon(Polygon polygon) {
    float[] vertices = polygon.getVertices();
    FloatArray tmpArray = convexHull.computePolygon(vertices, false);
    float[] newVertices = new float[tmpArray.size-2];
    System.arraycopy(tmpArray.items, 0, newVertices, 0, newVertices.length);
    polygon.setVertices(newVertices);
  }


  public int getHandleIndex(Shape2D shape, float posX, float posY) {
    if (shape.getClass() == Polygon.class) {
      float[] vertices = ((Polygon) shape).getTransformedVertices();
      for (int i = 0; i < vertices.length; i += 2) {
        if (Vector2.dst(vertices[i], vertices[i+1], posX, posY) < HANDLE_RADIUS / transform.m00)
          return i;
      }
    } else if (shape.getClass() == Circle.class) {
      Circle c = (Circle) shape;
      float dist = Vector2.dst(posX, posY, c.x, c.y);
      if (abs(c.radius - dist) < 0.5 * HANDLE_RADIUS / transform.m00)
        return 0;
    }
    return -1;
  }


  public void drawShape(Shape2D shape) {
    strokeWeight(1);
    if (shape == selectedShape) {
      stroke(colorSelected);
      fill(colorSelected, 61);
    } else {
      stroke(80);
      fill(255, 63);
    }

    if (shape.getClass() == Polygon.class) {
      float[] vertices = ((Polygon) shape).getTransformedVertices();
      beginShape();
      for (int i = 0; i < vertices.length; i += 2) {
        tmpVec.set(vertices[i], vertices[i+1]);
        transform.applyTo(tmpVec);
        vertex(tmpVec.x, tmpVec.y);
      }
      endShape(CLOSE);

      if (shape == selectedShape) {
        strokeWeight(4);
        for (int i = 0; i < vertices.length; i += 2) {
          tmpVec.set(vertices[i], vertices[i+1]);
          transform.applyTo(tmpVec);
          point(tmpVec.x, tmpVec.y);
        }
      }
    } else if (shape.getClass() == Circle.class) {
      Circle c = (Circle) shape;
      tmpVec.set(c.x, c.y);
      transform.applyTo(tmpVec);
      circle(tmpVec.x, tmpVec.y, 2 * c.radius * transform.m00);
      if (shape == selectedShape) {
        strokeWeight(4);
        point(tmpVec.x, tmpVec.y);
      }
    }
  }


  void keyPressed(KeyEvent event) {
    tmpVec.set(mouseX, mouseY);
    unproject.applyTo(tmpVec);

    switch (key) {
    case 'q':
      showUI();
      currentScreen = mainScreen;
      break;
    case 'p':
      // New polygon shape
      float r = 40 / transform.m00;
      float[] vertices = new float[] {-r, +r, +r, +r, +r, -r, -r, -r};
      Polygon polygon = new Polygon();
      Vector2 origin = avatar.shape.getLocalOrigin();
      polygon.setOrigin(origin.x, origin.y);
      polygon.setPosition(tmpVec.x, tmpVec.y);
      polygon.setVertices(vertices);
      avatar.physicsShapes.add(polygon);
      selectedShape = polygon;
      break;
    case 'c':
      // New circle shape
      r = 40 / transform.m00;
      Circle circle = new Circle(tmpVec.x, tmpVec.y, r);
      avatar.physicsShapes.add(circle);
      selectedShape = circle;
      break;
    case 127:  // Suppr
      avatar.physicsShapes.remove(selectedShape);
      break;
    }
  }

  void mousePressed(MouseEvent event) {
    tmpVec.set(mouseX, mouseY);
    unproject.applyTo(tmpVec);

    // Check if cursor is above a handle from the selected shape
    if (selectedShape != null) {
      selectedHandle = getHandleIndex(selectedShape, tmpVec.x, tmpVec.y);
      if (selectedHandle >= 0)
        return;

      // Maj key is pressed, add new point to selected Polygon
      if (keyPressed && keyCode == 16
        && selectedShape.getClass() == Polygon.class
        && !selectedShape.contains(tmpVec.x, tmpVec.y)) {
        Polygon polygon = (Polygon) selectedShape;
        float[] vertices = polygon.getVertices();
        if (vertices.length < 2 * MAX_POINTS) {
          float[] newVertices = new float[vertices.length + 2];
          System.arraycopy(vertices, 0, newVertices, 0, vertices.length);
          newVertices[vertices.length] = tmpVec.x - polygon.getX();
          newVertices[vertices.length + 1] = tmpVec.y - polygon.getY();
          polygon.setVertices(newVertices);
          computeConvexPolygon(polygon);
        }
        return;
      }
    }

    // List all shapes pointed by the mouse click
    clicked.clear();
    for (Shape2D shape : avatar.physicsShapes) {
      if (shape.contains(tmpVec.x, tmpVec.y))
        clicked.add(shape);
    }

    if (clicked.isEmpty()) {
      selectedShape = null;
    } else if (clicked.size() == 1) {
      selectedShape = clicked.get(0);
      // put the selected shape back on top
    }
  }


  void mouseClicked(MouseEvent event) {
    if (clicked.size() > 0) {
      selectedShape = clicked.get(0);
      avatar.physicsShapes.remove(selectedShape);
      avatar.physicsShapes.add(selectedShape);
    }
  }


  void mouseDragged(MouseEvent event) {
    float dx = (mouseX - pmouseX) / transform.m00;
    float dy = (mouseY - pmouseY) / transform.m00;

    if (event.getButton() == RIGHT) {
      // scale translation by the zoom factor
      transform.translate(dx, dy);
      unproject.set(transform).inv();
      return;
    }

    // Move handle
    if (selectedHandle >= 0) {
      if (selectedShape.getClass() == Polygon.class) {
        float[] vertices = ((Polygon) selectedShape).getVertices();
        vertices[selectedHandle] += dx;
        vertices[selectedHandle + 1] += dy;
        ((Polygon) selectedShape).dirty();
        computeConvexHull = true;
      } else if (selectedShape.getClass() == Circle.class) {
        tmpVec.set(mouseX, mouseY);
        unproject.applyTo(tmpVec);
        Circle c = (Circle) selectedShape;
        float dist = Vector2.dst(tmpVec.x, tmpVec.y, c.x, c.y);
        c.setRadius(dist);
      }
      return;
    }

    // Translate whole shape
    if (selectedShape != null) {
      if (selectedShape.getClass() == Polygon.class) {
        ((Polygon) selectedShape).translate(dx, dy);
      } else if (selectedShape.getClass() == Circle.class) {
        Circle circle = (Circle) selectedShape;
        circle.x += dx;
        circle.y += dy;
      }
    }
  }


  void mouseReleased(MouseEvent event) {
    if (computeConvexHull) {
      computeConvexPolygon((Polygon) selectedShape);
      computeConvexHull = false;
      selectedHandle = -1;
    }
  }


  void mouseWheel(MouseEvent event) {
    float z = pow(1.1, -event.getCount());
    tmpVec.set(mouseX, mouseY);
    unproject.applyTo(tmpVec);

    // scale translation by the zoom factor
    transform.translate(tmpVec.x, tmpVec.y).scale(z, z).translate(-tmpVec.x, -tmpVec.y);
    unproject.set(transform).inv();
  }
}
