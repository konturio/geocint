import sys
import json

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
    "minzoom": 9
})

print(json.dumps(style))
