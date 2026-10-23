extends Node

const MechaPixelSpriteScript = preload("res://scripts/visual/mecha_pixel_sprite.gd")
const MechaVisualControllerScript = preload("res://scripts/visual/mecha_visual_controller.gd")
const ApexViperScript = preload("res://scripts/characters/apex_viper.gd")
const TitanBulwarkScript = preload("res://scripts/characters/titan_bulwark.gd")
const CombatConstants = preload("res://scripts/combat/combat_constants.gd")

var log_file: FileAccess = null
var _failed: bool = false

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		_log("   [FAIL] " + msg)

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_pixel_sprites_visual_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Story 7.1: 32-Bit Pixel Mecha Sprites & Visuals...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_mecha_pixel_sprite_initialization_and_archetypes,
		_test_base_mecha_visual_auto_setup,
		_test_state_driven_animation_and_poses,
		_test_collision_matrix_preservation,
		_test_mecha_visual_controller_wrapper
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			passed += 1
			_log(" [LULUS]")

	_log("\n==================================================")
	_log("HASIL: %d/%d pengujian lulus." % [passed, tests.size()])
	_log("==================================================")

	if log_file:
		log_file.close()

	if passed == tests.size():
		get_tree().quit(0)
	else:
		get_tree().quit(1)

func _test_mecha_pixel_sprite_initialization_and_archetypes() -> void:
	var spr_viper = MechaPixelSpriteScript.new()
	spr_viper.archetype = &"viper"
	spr_viper._apply_archetype_palette()
	_check(spr_viper.col_armor.g > 0.8, "Viper col_armor harus dominan cyan cerah")
	_check(spr_viper.col_visor.r > 0.8 and spr_viper.col_visor.b > 0.9, "Viper visor harus cyan/putih")
	spr_viper.free()

	var spr_bulwark = MechaPixelSpriteScript.new()
	spr_bulwark.archetype = &"bulwark"
	spr_bulwark._apply_archetype_palette()
	_check(spr_bulwark.col_armor.r > 0.9 and spr_bulwark.col_armor.g < 0.7, "Bulwark col_armor harus oranye industrial")
	_check(spr_bulwark.col_visor.r > 0.9 and spr_bulwark.col_visor.g < 0.4, "Bulwark visor harus sensor optik merah")
	spr_bulwark.free()

func _test_base_mecha_visual_auto_setup() -> void:
	var viper = ApexViperScript.new()
	add_child(viper)
	viper._ready()

	_check(viper.visual_root != null, "ApexViper harus memiliki visual_root")
	_check(viper.visual_root.has_node("Sprite"), "visual_root harus memiliki node 'Sprite'")
	var spr = viper.visual_root.get_node("Sprite")
	_check(spr is MechaPixelSpriteScript, "Sprite harus berinstansiasi MechaPixelSprite")
	_check(spr.archetype == &"viper", "Sprite archetype untuk ApexViper harus 'viper'")
	
	viper.queue_free()

	var bulwark = TitanBulwarkScript.new()
	add_child(bulwark)
	bulwark._ready()

	_check(bulwark.visual_root != null, "TitanBulwark harus memiliki visual_root")
	_check(bulwark.visual_root.has_node("Sprite"), "visual_root harus memiliki node 'Sprite'")
	var b_spr = bulwark.visual_root.get_node("Sprite")
	_check(b_spr is MechaPixelSpriteScript, "Sprite Bulwark harus berinstansiasi MechaPixelSprite")
	_check(b_spr.archetype == &"bulwark", "Sprite archetype untuk TitanBulwark harus 'bulwark'")

	bulwark.queue_free()

func _test_state_driven_animation_and_poses() -> void:
	var spr = MechaPixelSpriteScript.new()
	add_child(spr)
	
	spr.set_current_state(&"Walk")
	_check(spr.current_state == &"Walk", "State harus berubah ke Walk")

	spr.set_current_state(&"Cliffhanger")
	_check(spr.current_state == &"Cliffhanger", "State harus berubah ke Cliffhanger")

	spr.trigger_hit_flash(5)
	_check(spr.hit_flash_frames == 5, "hit_flash_frames harus terisi 5 frame")

	spr._physics_process(1.0 / 60.0)
	_check(spr.hit_flash_frames == 4, "hit_flash_frames harus berkurang 1 per frame")

	spr.queue_free()

func _test_collision_matrix_preservation() -> void:
	var viper = ApexViperScript.new()
	add_child(viper)
	viper._ready()

	_check(viper.collision_layer == 1, "Layer fisik mecha harus tetap Layer 1 (World)")
	_check(viper.collision_mask == 1, "Mask fisik mecha harus tetap Layer 1 (World)")

	_check(viper.hurtbox != null, "Hurtbox harus terpasang")
	_check(viper.hurtbox.collision_layer == (1 << (CombatConstants.LAYER_HURTBOX - 1)), "Hurtbox harus di Layer 2")

	_check(viper.hitbox != null, "Hitbox harus terpasang")
	_check(viper.hitbox.collision_layer == (1 << (CombatConstants.LAYER_STRIKE_HITBOX - 1)), "Hitbox harus di Layer 3")

	var shape_node = viper.get_node_or_null("CollisionShape2D")
	_check(shape_node != null, "CollisionShape2D harus ada")
	if shape_node and shape_node.shape is RectangleShape2D:
		var rect: RectangleShape2D = shape_node.shape as RectangleShape2D
		_check(rect.size.x == 24 and rect.size.y == 38, "Ukuran collision box harus tepat 24x38 px")

	viper.queue_free()

func _test_mecha_visual_controller_wrapper() -> void:
	var ctrl = MechaVisualControllerScript.new()
	ctrl.archetype = &"viper"
	add_child(ctrl)
	ctrl._ready()

	_check(ctrl.pixel_sprite != null, "MechaVisualController harus menginisialisasi pixel_sprite")
	_check(ctrl.pixel_sprite.archetype == &"viper", "Archetype awal harus viper")

	ctrl.set_archetype(&"bulwark")
	_check(ctrl.pixel_sprite.archetype == &"bulwark", "Archetype setelah update harus bulwark")

	ctrl.trigger_hit_flash(6)
	_check(ctrl.pixel_sprite.hit_flash_frames == 6, "Hit flash via controller harus tersalurkan ke pixel_sprite")

	ctrl.queue_free()
