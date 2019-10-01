CREATE MATERIALIZED VIEW osm_poi_playgrounds AS
SELECT tags, osm_id, geom, string_agg(equipment, ',') AS equipment FROM
(SELECT osm_poi_point.tags->'playground' AS equipment,
osm_poi_poly.osm_id AS osm_id,
osm_poi_poly.tags AS tags,
osm_poi_poly.geom AS geom FROM osm_poi_point, osm_poi_poly
WHERE (st_within(osm_poi_point.geom, osm_poi_poly.geom)
AND (osm_poi_poly.tags->'leisure'='playground' AND osm_poi_point.tags->'playground' IS NOT null))) AS z
GROUP BY osm_id, tags, z.geom UNION ALL
SELECT tags, osm_id, geom, 'null' AS equipment
FROM osm_poi_point WHERE osm_poi_point.tags->'leisure'='playground'
group by osm_id, tags, geom;

CREATE INDEX osm_poi_point_playground_index ON osm_poi_point USING GIST (geom) WHERE (tags->'leisure') = 'playground';
CREATE INDEX osm_poi_poly_playground_index ON osm_poi_poly USING GIST (geom) WHERE (tags->'leisure') = 'playground';
