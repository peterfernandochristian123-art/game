class_name MechaVisualController
extends Node2D

## Visual Controller untuk Mecha Tempur (Story 7.1)
## Mengatur MechaPixelSprite, sinkronisasi FSM, hit flash, dan kompatibilitas visual root

const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")

@export var archetype: StringName = &"viper"

var pixel_sprite: Node2D = null
var parent_mecha: CharacterBody2D = null

func _ready() -> void:
	_setup_sprite_node()
	_bind_parent()

func _setup_sprite_node() -> void:
	# Cek apakah sudah ada Sprite anak
	if has_node("Sprite"):
		var existing = get_node("Sprite")
		if existing.get_script() == MechaPixelSpriteScript:
			pixel_sprite = existing
		else:
			# Jika ada ColorRect placeholder, gantikan dengan MechaPixelSprite
			var rect_pos = existing.position if "position" in existing else Vector2.ZERO
			existing.queue_free()
			pixel_sprite = MechaPixelSpriteScript.new()
			pixel_sprite.name = "Sprite"
			pixel_sprite.archetype = archetype
			pixel_sprite.position = rect_pos
			add_child(pixel_sprite)
	else:
		pixel_sprite = MechaPixelSpriteScript.new()
		pixel_sprite.name = "Sprite"
		pixel_sprite.archetype = archetype
		add_child(pixel_sprite)

func _bind_parent() -> void:
	if get_parent() is CharacterBody2D:
		parent_mecha = get_parent() as CharacterBody2D
	elif get_parent() and get_parent().get_parent() is CharacterBody2D:
		parent_mecha = get_parent().get_parent() as CharacterBody2D

	if parent_mecha and pixel_sprite:
		if parent_mecha.has_signal("hp_changed"):
			parent_mecha.hp_changed.connect(_on_hp_changed)

func _on_hp_changed(_curr: int, _max_val: int) -> void:
	# Flash saat menerima damage / HP berkurang
	if pixel_sprite:
		pixel_sprite.trigger_hit_flash(3)

func trigger_hit_flash(frames: int = 4) -> void:
	if pixel_sprite:
		pixel_sprite.trigger_hit_flash(frames)

func set_archetype(arch: StringName) -> void:
	archetype = arch
	if pixel_sprite:
		pixel_sprite.archetype = arch
		pixel_sprite._apply_archetype_palette()
		pixel_sprite.queue_redraw()
