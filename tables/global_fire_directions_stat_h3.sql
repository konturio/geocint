CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS h3_postgis;

CREATE TABLE IF NOT EXISTS temp_h3_table (
    h3 h3index PRIMARY KEY,
    geom geometry
);

DROP TABLE IF EXISTS global_fire_directions_stat_h3;

CREATE TABLE global_fire_directions_stat_h3 AS (
    WITH wildfire_hexagons AS (
        -- identifies hexagons with wildfires
        SELECT
            h3,
            h3_to_geoboundary(h3) AS geom
        FROM
            global_fires_stat_h3
    ),
    nearby_hexagons AS (
        -- generates hexagons within 5 tiles of each wildfire hexagon
        SELECT
            wf.h3 AS wildfire_h3,
            wf.geom AS wildfire_geom,
            nh.h3 AS nearby_h3,
            h3_to_geoboundary(nh.h3) AS nearby_geom
        FROM
            wildfire_hexagons wf,
            LATERAL (
                SELECT h3
                FROM unnest(h3_kring(wf.h3, 5)) AS h3
            ) nh
    ),
    directions AS (
        -- calculates the direction from each nearby hexagon away from the wildfire
        SELECT
            nearby_h3,
            wildfire_h3,
            wildfire_geom,
            nearby_geom,
            CASE
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < pi() / 8 OR ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 15 * pi() / 8 THEN 'N'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 3 * pi() / 8 THEN 'NE'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 3 * pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 5 * pi() / 8 THEN 'E'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 5 * pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 7 * pi() / 8 THEN 'SE'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 7 * pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 9 * pi() / 8 THEN 'S'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 9 * pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 11 * pi() / 8 THEN 'SW'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 11 * pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 13 * pi() / 8 THEN 'W'
                WHEN ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) >= 13 * pi() / 8 AND ST_Azimuth(ST_Centroid(wildfire_geom), ST_Centroid(nearby_geom)) < 15 * pi() / 8 THEN 'NW'
            END AS direction
        FROM
            nearby_hexagons
    )
    SELECT
        nearby_h3 AS h3,
        direction,
        wildfire_h3,
        wildfire_geom,
        nearby_geom
    FROM
        directions
);

-- creates indexes for faster querying if necessary
CREATE INDEX ON global_fire_directions_stat_h3 (h3);
CREATE INDEX ON global_fire_directions_stat_h3 (direction);
