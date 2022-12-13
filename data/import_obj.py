import struct
import sys
import serial

# s = serial.Serial('COM4', 115200)
s = serial.Serial('/dev/ttyUSB1', 115200)

def hex_from_float(f, l):
    return hex(struct.unpack('I', struct.pack('f', f))[0]).upper()[2:].zfill(l)

def hex_from_int(i, l):
    return hex(struct.unpack('I', struct.pack('i', i))[0]).upper()[2:].zfill(l)

def hex_from_tuple(t, l=8, r=True):
    if r: t = t[::-1]
    if isinstance(t[0], float):
        strs = [hex_from_float(v, l) for v in t]
    else:
        strs = [hex_from_int(v, l) for v in t]
    return '_'.join(strs)

def send_contents(contents):
    lines = contents.split('\n')
    for line in lines:
        if not line: continue
        line = line.replace('_', '')
        if len(line) % 2 != 0:
            line += 'F'
        chars = [line[i:i+2] for i in range(0, len(line), 2)]
        for char in chars:
            byte = bytes.fromhex(char)
            s.write(byte)
            #confirmation = s.read().hex()
            #if (confirmation != char):
            #    print('UART error detected')

name = sys.argv[1]

f = open(f'./models/{name}.mtl', 'r')
lines = [line.split() for line in f]

materials = [(0.75, 0.75, 0.75)]
material_map = {'None': 0}
current_material = 0

for line in lines:
    if not line: continue

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
    pos, uv, norm = key.split('/')
    pos = int(pos)
    norm = int(norm)
    return (pos-1, norm-1, current_material)

for line in lines:
    if not line: continue

    if line[0] == 'v':
        positions += [tuple(float(el) for el in line[1:4])]

    if line[0] == 'vn':
        normals += [tuple(float(el) for el in line[1:4])]

    if line[0] == 'usemtl':
        current_material = material_map[line[1]]

    if line[0] == 'f':
        triangles += [tuple(make_vertex(el) for el in line[1:4])]
        if (len(line) == 5): # obj also can also define quads
            triangles += [tuple(make_vertex(el) for el in [line[3], line[4], line[1]])]

contents = ''
tri_index = 0
for triangle in triangles:
    for index in triangle:
        contents += hex_from_tuple(index, 3, False) + '\n'
    tri_index += 1
contents += 'FFF_FFF_FFF\n'

send_contents(contents)
f = open('./data/indices.mem', 'w')
f.write(contents)
f.close()

contents = ''
for pos in positions:
    contents += hex_from_tuple(pos) + '\n'
contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

send_contents(contents)
f = open('./data/positions.mem', 'w')
f.write(contents)
f.close()

contents = ''
for norm in normals:
    contents += hex_from_tuple(norm) + '\n'
contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

send_contents(contents)
f = open('./data/normals.mem', 'w')
f.write(contents)
f.close()

contents = ''
for material in materials:
    contents += hex_from_tuple(material, 8, False) + '\n'
contents += 'FFFFFFFF_FFFFFFFF_FFFFFFFF\n'

send_contents(contents)
f = open('./data/materials.mem', 'w')
f.write(contents)
f.close()
