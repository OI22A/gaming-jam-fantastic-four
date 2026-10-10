class_name TmxReader
extends RefCounted
## Lector de mapas de Tiled (.tmx / .tsx) sin plugins. Godot 4.3 no lee TMX por sí
## solo, así que este lector interpreta el archivo original y devuelve datos listos
## para dibujar y para generar colisiones. No usa ninguna imagen plana del mapa.
##
## Soporta lo que usa "Mapa (Videojuego 24 horas)": mapa ortogonal, capas de tiles en
## CSV, tilesets con una imagen (atlas) o con una imagen por tile, y grupos de objetos
## con rectángulos. Los tiles se alinean abajo a la izquierda de su celda, igual que
## en Tiled.
##
## Resultado de `read()`:
## {
##   "ok": bool, "error": String,
##   "width": int, "height": int, "tile_size": Vector2i, "pixel_size": Vector2,
##   "background": Color,
##   "layers": [{"name": String, "visible": bool, "opacity": float, "gids": PackedInt32Array}],
##   "tilesets": [{"firstgid": int, "columns": int, "tile_size": Vector2i,
##                 "offset": Vector2, "texture": Texture2D, "tiles": {id: Texture2D}}],
##   "objects": {"nombre_del_grupo": [Rect2, ...]},
## }

const FLIP_MASK := 0x1FFFFFFF


static func read(tmx_path: String) -> Dictionary:
	var result := {
		"ok": false,
		"error": "",
		"width": 0,
		"height": 0,
		"tile_size": Vector2i(32, 32),
		"pixel_size": Vector2.ZERO,
		"background": Color(0.23, 0.69, 0.33),
		"layers": [],
		"tilesets": [],
		"objects": {},
	}
	var parser := XMLParser.new()
	if parser.open(tmx_path) != OK:
		result.error = "No se pudo abrir %s" % tmx_path
		return result
	var base_dir := tmx_path.get_base_dir()
	var current_layer: Dictionary = {}
	var current_group := ""
	var in_data := false
	var csv := ""
	while parser.read() == OK:
		match parser.get_node_type():
			XMLParser.NODE_ELEMENT:
				var element := parser.get_node_name()
				match element:
					"map":
						result.width = int(_attr(parser, "width", "0"))
						result.height = int(_attr(parser, "height", "0"))
						result.tile_size = Vector2i(
							int(_attr(parser, "tilewidth", "32")), int(_attr(parser, "tileheight", "32"))
						)
						if parser.has_attribute("backgroundcolor"):
							result.background = Color.html(_attr(parser, "backgroundcolor", "#3aaf54"))
						if _attr(parser, "orientation", "orthogonal") != "orthogonal":
							result.error = "Solo se admiten mapas ortogonales."
							return result
					"tileset":
						var tileset := _read_tileset(
							int(_attr(parser, "firstgid", "1")), base_dir.path_join(_attr(parser, "source", ""))
						)
						if tileset.is_empty():
							result.error = "No se pudo leer el tileset %s" % _attr(parser, "source", "")
							return result
						result.tilesets.append(tileset)
					"layer":
						current_layer = {
							"name": _attr(parser, "name", ""),
							"visible": _attr(parser, "visible", "1") != "0",
							"opacity": float(_attr(parser, "opacity", "1")),
							"gids": PackedInt32Array(),
						}
					"data":
						if _attr(parser, "encoding", "") != "csv":
							result.error = "Las capas deben usar codificación CSV."
							return result
						in_data = true
						csv = ""
					"objectgroup":
						current_group = _attr(parser, "name", "")
						if not result.objects.has(current_group):
							result.objects[current_group] = [] as Array[Rect2]
					"object":
						# Solo rectángulos (sin polígonos, elipses ni puntos).
						if current_group != "" and parser.has_attribute("width") and parser.has_attribute("height"):
							var rect := Rect2(
								float(_attr(parser, "x", "0")),
								float(_attr(parser, "y", "0")),
								float(_attr(parser, "width", "0")),
								float(_attr(parser, "height", "0"))
							)
							if rect.size.x > 0.0 and rect.size.y > 0.0:
								result.objects[current_group].append(rect)
			XMLParser.NODE_TEXT:
				if in_data:
					csv += parser.get_node_data()
			XMLParser.NODE_ELEMENT_END:
				match parser.get_node_name():
					"data":
						in_data = false
						current_layer.gids = _parse_csv(csv)
					"layer":
						result.layers.append(current_layer)
						current_layer = {}
					"objectgroup":
						current_group = ""
	result.pixel_size = Vector2(
		result.width * result.tile_size.x, result.height * result.tile_size.y
	)
	result.ok = result.width > 0 and result.height > 0 and not result.layers.is_empty()
	if not result.ok:
		result.error = "El TMX no contiene un mapa válido."
	return result


## Devuelve [textura, región en la textura, posición relativa a la esquina inferior izquierda
## de la celda] para dibujar el tile `gid`, o un arreglo vacío si no hay nada que dibujar.
static func tile_draw_info(data: Dictionary, gid: int) -> Array:
	gid &= FLIP_MASK
	if gid == 0:
		return []
	var chosen: Dictionary = {}
	for tileset in data.tilesets:
		if tileset.firstgid <= gid and (chosen.is_empty() or tileset.firstgid > chosen.firstgid):
			chosen = tileset
	if chosen.is_empty():
		return []
	var local_id: int = gid - chosen.firstgid
	var texture: Texture2D
	var region: Rect2
	if chosen.tiles.has(local_id):
		texture = chosen.tiles[local_id]
		if texture == null:
			return []
		region = Rect2(Vector2.ZERO, texture.get_size())
	else:
		texture = chosen.texture
		if texture == null or chosen.columns <= 0:
			return []
		var tile_size: Vector2i = chosen.tile_size
		region = Rect2(
			Vector2((local_id % chosen.columns) * tile_size.x, (local_id / chosen.columns) * tile_size.y),
			Vector2(tile_size)
		)
	return [texture, region, chosen.offset]


# --- Internos ---------------------------------------------------------------


static func _attr(parser: XMLParser, name: String, fallback: String) -> String:
	return parser.get_named_attribute_value(name) if parser.has_attribute(name) else fallback


static func _parse_csv(text: String) -> PackedInt32Array:
	var gids := PackedInt32Array()
	for token in text.split(",", false):
		var cleaned := token.strip_edges()
		if cleaned != "":
			# Se descartan los bits de volteo de Tiled (este mapa no usa tiles volteados).
			gids.append(cleaned.to_int() & FLIP_MASK)
	return gids


static func _read_tileset(first_gid: int, tsx_path: String) -> Dictionary:
	var parser := XMLParser.new()
	if parser.open(tsx_path) != OK:
		return {}
	var base_dir := tsx_path.get_base_dir()
	var tileset := {
		"firstgid": first_gid,
		"columns": 0,
		"tile_size": Vector2i(32, 32),
		"offset": Vector2.ZERO,
		"texture": null,
		"tiles": {},
	}
	var current_tile := -1
	while parser.read() == OK:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			match parser.get_node_name():
				"tileset":
					tileset.columns = int(_attr(parser, "columns", "0"))
					tileset.tile_size = Vector2i(
						int(_attr(parser, "tilewidth", "32")), int(_attr(parser, "tileheight", "32"))
					)
				"tileoffset":
					tileset.offset = Vector2(
						float(_attr(parser, "x", "0")), float(_attr(parser, "y", "0"))
					)
				"tile":
					current_tile = int(_attr(parser, "id", "-1"))
				"image":
					var texture := load_texture(base_dir.path_join(_attr(parser, "source", "")))
					if current_tile >= 0:
						tileset.tiles[current_tile] = texture
					else:
						tileset.texture = texture
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			if parser.get_node_name() == "tile":
				current_tile = -1
	return tileset


## Carga la textura importada por Godot; si aún no se ha importado (primer arranque en
## el editor) la lee directamente del PNG.
static func load_texture(path: String) -> Texture2D:
	path = path.simplify_path()
	if ResourceLoader.exists(path):
		var imported := load(path) as Texture2D
		if imported != null:
			return imported
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		push_warning("TmxReader: no se pudo cargar la imagen %s" % path)
		return null
	return ImageTexture.create_from_image(image)
