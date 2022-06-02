#!/usr/bin/python3

import json
import sys

style = json.loads(sys.stdin.read())

style["sources"]["osm-raster-tiles"] = {
    "type": "raster",
    "tiles": [
        "https://tile.openstreetmap.org/{z}/{x}/{y}.png"
    ],
    "tileSize": 256
}

style["layers"].append({
    "id": "osm-tiles",
    "type": "raster",
    "source": "osm-raster-tiles",
    "minzoom": int(sys.argv[1])
})

print(json.dumps(style))
