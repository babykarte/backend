CREATE MATERIALIZED VIEW playgrounds AS
SELECT playgroundtags, playgroundid, string_agg(equipment, ',') AS equipment FROM
(SELECT osm_poi_point.tags->'playground' AS equipment,
osm_poi_poly.osm_id AS playgroundid,
osm_poi_poly.tags AS playgroundtags,
osm_poi_poly.geom AS playgroundgeom FROM osm_poi_point, osm_poi_poly
WHERE st_within(osm_poi_point.geom, osm_poi_poly.geom)
AND osm_poi_poly.tags->'leisure'='playground' AND osm_poi_point.tags->'playground' IS NOT null) AS z
group by playgroundid, playgroundtags;
