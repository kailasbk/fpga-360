import struct
import sys

def hex_from_float(f, l):
    return hex(struct.unpack('I', struct.pack('f', f))[0]).upper()[2:].zfill(l)

def hex_from_int(i, l):
    return hex(struct.unpack('I', struct.pack('i', i))[0]).upper()[2:].zfill(l)

def hex_from_tuple(t, l=8):
    if (isinstance(t[0], float)):
        strs = [hex_from_float(v, l) for v in t[::-1]]
    else:
        strs = [hex_from_int(v, l) for v in t]
    return '_'.join(strs)

name = sys.argv[1]

f = open(f'./models/{name}.mtl', 'r')
lines = [line.split() for line in f]

materials = [(0.75, 0.75, 0.75)]
material_map = {'None': 0}
current_material = 0

for line in lines:
    if line[0] == 'newmtl':
        current_material = len(materials)
        material_map[line[1]] = current_material
        materials += [(0.0, 0.0, 0.0)]

    if line[0] == 'Kd':
        materials[current_material] = tuple(float(el) for el in line[1:4])

f = open(f'./models/{name}.obj', 'r')
lines = [line.split() for line in f]

positions = []
normals = []

triangles = []

def make_vertex(key):
    pos, norm = [int(el) for el in key.split('//')]
    return (pos-1, norm-1, current_material)

for line in lines:
    if line[0] == 'v':
        positions += [tuple(float(el) for el in line[1:4])]

    if line[0] == 'vn':
        normals += [tuple(float(el) for el in line[1:4])]

    if line[0] == 'usemtl':
        current_material = material_map[line[1]]

    if line[0] == 'f':
        triangles += [tuple(make_vertex(el) for el in line[1:4])]

contents = ''
for pos in positions:
    contents += hex_from_tuple(pos) + '\n'

contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

f = open('./data/positions.mem', 'w')
f.write(contents)
f.close()

contents = ''
for norm in normals:
    contents += hex_from_tuple(norm) + '\n'

contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

f = open('./data/normals.mem', 'w')
f.write(contents)
f.close()

contents = ''
tri_index = 0
for triangle in triangles:
    for index in triangle:
        contents += hex_from_tuple(index, 3) + '\n'
    tri_index += 1

contents += 'FFF_FFF_FFF\n'

f = open('./data/indices.mem', 'w')
f.write(contents)
f.close()

contents = ''
for material in materials:
    contents += hex_from_tuple(material, 3) + '\n'

contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

f = open('./data/materials.mem', 'w')
f.write(contents)
f.close()
