class_name ArenaStage
extends Node2D

## Arena generik untuk 12 map Stage Select.
## Membaca MatchConfig.selected_stage -> memasang background (parallax) + ambience ringan.
## Geometri (lantai y=288, dinding x=52 / x=1356) identik dengan arena lain sehingga
## kontrol, collision, dan pertarungan tidak berubah.

const CAMERA_Y: float = 209.0
const BG_HEIGHT: float = 430.0
const PARALLAX: float = 0.6
const FLOOR_Y: float = 288.0
const CENTER_X: float = 704.0

@export var platform_width: float = 1280.0
@export var left_bound: float = 64.0
@export var right_bound: float = 1344.0
@export var stage_id: StringName = &""
@export var spawn_p1: Vector2 = Vector2(560.0, 280.0)
@export var spawn_p2: Vector2 = Vector2(848.0, 280.0)

@onready var platform_body: StaticBody2D = $Platform
@onready var left_wall: StaticBody2D = $LeftWall
@onready var right_wall: StaticBody2D = $RightWall
@onready var camera: Camera2D = $Camera2D

const StageThemedPlatformScript = preload("res://scripts/arena/stage_themed_platform.gd")
const StageFloorVisualScript = preload("res://scripts/arena/stage_floor_visual.gd")

var registered_fighters: Array[Node2D] = []
var background_sprite: Sprite2D = null
var ambience: StageAmbience = null
var elevated_platforms: Array[StaticBody2D] = []
var floor_visual: Node2D = null
var _track_retries: int = 120

func _ready() -> void:
	if stage_id == &"":
		stage_id = MatchConfig.selected_stage
	if not StageManager.has_stage(stage_id):
		stage_id = StageManager.DEFAULT_STAGE
	_setup_background()
	_setup_themed_platforms()
	_setup_camera()
	_setup_audio()
	_find_fighters_in_tree()

func _setup_themed_platforms() -> void:
	# 1. Pasang visual lantai utama bertema pada Platform dasar (Y=300)
	if platform_body:
		floor_visual = StageFloorVisualScript.new(stage_id, platform_width, 24.0)
		floor_visual.name = "StageFloorVisual"
		platform_body.add_child(floor_visual)

	# 2. Pasang platform bertingkat sesuai konfigurasi tema
	# Syarat:
	# - Tengah TIDAK BOLEH KOSONG (selalu ada platform di X=704)
	# - Tempat munculnya karakter (P1 di X=560, P2 di X=848) TIDAK BOLEH KOSONG
	# - Semua platform memiliki variasi posisi, dimensi, dan layout sesuai tema 12 map
	elevated_platforms.clear()
	var configs := _get_platform_configs_for_stage(stage_id)
	for i in range(configs.size()):
		var cfg: Dictionary = configs[i]
		var pos: Vector2 = cfg.get("pos", Vector2(CENTER_X, 196.0))
		var size: Vector2 = cfg.get("size", Vector2(170.0, 14.0))
		var is_left: bool = cfg.get("is_left", pos.x < CENTER_X)
		var p_name: String = cfg.get("name", "ThemedPlatform_%d" % i)
		var plat = StageThemedPlatformScript.new(stage_id, size, is_left)
		plat.name = p_name
		plat.position = pos
		add_child(plat)
		elevated_platforms.append(plat)

## Menghasilkan konfigurasi layout platform yang unik & bervariasi untuk masing-masing 12 map
func _get_platform_configs_for_stage(s_id: StringName) -> Array[Dictionary]:
	match s_id:
		&"sakura_temple":
			return [
				{"name": "Center_ShrineAltar", "pos": Vector2(704.0, 196.0), "size": Vector2(190.0, 14.0)},
				{"name": "P1_ToriiBeam", "pos": Vector2(540.0, 224.0), "size": Vector2(160.0, 14.0), "is_left": true},
				{"name": "P2_ToriiBeam", "pos": Vector2(868.0, 224.0), "size": Vector2(160.0, 14.0), "is_left": false},
				{"name": "Left_LanternLedge", "pos": Vector2(340.0, 178.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_LanternLedge", "pos": Vector2(1068.0, 178.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"neon_city":
			return [
				{"name": "Center_HoloMatrix", "pos": Vector2(704.0, 180.0), "size": Vector2(210.0, 14.0)},
				{"name": "P1_HardlightRamp", "pos": Vector2(550.0, 218.0), "size": Vector2(160.0, 14.0), "is_left": true},
				{"name": "P2_HardlightRamp", "pos": Vector2(858.0, 218.0), "size": Vector2(160.0, 14.0), "is_left": false},
				{"name": "Left_CyberPad", "pos": Vector2(350.0, 160.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_CyberPad", "pos": Vector2(1058.0, 160.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"ruin_factory":
			return [
				{"name": "Center_GirderCatwalk", "pos": Vector2(704.0, 204.0), "size": Vector2(220.0, 16.0)},
				{"name": "P1_PipeGantry", "pos": Vector2(530.0, 228.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_PipeGantry", "pos": Vector2(878.0, 228.0), "size": Vector2(150.0, 14.0), "is_left": false},
				{"name": "Upper_CraneBeam", "pos": Vector2(704.0, 136.0), "size": Vector2(160.0, 14.0)},
				{"name": "Left_ScrapGantry", "pos": Vector2(330.0, 172.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_ScrapGantry", "pos": Vector2(1078.0, 172.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"forest_shrine":
			return [
				{"name": "Center_SacredCanopy", "pos": Vector2(704.0, 192.0), "size": Vector2(190.0, 14.0)},
				{"name": "P1_CedarBranch", "pos": Vector2(540.0, 220.0), "size": Vector2(160.0, 14.0), "is_left": true},
				{"name": "P2_CedarBranch", "pos": Vector2(868.0, 220.0), "size": Vector2(160.0, 14.0), "is_left": false},
				{"name": "Left_MossBoulder", "pos": Vector2(360.0, 184.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_MossBoulder", "pos": Vector2(1048.0, 184.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"rooftop":
			return [
				{"name": "Center_VentBridge", "pos": Vector2(704.0, 188.0), "size": Vector2(210.0, 14.0)},
				{"name": "P1_HelipadCatwalk", "pos": Vector2(530.0, 222.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_HelipadCatwalk", "pos": Vector2(878.0, 222.0), "size": Vector2(150.0, 14.0), "is_left": false},
				{"name": "Left_TowerPlatform", "pos": Vector2(350.0, 168.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_TankPlatform", "pos": Vector2(1058.0, 168.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"snow_field":
			return [
				{"name": "Center_GlacierLedge", "pos": Vector2(704.0, 194.0), "size": Vector2(190.0, 14.0)},
				{"name": "P1_SnowTerrace", "pos": Vector2(530.0, 224.0), "size": Vector2(160.0, 14.0), "is_left": true},
				{"name": "P2_SnowTerrace", "pos": Vector2(878.0, 224.0), "size": Vector2(160.0, 14.0), "is_left": false},
				{"name": "Left_IceSpire", "pos": Vector2(340.0, 172.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_IceSpire", "pos": Vector2(1068.0, 172.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"canyon":
			return [
				{"name": "Center_MesaOutcrop", "pos": Vector2(704.0, 198.0), "size": Vector2(210.0, 14.0)},
				{"name": "P1_RedSandstone", "pos": Vector2(540.0, 226.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_RedSandstone", "pos": Vector2(868.0, 226.0), "size": Vector2(150.0, 14.0), "is_left": false},
				{"name": "Left_DesertRidge", "pos": Vector2(360.0, 174.0), "size": Vector2(140.0, 14.0), "is_left": true},
				{"name": "Right_DesertRidge", "pos": Vector2(1048.0, 174.0), "size": Vector2(140.0, 14.0), "is_left": false}
			]
		&"moon_castle":
			return [
				{"name": "Center_CastleBalcony", "pos": Vector2(704.0, 186.0), "size": Vector2(200.0, 14.0)},
				{"name": "P1_GothicParapet", "pos": Vector2(530.0, 220.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_GothicParapet", "pos": Vector2(878.0, 220.0), "size": Vector2(150.0, 14.0), "is_left": false},
				{"name": "Upper_Observatory", "pos": Vector2(704.0, 128.0), "size": Vector2(140.0, 12.0)},
				{"name": "Left_TurretLedge", "pos": Vector2(340.0, 168.0), "size": Vector2(120.0, 12.0), "is_left": true},
				{"name": "Right_TurretLedge", "pos": Vector2(1068.0, 168.0), "size": Vector2(120.0, 12.0), "is_left": false}
			]
		&"ancient_ruins":
			return [
				{"name": "Center_TempleAltar", "pos": Vector2(704.0, 190.0), "size": Vector2(200.0, 14.0)},
				{"name": "P1_PillarCapital", "pos": Vector2(540.0, 222.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_PillarCapital", "pos": Vector2(868.0, 222.0), "size": Vector2(150.0, 14.0), "is_left": false},
				{"name": "Left_AncientMonolith", "pos": Vector2(350.0, 166.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_AncientMonolith", "pos": Vector2(1058.0, 166.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"space_station":
			return [
				{"name": "Center_CommandRepulsor", "pos": Vector2(704.0, 174.0), "size": Vector2(220.0, 14.0)},
				{"name": "P1_DockingDeck", "pos": Vector2(530.0, 214.0), "size": Vector2(160.0, 14.0), "is_left": true},
				{"name": "P2_DockingDeck", "pos": Vector2(878.0, 214.0), "size": Vector2(160.0, 14.0), "is_left": false},
				{"name": "Upper_FusionCore", "pos": Vector2(704.0, 120.0), "size": Vector2(150.0, 12.0)},
				{"name": "Left_TelemetryRelay", "pos": Vector2(330.0, 168.0), "size": Vector2(120.0, 12.0), "is_left": true},
				{"name": "Right_TelemetryRelay", "pos": Vector2(1078.0, 168.0), "size": Vector2(120.0, 12.0), "is_left": false}
			]
		&"traditional_town":
			return [
				{"name": "Center_BridgePavilion", "pos": Vector2(704.0, 196.0), "size": Vector2(210.0, 14.0)},
				{"name": "P1_VerandaDeck", "pos": Vector2(530.0, 224.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_VerandaDeck", "pos": Vector2(878.0, 224.0), "size": Vector2(150.0, 14.0), "is_left": false},
				{"name": "Left_EavesPlatform", "pos": Vector2(350.0, 176.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_EavesPlatform", "pos": Vector2(1058.0, 176.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		&"hell_gate":
			return [
				{"name": "Center_MagmaCrag", "pos": Vector2(704.0, 192.0), "size": Vector2(210.0, 14.0)},
				{"name": "P1_VolcanicRock", "pos": Vector2(530.0, 224.0), "size": Vector2(160.0, 14.0), "is_left": true},
				{"name": "P2_VolcanicRock", "pos": Vector2(878.0, 224.0), "size": Vector2(160.0, 14.0), "is_left": false},
				{"name": "Upper_HellAltar", "pos": Vector2(704.0, 130.0), "size": Vector2(150.0, 12.0)},
				{"name": "Left_ObsidianSpire", "pos": Vector2(340.0, 170.0), "size": Vector2(130.0, 12.0), "is_left": true},
				{"name": "Right_ObsidianSpire", "pos": Vector2(1068.0, 170.0), "size": Vector2(130.0, 12.0), "is_left": false}
			]
		_:
			return [
				{"name": "Center_Platform", "pos": Vector2(704.0, 196.0), "size": Vector2(180.0, 14.0)},
				{"name": "P1_Platform", "pos": Vector2(540.0, 220.0), "size": Vector2(150.0, 14.0), "is_left": true},
				{"name": "P2_Platform", "pos": Vector2(868.0, 220.0), "size": Vector2(150.0, 14.0), "is_left": false}
			]

func get_elevated_platforms() -> Array[StaticBody2D]:
	return elevated_platforms

func _setup_camera() -> void:
	if camera:
		camera.position = Vector2(CENTER_X, CAMERA_Y)
		if "default_y" in camera:
			camera.default_y = CAMERA_Y
		if "base_position" in camera:
			camera.base_position = camera.position

func _setup_audio() -> void:
	var audio_mgr := get_node_or_null("AudioManager")
	if audio_mgr and audio_mgr.has_method("play_bgm"):
		audio_mgr.play_bgm(&"arena")

func _setup_background() -> void:
	var info := StageManager.get_stage(stage_id)
	var tex: Texture2D = StageManager.get_background_texture(stage_id)
	var floor_ratio: float = float(info.get("floor_ratio", 0.74))
	background_sprite = Sprite2D.new()
	background_sprite.name = "StageBackground"
	background_sprite.texture = tex
	background_sprite.centered = true
	background_sprite.z_index = -50
	background_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var tex_size := tex.get_size()
	var s: float = BG_HEIGHT / maxf(tex_size.y, 1.0)
	background_sprite.scale = Vector2(s, s)
	# Kaki petarung (FLOOR_Y) berada di floor_ratio dari tinggi gambar.
	var top_y: float = FLOOR_Y - floor_ratio * BG_HEIGHT
	background_sprite.position = Vector2(CENTER_X, top_y + BG_HEIGHT * 0.5)
	add_child(background_sprite)
	move_child(background_sprite, 0)

	ambience = StageAmbience.new()
	ambience.name = "StageAmbience"
	ambience.z_index = -40
	add_child(ambience)
	ambience.position = Vector2(CENTER_X, CAMERA_Y)
	ambience.setup(info.get("ambience", &"none"), info.get("accent", Color.WHITE))

func _process(_delta: float) -> void:
	if camera == null:
		return
	var cam_x: float = camera.global_position.x
	if background_sprite:
		background_sprite.position.x = CENTER_X + (cam_x - CENTER_X) * PARALLAX
	if ambience:
		ambience.position = Vector2(cam_x, camera.global_position.y)
	if _track_retries > 0 and camera.has_method("track_fighters"):
		_track_retries -= 1
		_find_fighters_in_tree()
		var duelists := _get_duelists()
		if duelists.size() >= 2:
			camera.track_fighters(duelists[0], duelists[1])
			_track_retries = 0

func _get_duelists() -> Array[Node2D]:
	var out: Array[Node2D] = []
	var parent_node := get_parent()
	if parent_node:
		var container := parent_node.get_node_or_null("Fighters")
		if container:
			for child in container.get_children():
				if child is CharacterBody2D and out.size() < 2:
					out.append(child)
	return out

func get_spawn_points() -> Array[Vector2]:
	return [spawn_p1, spawn_p2]

func register_fighter(fighter: Node2D) -> void:
	if fighter and fighter not in registered_fighters:
		registered_fighters.append(fighter)

func unregister_fighter(fighter: Node2D) -> void:
	registered_fighters.erase(fighter)

func _find_fighters_in_tree() -> void:
	for f in _get_duelists():
		register_fighter(f)

func is_within_platform(x_pos: float) -> bool:
	return x_pos >= left_bound and x_pos <= right_bound

func get_platform_top_y() -> float:
	if platform_body:
		return platform_body.global_position.y - 12.0
	return 288.0
