class_name StageManager
extends RefCounted

## Registri 12 Map Arena (Stage Select).
## Satu-satunya sumber kebenaran untuk id, nama, aset, dan ambience tiap map.
## Untuk MENGGANTI gambar: timpa file PNG pada `background` / `thumbnail` dengan nama yang sama
## (background ideal 1152x480 landscape; kaki petarung berada di floor_ratio * tinggi gambar).
## Untuk MENAMBAH map: tambahkan satu entri ke STAGES (id unik) + dua file PNG.

const DEFAULT_STAGE: StringName = &"sakura_temple"
const MAPS_DIR := "res://assets/maps/"
const THUMBS_DIR := "res://assets/map_thumbnails/"

## ambience: petals | rain | embers | leaves | clouds | snow | dust | stars | none
const STAGES: Array[Dictionary] = [
	{"id": &"sakura_temple", "name": "SAKURA TEMPLE", "tag": "JAPAN", "ambience": &"petals", "floor_ratio": 0.74, "accent": Color(1.0, 0.55, 0.75)},
	{"id": &"neon_city", "name": "NEON CITY", "tag": "NIGHT CITY", "ambience": &"rain", "floor_ratio": 0.74, "accent": Color(0.75, 0.35, 1.0)},
	{"id": &"ruin_factory", "name": "RUIN FACTORY", "tag": "DESERTED AREA", "ambience": &"embers", "floor_ratio": 0.74, "accent": Color(1.0, 0.55, 0.2)},
	{"id": &"forest_shrine", "name": "FOREST SHRINE", "tag": "MOUNTAIN", "ambience": &"leaves", "floor_ratio": 0.74, "accent": Color(0.4, 0.9, 0.5)},
	{"id": &"rooftop", "name": "ROOFTOP", "tag": "CITY VIEW", "ambience": &"clouds", "floor_ratio": 0.74, "accent": Color(1.0, 0.6, 0.3)},
	{"id": &"snow_field", "name": "SNOW FIELD", "tag": "ICY LAND", "ambience": &"snow", "floor_ratio": 0.74, "accent": Color(0.6, 0.85, 1.0)},
	{"id": &"canyon", "name": "CANYON", "tag": "WILD WEST", "ambience": &"dust", "floor_ratio": 0.74, "accent": Color(1.0, 0.65, 0.4)},
	{"id": &"moon_castle", "name": "MOON CASTLE", "tag": "NIGHT", "ambience": &"petals", "floor_ratio": 0.74, "accent": Color(0.6, 0.65, 1.0)},
	{"id": &"ancient_ruins", "name": "ANCIENT RUINS", "tag": "ANCIENT", "ambience": &"dust", "floor_ratio": 0.74, "accent": Color(0.55, 0.9, 0.55)},
	{"id": &"space_station", "name": "SPACE STATION", "tag": "SPACE", "ambience": &"stars", "floor_ratio": 0.74, "accent": Color(0.3, 0.8, 1.0)},
	{"id": &"traditional_town", "name": "TRADITIONAL TOWN", "tag": "TRADITIONAL", "ambience": &"petals", "floor_ratio": 0.74, "accent": Color(1.0, 0.7, 0.55)},
	{"id": &"hell_gate", "name": "HELL GATE", "tag": "INFERNO", "ambience": &"embers", "floor_ratio": 0.74, "accent": Color(1.0, 0.3, 0.2)},
]

static var _texture_cache: Dictionary = {}

static func get_stages() -> Array[Dictionary]:
	return STAGES

static func get_count() -> int:
	return STAGES.size()

static func has_stage(stage_id: StringName) -> bool:
	return index_of(stage_id) != -1

static func index_of(stage_id: StringName) -> int:
	for i in range(STAGES.size()):
		if STAGES[i]["id"] == stage_id:
			return i
	return -1

static func get_stage(stage_id: StringName) -> Dictionary:
	var idx := index_of(stage_id)
	if idx == -1:
		idx = 0
	return STAGES[idx]

static func get_background_path(stage_id: StringName) -> String:
	return MAPS_DIR + String(stage_id) + ".png"

static func get_thumbnail_path(stage_id: StringName) -> String:
	return THUMBS_DIR + String(stage_id) + ".png"

static func get_background_texture(stage_id: StringName) -> Texture2D:
	return _load_texture(get_background_path(stage_id), get_stage(stage_id))

static func get_thumbnail_texture(stage_id: StringName) -> Texture2D:
	return _load_texture(get_thumbnail_path(stage_id), get_stage(stage_id))

## true jika file gambar asli tersedia (bukan placeholder)
static func has_real_background(stage_id: StringName) -> bool:
	return _file_available(get_background_path(stage_id))

static func _file_available(path: String) -> bool:
	return ResourceLoader.exists(path) or FileAccess.file_exists(ProjectSettings.globalize_path(path))

static func _load_texture(path: String, stage: Dictionary) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path]
	var tex: Texture2D = null
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			tex = res
	if tex == null:
		var abs_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(abs_path):
			var img := Image.load_from_file(abs_path)
			if img and not img.is_empty():
				tex = ImageTexture.create_from_image(img)
	if tex == null:
		tex = _make_placeholder(stage)
	_texture_cache[path] = tex
	return tex

## Placeholder gradien berwarna aksen, dipakai bila file PNG belum ada.
static func _make_placeholder(stage: Dictionary) -> Texture2D:
	var accent: Color = stage.get("accent", Color(0.5, 0.5, 0.6))
	var w := 328
	var h := 143
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in range(h):
		var t := float(y) / float(h - 1)
		var c := accent.darkened(0.75).lerp(accent, t * 0.8)
		for x in range(w):
			img.set_pixel(x, y, c)
	for x in range(w):
		img.set_pixel(x, int(h * 0.74), accent.lightened(0.3))
	return ImageTexture.create_from_image(img)
