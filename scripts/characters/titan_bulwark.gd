class_name TitanBulwark
extends BaseMecha

## Petarung Mecha: Titan-V "Bulwark" (Story 3.3)
## Archetype: Heavy Grappler / Space Control
## Kecepatan Jalan: 260 px/s, Dash: 650 px/s (16 frame)
## Total HP: 1200, Reduksi Pasif Kerusakan: 5% (Lapis baja tebal)

func _init() -> void:
	max_hp = CombatConstants.BULWARK_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.BULWARK_WALK_SPEED
	passive_damage_reduction = CombatConstants.BULWARK_PASSIVE_ARMOR_REDUCTION

func _ready() -> void:
	max_hp = CombatConstants.BULWARK_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.BULWARK_WALK_SPEED
	passive_damage_reduction = CombatConstants.BULWARK_PASSIVE_ARMOR_REDUCTION

	attack_resources = {
		&"5L": preload("res://resources/attacks/bulwark_punch.tres"),
		&"Punch": preload("res://resources/attacks/bulwark_punch.tres"),
		&"5H": preload("res://resources/attacks/bulwark_slam.tres"),
		&"Slam": preload("res://resources/attacks/bulwark_slam.tres"),
		&"Skill1": preload("res://resources/attacks/bulwark_piledriver.tres"),
		&"HydraulicPiledriver": preload("res://resources/attacks/bulwark_piledriver.tres"),
		&"Piledriver": preload("res://resources/attacks/bulwark_piledriver.tres"),
		&"Skill2": preload("res://resources/attacks/bulwark_riot_shield.tres"),
		&"RiotShield": preload("res://resources/attacks/bulwark_riot_shield.tres"),
		&"Ultimate": preload("res://resources/attacks/bulwark_orbital_cannon.tres"),
		&"OrbitalSiegeCannon": preload("res://resources/attacks/bulwark_orbital_cannon.tres")
	}

	super._ready()

	# Warna visual khas Bulwark: Heavy Bronze / Dark Industrial Armor
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.85, 0.55, 0.25, 1.0)

	if OS.is_debug_build():
		print("[CHARACTER][TitanBulwark] Titan-V Bulwark diinisialisasi. HP: %d, Armor: -%.0f%%, Jalan: %.1f px/s, Dash: %.1f px/s." % [
			max_hp, passive_damage_reduction * 100.0, walk_speed, get_dash_speed()
		])

## Kecepatan dash khusus Titan-V Bulwark (650 px/s)
func get_dash_speed() -> float:
	return CombatConstants.BULWARK_DASH_SPEED

## Durasi dash khusus Bulwark: 16 frame
func get_dash_duration() -> int:
	return CombatConstants.BULWARK_DASH_DURATION_FRAMES

## Skill 1: Hydraulic Piledriver
## Command grab jarak dekat (Startup 6f, mengabaikan block biasa, membanting musuh dengan 220 damage, +35% Heat)
func execute_hydraulic_piledriver(target_opponent: Node2D = null) -> void:
	if target_opponent and target_opponent.global_position.distance_to(global_position) < 120.0:
		# Jika lawan dalam jarak cengkeram, tarik sedikit mendekat ke posisi bantingan mecha
		var grab_pos_x: float = global_position.x + (40.0 * float(facing_direction))
		target_opponent.global_position.x = grab_pos_x

	request_attack_by_name(&"HydraulicPiledriver")

## Skill 2: Riot Shield Deploy
## Menancapkan perisai baja ke lantai. Memberikan status Full Super Armor selama 45 frame terhadap serangan non-grab (+15% Heat)
func execute_riot_shield_deploy() -> void:
	super_armor_frames = CombatConstants.BULWARK_RIOT_SHIELD_DURATION_FRAMES
	velocity.x = 0.0
	request_attack_by_name(&"RiotShield")

	if OS.is_debug_build():
		print("[CHARACTER][TitanBulwark] Riot Shield Deploy aktif! Full Super Armor selama %d frame." % super_armor_frames)

## Ultimate: Orbital Siege Cannon
## Meriam laser partikel vertikal-diagonal layar penuh berdamage 450 HP (Startup 24f)
func activate_orbital_siege_cannon() -> bool:
	if current_ultimate < CombatConstants.MAX_ULTIMATE:
		return false

	drain_ultimate(CombatConstants.MAX_ULTIMATE)
	velocity.x = 0.0
	request_attack_by_name(&"OrbitalSiegeCannon")

	if OS.is_debug_build():
		print("[ULTIMATE][%s] ORBITAL SIEGE CANNON MENYALA! Meriam partikel 450 HP!" % name)
	return true

func _update_hud() -> void:
	super._update_hud()
	var status_label := get_node_or_null("../UI/HUD/StatusLabel") as Label
	if status_label and has_super_armor():
		status_label.text += " [RIOT SHIELD SUPER ARMOR!]"
