import struct

def hex_from_float(f):
    return hex(struct.unpack('I', struct.pack('f', f))[0]).upper()[2:].zfill(8)

def hex_from_tuple(t):
    strs = [hex_from_float(v) for v in t[::-1]]
    return '_'.join(strs)

# vertices to convert to mem file
vertices = [
    (0.0, 0.666666, 0.5),
    (-0.375, 0.3333333, 0.5),
    (0.25, 0.1666666, 0.5),
    (0.4, -0.1, 0.5),
    (-0.6, 0.6, 0.2),
    (-0.3, 0.1, 0.2),
    (0.1, 0.0, 0.2),
]

contents = ''
for vertex in vertices:
    contents += hex_from_tuple(vertex) + '\n'

contents += '00000000_00000000_00000000\n'

f = open('./data/vertices.mem', 'w')
f.write(contents)
f.close()

