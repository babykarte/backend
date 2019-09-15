#!/usr/bin/python3
#
import wsgiref.handlers, cgi, psycopg2, json, sys, ast, io
# BOX3D(xmin ymin,xmax ymax)
debug = """park - 10.1207,54.3152,10.1593,54.3309"""
# "SELECT to_json(tags), osm_id, array[round(ST_XMin(geom)::integer,7),round(ST_YMin(geom)::integer,7),round(ST_XMax(geom)::integer,7),round(ST_YMax(geom)::integer,7)] AS bbox, St_asgeojson(St_centroid(geom)) ::json AS geometry FROM osm_poi_point WHERE %condition AND geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326) UNION ALL SELECT to_json(tags), osm_id, array[round(ST_XMin(geom)::integer,7),round(ST_YMin(geom)::integer,7),round(ST_XMax(geom)::integer,7),round(ST_YMax(geom)::integer,7)] AS bbox, St_asgeojson(St_centroid(geom)) ::json AS geometry FROM osm_poi_poly WHERE %condition and geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326);"

data = {}
elem_count = 0
dbconnstr="dbname=gis"
sqls = {"normal": "SELECT to_json(tags), osm_id, St_asgeojson(St_centroid(geom)) ::json AS geometry FROM osm_poi_point WHERE %condition AND geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326) UNION ALL SELECT to_json(tags), osm_id, st_asgeojson(St_centroid(geom)) ::json AS geometry FROM osm_poi_poly WHERE %condition and geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326);",
			"playground": "SELECT to_json(tags), osm_id, St_asgeojson(St_centroid(geom)) ::json AS geometry, equipment from playgrounds where %condition and geom && St_setsrid('BOX3D(%lon1 %lat1, %lon2 %lat2)' ::box3d, 4326);"}
queryLookUp = {"paediatrics": ("tags->'healthcare:speciality'='paediatrics'", "normal", "health"),
				"midwife": ("tags->'healthcare'='midwife'", "normal", "health"),
				"birthing_center": ("tags->'healthcare'='birthing_center'", "normal", "health"),
				"playground": ("tags->'leisure'='playground'", "playground", "activity"),
				"play-equipment": ("tags->''='playground' IS NOT NULL", "normal", "activity"),
				"park": ("tags->'leisure'='park'", "normal", "rest"),
				"shop-babygoods": ("tags->'shop'='baby_goods'", "normal", "shop"),
				"shop-toys": ("tags->'shop'='toys'", "normal", "shop"),
				"shop-clothes": ("tags->'shop'='clothes'", "normal", "shop"),
				"childcare": ("tags->'amenity'='kindergarten' OR tags->'amenity'='childcare'", "normal", "shop"),
				"zoo": ("tags->'tourism'='zoo'", "normal", "activity"),
				"changingtable": ("(tags->'diaper' IS NOT NULL AND tags->'diaper'!='no') OR (tags->'changing_table' IS NOT NULL AND tags->'changing_table'!='no')", "normal", "changingtable"),
				"changingtable-men": ("tags->'diaper:male'='yes' OR tags->'diaper:unisex'='yes' OR tags->'diaper'='room' OR tags->'diaper:wheelchair'='yes' OR tags->'changing_table' IS NOT NULL OR tags->'changing_table' NOT LIKE 'female_toilet'", "normal", "changingtable"),
				"cafe": ("tags->'amenity'='cafe'", "normal", "eat"),
				"restaurant": ("tags->'amenity'='restaurant'", "normal", "eat"),
				"fast_food": ("tags->'amenity'='fast_food'", "normal", "eat"),
			}
def convertToJSON(query, category):
	global data, elem_count
	for row in query:
		data[elem_count] = {}
		if category == "playground":
			data[elem_count]["tags"], data[elem_count]["osm_id"], data[elem_count]["geometry"], data[elem_count]["equipment"] = row
			data[elem_count]["tags"] = json.loads(str(data[elem_count]["tags"]).replace("\\'", "\\ESCAPED").replace("'", "\"").replace("\\ESCAPED", "\\'"))
			for equip in data[elem_count]["equipment"].split(","):
				data[elem_count]["tags"]["playground" + equip] = "yes"
		else:
			data[elem_count]["tags"], data[elem_count]["osm_id"], data[elem_count]["geometry"] = row
			data[elem_count]["tags"] = json.loads(str(data[elem_count]["tags"]).replace("\\'", "\\ESCAPED").replace("'", "\"").replace("\\ESCAPED", "\\'"))
		print("\033[0;34m" + str(data[elem_count]["tags"]) + "\033[0;m")
		elem_count += 1
	stream = io.StringIO()
	json.dump(data, stream, ensure_ascii=False)
	return stream.getvalue()
def lookupQuery(name, bbox):
	if name in queryLookUp:
		condition, mode, category = queryLookUp[name]
		return sqls[mode].replace("%lon1", str(bbox[0])).replace("%lat1", str(bbox[1])).replace("%lon2", str(bbox[2])).replace("%lat2", str(bbox[3])).replace("%condition", condition), category
	else:
		return "ERROR 404", ""
def getData():
	output = ""
	if debug == "":
		filebuffer = sys.stdin.read()
	else:
		filebuffer = debug
	for entry in filebuffer.split("\n"):
		query, bbox = entry.split(" - ")
		query, category = lookupQuery(query.strip(), bbox.split(","))
		print("\033[0;34m" + query + "\033[0;m")
		if query.startswith("ERROR"):
			return query
		try:
			conn = psycopg2.connect(dbconnstr)
			cur = conn.cursor()
			cur.execute(query)
			result = cur.fetchall()
		except Exception as e:
			return "ERROR 504" + e.message
		print(result)
		output += convertToJSON(result, category);
	return output
def application(environ, start_response):
	#start_response('200 OK', [('Content-Type', 'application/json')])
	if "HTTP_COOKIE" in environ:
		environ["HTTP_COOKIE"] = ""
	if "POST" == environ["HTTP_METHOD"]:
		if debug == "":
			return getData()
		else:
			print(getData())
	
	
if __name__ == '__main__':
#wsgiref.handlers.CGIHandler().run(application)
	pass
application({"HTTP_COOKIE": "tesr", "HTTP_METHOD" : "POST"}, False)
