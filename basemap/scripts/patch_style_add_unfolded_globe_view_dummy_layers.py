import sys
import json
from copy import deepcopy

style = json.loads(sys.stdin.read())

land_style = deepcopy(
    next(
        layer
        for layer in style["layers"]
        if layer["type"] == "fill"
        and layer.get("filter") is not None
        and layer["filter"] == ["all", ["==", ["get", "natural"], "coastline"]]
    )
)
land_style["layout"]["visibility"] = "none"
land_style["paint"]["background-color"] = land_style["paint"]["fill-color"]
del land_style["paint"]["fill-color"]
del land_style["paint"]["fill-opacity"]
land_style["type"] = "background"
land_style["id"] = "background"
land_style["filter"] = ["boolean", False]
style["layers"].append(land_style)

try:
    coastline_style = deepcopy(
        next(
            layer
            for layer in style["layers"]
            if layer["type"] == "line"
            and layer.get("filter") is not None
            and layer["filter"] == ["all", ["==", ["get", "natural"], "coastline"]]
        )
    )
    coastline_style["layout"]["visibility"] = "none"
    coastline_style["filter"] = ["boolean", False]
    coastline_style["id"] = "coastline"
    style["layers"].append(coastline_style)
except Exception:
    sys.stderr.write("coastline style is not presented in the style")
    pass

country_label_style = deepcopy(
    next(
        layer
        for layer in style["layers"]
        if layer["type"] == "symbol"
        and layer.get("filter") is not None
        and layer["filter"] == ["all", ["==", ["get", "place"], "country"]]
    )
)
country_label_style["layout"]["visibility"] = "none"
country_label_style["id"] = "country-label"
country_label_style["filters"] = ["false"]
style["layers"].append(country_label_style)

admin_style = deepcopy(
    next(
        layer
        for layer in style["layers"]
        if layer["type"] == "line"
        and layer.get("filter") is not None
        and ["==", ["get", "boundary"], "administrative"] in layer["filter"]
        and ["==", ["get", "admin_level"], "2"] in layer["filter"]
    )
)
admin_style["layout"]["visibility"] = "none"
admin_style["id"] = "admin-3-4-boundaries"
admin_style["filter"] = ["boolean", False]
style["layers"].append(admin_style)

water_style = deepcopy(
    next(layer for layer in style["layers"] if layer["type"] == "background")
)
water_style["layout"]["visibility"] = "none"
water_style["paint"]["fill-color"] = water_style["paint"]["background-color"]
del water_style["paint"]["background-color"]
water_style["source"] = "composite"
water_style["source-layer"] = "area"
water_style["type"] = "fill"
water_style["id"] = "water"
water_style["filter"] = ["boolean", False]
style["layers"].append(water_style)

print(json.dumps(style))
