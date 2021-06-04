import sys

minzoom = int(sys.argv[1])
maxzoom = int(sys.argv[2])

for z in range(minzoom, maxzoom + 1):
    for x in range(0, 2 ** z):
        for y in range(0, 2 ** z):
            print("%s,%s,%s" % (z, x, y))
