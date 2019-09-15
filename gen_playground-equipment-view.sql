CREATE MATERIALIZED VIEW playgrounds AS
SELECT tags, osm_id, geom, string_agg(equipment, ',') AS equipment FROM
(SELECT osm_poi_point.tags->'playground' AS equipment,
osm_poi_poly.osm_id AS osm_id,
osm_poi_poly.tags AS tags,
osm_poi_poly.geom AS geom FROM osm_poi_point, osm_poi_poly
WHERE st_within(osm_poi_point.geom, osm_poi_poly.geom)
AND osm_poi_poly.tags->'leisure'='playground' AND osm_poi_point.tags->'playground' IS NOT null) AS z
group by osm_id, tags;






SELECT tags, osm_id, array[round(ST_XMin(geom)::numeric,7),round(ST_YMin(geom)::numeric,7),round(ST_XMax(geom)::numeric,7),round(ST_YMax(geom)::numeric,7)] ::json AS bbox, St_asgeojson(St_centroid(geom)) ::json AS geometry FROM osm_poi_point WHERE %s AND geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326) UNION ALL SELECT tags, osm_id, array[round(ST_XMin(geom)::numeric,7),round(ST_YMin(geom)::numeric,7),round(ST_XMax(geom)::numeric,7),round(ST_YMax(geom)::numeric,7)] AS bbox, St_asgeojson(St_centroid(geom)) ::json AS geometry FROM osm_poi_poly WHERE %s and geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326);
