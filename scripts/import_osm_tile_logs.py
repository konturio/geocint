import sys
date = sys.argv[1].replace("data/tile_logs/", "").replace("tiles-", "").replace(".txt.xz", "")
for line in sys.stdin:
    line_preproc = date + "Z," + line.replace("/", ",").replace(" ", ",").replace("\n", "")
    print(line_preproc)

