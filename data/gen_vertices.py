import struct
import random

def hex_from_float(f):
    return hex(struct.unpack('I', struct.pack('f', f))[0]).upper()[2:].zfill(8)

def hex_from_tuple(t):
    strs = [hex_from_float(v) for v in t[::-1]]
    return '_'.join(strs)

# vertices to convert to mem file
vertices = [
    (0.499969, -0.499969, 0.499969),
    (-0.499969, -0.499969, -0.499969),
    (-0.499969, -0.499969, 0.499969),
    (0.499969, 0.499969, -0.499969),
    (-0.499969, 0.499969, -0.499969),
    (0.499969, -0.499969, -0.499969),
    (0.499969, 0.499969, 0.499969),
    (-0.499969, 0.499969, 0.499969),
]

triangles = [
    (0, 1, 2),
    (1, 3, 4),
    (5, 6, 3),
    (7, 3, 6),
    (2, 4, 7),
    (0, 7, 6),
    (0, 5, 1),
    (2, 1, 4),
    (0, 2, 7),
    (1, 5, 3),
    (5, 0, 6),
    (7, 4, 3),
]

materials = [(random.randint(6, 15), random.randint(6, 15), random.randint(6, 15)) for i in range(len(triangles) * 3)]

contents = ''
for vertex in vertices:
    contents += hex_from_tuple(vertex) + '\n'

contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

f = open('./data/vertices.mem', 'w')
f.write(contents)
f.close()

contents = ''
for material in materials:
    contents += ''.join([hex(comp)[2:].upper().zfill(1) for comp in material]) + '\n'

contents += 'FFF\n'

f = open('./data/materials.mem', 'w')
f.write(contents)
f.close()

contents = ''
for triangle in triangles:
    for index in triangle:
        contents += hex(index)[2:].upper().zfill(3) + '\n'

contents += 'FFF\n'

f = open('./data/indices.mem', 'w')
f.write(contents)
f.close()
