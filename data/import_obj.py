import struct

def hex_from_float(f):
    return hex(struct.unpack('I', struct.pack('f', f))[0]).upper()[2:].zfill(8)

def hex_from_tuple(t):
    strs = [hex_from_float(v) for v in t[::-1]]
    return '_'.join(strs)

f = open('./data/model.obj', 'r')
lines = [line.split() for line in f]

positions = []
normals = []
triangles = []

vertex_map = {}
vertices = []

def make_vertex(key):
    global vertices
    if key in vertex_map:
        return vertex_map[key]
    else:
        vertex_map[key] = len(vertices)
        pos, norm = [int(el) for el in key.split('//')]
        vertices += [(positions[pos-1], normals[norm-1])]
        return vertex_map[key]

for line in lines:
    if line[0] == 'v':
        positions += [tuple(float(el) for el in line[1:4])]

    if line[0] == 'vn':
        normals += [tuple(float(el) for el in line[1:4])]

    if line[0] == 'f':
        triangles += [tuple(make_vertex(el) for el in line[1:4])]

contents = ''
for vertex in vertices:
    contents += hex_from_tuple(vertex[0]) + '__' + hex_from_tuple(vertex[1]) + '\n'

contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF__FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

f = open('./data/vertices.mem', 'w')
f.write(contents)
f.close()

def get_material(index):
    index = index // 2
    index = index % 6
    index = index + 1
    return index

contents = ''
tri_index = 0
for triangle in triangles:
    for index in triangle:
        contents += hex(index)[2:].upper().zfill(3) + '_' + hex(get_material(tri_index))[2:].upper().zfill(3) + '\n'
    tri_index += 1

contents += 'FFF_FFF\n'

f = open('./data/indices.mem', 'w')
f.write(contents)
f.close()
