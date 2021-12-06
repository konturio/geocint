import sys
import json

style = json.loads(sys.stdin.read())

land_style = next(
    layer
    for layer in style["layers"]
    if layer["type"] == "fill"
    and layer.get("filter") is not None
    and layer["filter"] == ["all", ["==", ["get", "natural"], "coastline"]]
).copy()
land_style["id"] = "land"
style["layers"].append(land_style)

country_label_style = next(
    layer
    for layer in style["layers"]
    if layer["type"] == "symbol"
    and layer.get("filter") is not None
    and layer["filter"] == ["all", ["==", ["get", "place"], "country"]]
).copy()
country_label_style["id"] = "country-label"
style["layers"].append(country_label_style)

admin_style = next(
    layer
    for layer in style["layers"]
    if layer["type"] == "line"
    and layer.get("filter") is not None
    and ["==", ["get", "boundary"], "administrative"] in layer["filter"]
    and ["==", ["get", "admin_level"], "2"] in layer["filter"]
).copy()
admin_style["id"] = "admin-3-4-boundaries"
style["layers"].append(admin_style)

water_style = next(
    layer
    for layer in style["layers"]
    if layer["id"] == "bg"
).copy()
water_style["id"] = "water"
style["layers"].append(water_style)

print(json.dumps(style))
