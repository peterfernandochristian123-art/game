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

var registered_fighters: Array[Node2D] = []
var background_sprite: Sprite2D = null
var ambience: StageAmbience = null
var _track_retries: int = 120

func _ready() -> void:
	if stage_id == &"":
		stage_id = MatchConfig.selected_stage
	if not StageManager.has_stage(stage_id):
		stage_id = StageManager.DEFAULT_STAGE
	_setup_background()
	_setup_camera()
	_setup_audio()
	_find_fighters_in_tree()

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
