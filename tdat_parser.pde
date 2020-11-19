import java.nio.ByteBuffer;

class PolygonParser {
  private int idx;
  ByteBuffer buffer;
  
  PolygonParser() {
  }
  
  public ComplexShape parse(File inFile) {
    return parse(loadBytes(inFile));
  }
  
  public ComplexShape parse(String filename) {
   return parse(loadBytes(filename)); 
  }
  
  public ComplexShape parse(byte[] data) {
    buffer = ByteBuffer.wrap(data);
    idx = 0;
    float red, green, blue, alpha;
    float x, y;
    Deque<ComplexShape> stack = new ArrayDeque();
    ComplexShape currentShape = new ComplexShape();
    //stack.push(currentShape);
    
    while (idx < data.length) {
      char c = nextChar();
      switch (c) {
        case 'g':
          char nc = nextChar();
          if (nc == 'o') {
            // open group
            stack.push(currentShape);
            currentShape = new ComplexShape();
          } else if (nc == 'c') {
            // close group
            for (int i=0; i<stack.size(); i++) {
              print("-");
            }
            ComplexShape parent = stack.pop();
            parent.addShape(currentShape);
            println(currentShape);
            currentShape = parent;
          }
          break;
        case 'p':  // Polygon
          int n = (int) nextByte();  // Number of vertices in polygon
          red = nextByte() / 254.f;
          green = nextByte() / 254.f;
          blue = nextByte() / 254.f;
          alpha = nextByte() / 254.f;
          float[] verts = new float[n*2];
          for (int i=0; i<verts.length; i++)
            verts[i] = nextFloat();
          Polygon shape = new Polygon(verts, null);
          shape.setColor(red, green, blue, alpha);
          currentShape.addShape(shape);
          break;
        case 'c':  // Circle
          red = nextByte() / 254.f;
          green = nextByte() / 254.f;
          blue = nextByte() / 254.f;
          alpha = nextByte() / 254.f;
          x = nextFloat();
          y = nextFloat();
          float radius = nextFloat();
          Circle circle = new Circle(x, y, radius);
          circle.setColor(red, green, blue, alpha);
          currentShape.addShape(circle);
          break;
        case 'h':  // Hinge/localOrigin
          x = nextFloat();
          y = nextFloat();
          currentShape.setLocalOrigin(x, y);
          break;
        case 'i':  // ID label
          String label = "";
          n = (int) nextByte();
          for (int i=0; i<n; i++)
            label += nextChar();
          currentShape.setId(label);
          break;
        default:
          println(hex(idx), c);
          break;
      }
    }
    return currentShape;
  }
  
  private float nextFloat() {
    float val = buffer.getFloat(idx);
    idx += 4;
    return val;
  }
  
  private char nextChar() {
    char c = (char) buffer.get(idx);
    idx += 1;
    return c;
  }
  
  private int nextByte() {
    byte b = buffer.get(idx);
    idx += 1;
    return b & 0xff;
  }
}
