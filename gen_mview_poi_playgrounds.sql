-- create MATERIALIZED VIEW osm_poi_playgrounds
-- with list of equipment and sport facilities
--
-- 2019-10-08 Sven Geggus <sven-osm@geggus.net>
-- 2019-10-09 Sören Reinecke alias Valor Naram <valinora@gmx.net>
-- 	Minor changes in columns: Added column 'osm_type'
-- 2019-10-09 Sven Geggus osm_type "richtig"

CREATE INDEX osm_poi_point_playground_index ON osm_poi_point USING GIST (geom) WHERE (tags->'leisure') = 'playground';
CREATE INDEX osm_poi_poly_playground_index ON osm_poi_poly USING GIST (geom) WHERE (tags->'leisure') = 'playground';

CREATE MATERIALIZED VIEW osm_poi_playgrounds AS
SELECT    (-1*poly.osm_id)      AS osm_id,
          poly.tags AS tags,
          poly.geom AS geom,
          'way' as osm_type,
          -- This will produce a list of available playground facilities on the premises
          array_remove(array_agg(DISTINCT CASE WHEN (_st_intersects(poly.geom, pt.geom) AND (pt.tags ? 'playground') AND (pt.osm_id != poly.osm_id)) THEN pt.tags->'playground' END),NULL) as equipment,
          -- This will produce a list of available sport facilities on the premises
          array_remove(array_agg(DISTINCT CASE WHEN (_st_intersects(poly.geom, pt.geom) AND (pt.tags ? 'sport') AND (pt.osm_id != poly.osm_id)) THEN pt.tags->'sport' END),NULL) as sport
FROM      osm_poi_poly                               AS poly
LEFT JOIN osm_poi_all                                AS pt
ON        poly.geom && pt.geom
WHERE     (poly.tags->'leisure' = 'playground')
-- campsites from OSM ways
          AND (poly.osm_id < 0) AND (poly.osm_id > -1e17)
GROUP BY  poly.osm_id,
          poly.geom,
          poly.tags,
          osm_type
UNION ALL
SELECT    (-1*(poly.osm_id+1e17)) AS osm_id,
          poly.tags AS tags,
          poly.geom AS geom,
          'relation' as osm_type,
          -- This will produce a list of available playground facilities on the premises
          array_remove(array_agg(DISTINCT CASE WHEN (_st_intersects(poly.geom, pt.geom) AND (pt.tags ? 'playground') AND (pt.osm_id != poly.osm_id)) THEN pt.tags->'playground' END),NULL) as equipment,
          -- This will produce a list of available sport facilities on the premises
          array_remove(array_agg(DISTINCT CASE WHEN (_st_intersects(poly.geom, pt.geom) AND (pt.tags ? 'sport') AND (pt.osm_id != poly.osm_id)) THEN pt.tags->'sport' END),NULL) as sport
FROM      osm_poi_poly                               AS poly
LEFT JOIN osm_poi_all                                AS pt
ON        poly.geom && pt.geom
WHERE     (poly.tags->'leisure' = 'playground')
-- campsites from OSM relations
          AND (poly.osm_id < -1e17)
GROUP BY  poly.osm_id,
          poly.geom,
          poly.tags,
          osm_type
UNION ALL
SELECT    osm_id,
          tags,
          geom,
          'node' as osm_type,
          '{}',
          '{}'
FROM      osm_poi_point          
WHERE     (tags->'leisure' = 'playground');

