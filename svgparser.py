#! /usr/bin/env python3
# -*- coding: utf-8 -*-

import sys
import xml.etree.ElementTree as ET
import re
import struct

DEBUG = False


# XML Namespaces
ns = {
    'svg': "http://www.w3.org/2000/svg",
    'sodipodi': "http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd",
    'inkscape': "http://www.inkscape.org/namespaces/inkscape"
}

# For illustrator
color_pattern = r".(\w+)\{fill:#([0-9A-Fa-f]{6});\}"


def hex_to_int(hex_str):
    ints = []
    ints.append(int(hex_str[:2], 16))
    ints.append(int(hex_str[2:4], 16))
    ints.append(int(hex_str[4:6], 16))
    
    return ints


def get_color(elt):
    opacity = 255
    
    if "style" in elt.attrib:
        color = re.match(r".*fill:([#\w]+);", elt.attrib["style"])[1]
        if color.lower() == "none":
            return None
        if color.startswith('#'):
            return hex_to_int(color[1:]) + [opacity]
    elif "class" in elt.attrib:
        return hex_to_int(colors[elt.attrib["class"]]) + [opacity]
    return None

"""
def unpack(l):
    out = []
    for e in l:
        if e.tag.endswith('g'):
            out.extend(unpack(e))
        elif e.tag.endswith('polygon'):
            out.append(e)
    return out
"""


pointer_x = 0
pointer_y = 0
def path_to_polygon(p_str):
    global pointer_x, pointer_y
    points = []
    absolute = False;
    i = 0
    
    for k in ['m', 'M', 'l', 'L']:
        p_str = p_str.replace(k, k+' ')
    
    elts = p_str.split()
    while i < len(elts):
        elt = elts[i]
        if elt == "m":
            # moveTo
            absolute = False;
            pointer_x, pointer_y = map(float, elts[i+1].split(','))
            points.append(pointer_x)
            points.append(pointer_y)
            i += 1
        elif elt == "M":
            # MoveTo
            absolute = True;
            pointer_x, pointer_y = map(float, elts[i+1].split(','))
            points.append(pointer_x)
            points.append(pointer_y)
            i += 1
        elif elt == "l":
            # lineTo
            absolute = False;
            dx, dy = map(float, elts[i+1].split(','))
            pointer_x += dx
            pointer_y += dy
            points.append(pointer_x)
            points.append(pointer_y)
            i += 1
        elif elt == "L":
            # LineTo
            absolute = True;
            pointer_x, pointer_y = map(float, elts[i+1].split(','))
            points.append(pointer_x)
            points.append(pointer_y)
        elif elt == 'z' or elt == 'Z':
            # closePath but no need to close the polygon
            pass
        else:
            # implicit lineTo command
            if absolute:
                pointer_x, pointer_y = map(float, elt.split(','))
            else:
                dx, dy = map(float, elt.split(','))
                pointer_x += dx
                pointer_y += dy
            points.append(pointer_x)
            points.append(pointer_y)
        i += 1
    
    return points


def parse(elt):
    output = b''
    for child in elt:
        tag = child.tag.split('}')[1]
        if tag == "path":
            color = get_color(child)
            color = color if color else 4*[255]
            points = path_to_polygon(child.attrib['d'])
            np = len(points) // 2
            print(f"Polygon with {np} vertices")
            if DEBUG:
                print("  " + ' '.join(map(str, color)))
                print("  " + ' '.join(map(str, points)))
            output += b'p' + bytes([np])
            output += struct.pack('4B', *color)
            output += struct.pack(f'>{len(points)}f', *points)
        elif tag == "polygon":
            color = get_color(child)
            points = child.attrib['points']
            points = points.replace(',', ' ').strip().split()
            points = [float(p) for p in points]
            np = len(points) // 2
            print(f"Polygon with {np} vertices")
            if DEBUG:
                print("  " + ' '.join(map(str, color)))
                print("  " + ' '.join(map(str, points)))
            output += b'p' + bytes([np])
            output += struct.pack('4B', *color)
            output += struct.pack(f'>{len(points)}f', *points)
        elif tag == "circle":
            print("Circle")
            color = get_color(child)
            if color:
                data = struct.pack('>3f',
                    float(child.attrib['cx']),
                    float(child.attrib['cy']),
                    float(child.attrib['r']))
                output += b'c'
                output += struct.pack('4B', *color)
                output += data
            else:   # Hinge point
                print("Hinge point")
                output += b'h'
                output += struct.pack('>2f',
                    float(child.attrib['cx']),
                    float(child.attrib['cy']))
        elif tag == "g":    # group
            output += b'go'    # Group Open
            if 'id' in child.attrib:
                label = child.attrib['id']
                print("Id:", label)
                output += b'i' + bytes([len(label)]) + label.encode('ascii')
            output += parse(child)
            output += b'gc'    # Group Close
    return output


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(f"usage: {sys.argv[0]} filename.svg")
        sys.exit()
    
    for fname in sys.argv[1:]:
        print("====== Parsing file : ", fname)
        tree = ET.parse(fname)
        root = tree.getroot()
        
        # Affiche les couleurs utilisées dans le fichier SVG (Illustrator)
        col_text = root.findall("svg:style", ns)
        if col_text:
            colors = dict(re.findall(color_pattern, col_text[0].text))
            print(colors)
    
        with open(fname.replace('svg', 'tdat'), "wb") as fout:
            fout.write(parse(root))
