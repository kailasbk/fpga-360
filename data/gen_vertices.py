import struct
import random

def hex_from_float(f):
    return hex(struct.unpack('I', struct.pack('f', f))[0]).upper()[2:].zfill(8)

def hex_from_tuple(t):
    strs = [hex_from_float(v) for v in t[::-1]]
    return '_'.join(strs)

# vertices to convert to mem file
vertices = [
    (1.000000, 1.000000, -1.000000),
    (1.000000, -1.000000, -1.000000),
    (1.000000, 1.000000, 1.000000),
    (1.000000, -1.000000, 1.000000),
    (-1.000000, 1.000000, -1.000000),
    (-1.000000, -1.000000, -1.000000),
    (-1.000000, 1.000000, 1.000000),
    (-1.000000, -1.000000, 1.000000),
]

triangles = [
    (5, 3, 1),
    (5, 7, 3),
    (3, 8, 4),
    (3, 7, 8),
    (1, 4, 2),
    (1, 3, 4),
    (5, 2, 6),
    (5, 1, 2),
    (7, 6, 8),
    (7, 5, 6),
    (2, 8, 6),
    (2, 4, 8),
]

contents = ''
for vertex in vertices:
    contents += hex_from_tuple(vertex) + '\n'

contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

f = open('./data/vertices.mem', 'w')
f.write(contents)
f.close()

contents = ''
material = 2
for triangle in triangles:
    for index in triangle:
        contents += hex(index - 1)[2:].upper().zfill(3) + '_' + hex(material//2)[2:].upper().zfill(3) + '\n'
    material += 1

contents += 'FFF_FFF\n'

f = open('./data/indices.mem', 'w')
f.write(contents)
f.close()
