class_name FighterFactory
extends RefCounted

## Fighter Factory & Roster Registry (Story 11.1)
## Menyediakan metadata karakter terpusat dan pembuat instance mecha siap tarung
## Mendukung Apex-0 Viper, Titan-V Bulwark, dan Ray-X Pulsar

const ApexViperScript = preload("res://scripts/characters/apex_viper.gd")
const TitanBulwarkScript = preload("res://scripts/characters/titan_bulwark.gd")
const RayPulsarScript = preload("res://scripts/characters/ray_pulsar.gd")
const PhantomKageScript = preload("res://scripts/characters/phantom_kage.gd")
const BossUnitZeroScript = preload("res://scripts/characters/boss_unit_zero.gd")

const StateMachineScript = preload("res://scripts/combat/fsm/state_machine.gd")
const IdleStateScript = preload("res://scripts/combat/fsm/idle_state.gd")
const WalkStateScript = preload("res://scripts/combat/fsm/walk_state.gd")
const JumpStateScript = preload("res://scripts/combat/fsm/jump_state.gd")
const FallStateScript = preload("res://scripts/combat/fsm/fall_state.gd")
const DashStateScript = preload("res://scripts/combat/fsm/dash_state.gd")
const AirDashStateScript = preload("res://scripts/combat/fsm/air_dash_state.gd")
const AttackStateScript = preload("res://scripts/combat/fsm/attack_state.gd")
const HitstunStateScript = preload("res://scripts/combat/fsm/hitstun_state.gd")

const ROSTER: Array[Dictionary] = [
	{
		"id": &"viper",
		"name": "Apex-0 \"Viper\"",
		"archetype": "Rushdown / High-Speed Striker",
		"hp": 900,
		"walk_speed": 350.0,
		"dash_speed": 820.0,
		"speed_grade": "A+",
		"defense_grade": "C",
		"range_grade": "C",
		"complexity": "Medium",
		"theme_color": Color(0.2, 0.9, 1.0, 1.0), # Cyan
		"description": "High-velocity duelist equipped with dual beam rapiers, 400px Blink Slash teleport, and Absolute Zero heat lock.",
		"signature_moves": [
			"5L / 5H: Beam Rapier 3-Hit Combo",
			"Skill 1: Blink Slash (400px Teleport Cut)",
			"Skill 2: Deflection Matrix (Shield)",
			"Ultimate: Absolute Zero Protocol (Heat Lock)"
		]
	},
	{
		"id": &"bulwark",
		"name": "Titan-V \"Bulwark\"",
		"archetype": "Heavy Grappler / Iron Juggernaut",
		"hp": 1200,
		"walk_speed": 260.0,
		"dash_speed": 650.0,
		"speed_grade": "C",
		"defense_grade": "S+",
		"range_grade": "D",
		"complexity": "High",
		"theme_color": Color(0.95, 0.45, 0.15, 1.0), # Industrial Orange
		"description": "Armored colossus with passive -5% damage reduction, unblockable Hydraulic Piledriver command grab, and Riot Shield.",
		"signature_moves": [
			"5L / 5H: Heavy Iron Hammer Strike",
			"Skill 1: Hydraulic Piledriver (Command Grab)",
			"Skill 2: Riot Shield Deploy (Super Armor)",
			"Ultimate: Orbital Siege Cannon (450 Dmg)"
		]
	},
	{
		"id": &"pulsar",
		"name": "Ray-X \"Pulsar\"",
		"archetype": "Long-Range Zoner / Spatial Trapper",
		"hp": 950,
		"walk_speed": 300.0,
		"dash_speed": 720.0,
		"speed_grade": "B",
		"defense_grade": "B",
		"range_grade": "S+",
		"complexity": "High",
		"theme_color": Color(0.7, 0.3, 1.0, 1.0), # Neon Violet
		"description": "Spatial control specialist wielding high-caliber photon railguns, floating disrupter drone pods, and 360° supernova.",
		"signature_moves": [
			"5L / 5H: Plasma Pulse & Beam Lance",
			"Skill 1: Photon Railgun (Linear Beam 110 Dmg)",
			"Skill 2: Disrupter Drone (120f Area Denial)",
			"Ultimate: Supernova Horizon (360° Shockwave)"
		]
	},
	{
		"id": &"kage",
		"name": "Phantom-9 \"Kage\"",
		"archetype": "Stance Switcher / Shadow Shinobi",
		"hp": 920,
		"walk_speed": 320.0,
		"dash_speed": 780.0,
		"speed_grade": "S",
		"defense_grade": "B",
		"range_grade": "A",
		"complexity": "Very High",
		"theme_color": Color(0.95, 0.15, 0.25, 1.0), # Crimson Red
		"description": "Shadow assassin mastering dual combat stances: close-quarters Kenjutsu Katana and ranged Shinobi Shurikens with evasive feints.",
		"signature_moves": [
			"5L / 5H: Katana Slash (Kenjutsu) / Kunai Poke (Shinobi)",
			"Skill 1: Stance Shift & Shadow Feint (Dual Stance Swap)",
			"Skill 2: Iaido Crescent (Kenjutsu) / Shuriken Storm (Shinobi)",
			"Ultimate: Tsukuyomi Shadow Blossom (420 Dmg Full Screen)"
		]
	}
]

static func get_character_info(char_id: StringName) -> Dictionary:
	for entry in ROSTER:
		if entry["id"] == char_id:
			return entry
	return ROSTER[0]

static func get_roster_count() -> int:
	return ROSTER.size()

static func get_character_at(index: int) -> Dictionary:
	if index >= 0 and index < ROSTER.size():
		return ROSTER[index]
	return ROSTER[0]

static func create_fighter(char_id: StringName, player_idx: int = 1) -> CharacterBody2D:
	var fighter: CharacterBody2D = null
	match char_id:
		&"bulwark":
			fighter = TitanBulwarkScript.new()
			fighter.name = "Bulwark_P%d" % player_idx
		&"pulsar":
			fighter = RayPulsarScript.new()
			fighter.name = "Pulsar_P%d" % player_idx
		&"kage":
			fighter = PhantomKageScript.new()
			fighter.name = "Kage_P%d" % player_idx
		&"unit_zero":
			fighter = BossUnitZeroScript.new()
			fighter.name = "UnitZero_P%d" % player_idx
		&"viper", _:
			fighter = ApexViperScript.new()
			fighter.name = "Viper_P%d" % player_idx

	fighter.set("player_index", player_idx)
	fighter.collision_layer = 1
	fighter.collision_mask = 1

	# Collision Shape standard jika belum ada
	if not fighter.has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(24, 38)
		col.shape = rect
		fighter.add_child(col)

	# Setup State Machine terstandarisasi
	var fsm = fighter.get_node_or_null("StateMachine")
	if not fsm:
		fsm = StateMachineScript.new()
		fsm.name = "StateMachine"
		fighter.add_child(fsm)

		var idle = IdleStateScript.new()
		idle.name = "Idle"
		fsm.add_child(idle)

		var walk = WalkStateScript.new()
		walk.name = "Walk"
		fsm.add_child(walk)

		var jump = JumpStateScript.new()
		jump.name = "Jump"
		fsm.add_child(jump)

		var fall = FallStateScript.new()
		fall.name = "Fall"
		fsm.add_child(fall)

		var dash = DashStateScript.new()
		dash.name = "Dash"
		fsm.add_child(dash)

		var airdash = AirDashStateScript.new()
		airdash.name = "AirDash"
		fsm.add_child(airdash)

		var attack = AttackStateScript.new()
		attack.name = "Attack"
		fsm.add_child(attack)

		var hitstun = HitstunStateScript.new()
		hitstun.name = "Hitstun"
		fsm.add_child(hitstun)

	return fighter
