class_name FighterFactory
extends RefCounted

## Fighter Factory & Roster Registry
## Menyediakan metadata karakter anime crossover terpusat dan pembuat instance siap tarung
## Mendukung: Miku Hatsune, Reimu Hakurei, Marisa Kirisame, Remilia Scarlet, Sasuke Uchiha, 2B, Death Kam

const MikuHatsuneScript = preload("res://scripts/characters/miku_hatsune.gd")
const ReimuHakureiScript = preload("res://scripts/characters/reimu_hakurei.gd")
const MarisaKirisameScript = preload("res://scripts/characters/marisa_kirisame.gd")
const RemiliaScarletScript = preload("res://scripts/characters/remilia_scarlet.gd")
const SasukeUchihaScript = preload("res://scripts/characters/sasuke_uchiha.gd")
const Yorha2BScript = preload("res://scripts/characters/yorha_2b.gd")
const DeathKamScript = preload("res://scripts/characters/death_kam.gd")

# Backward Compatibility Scripts
const ApexViperScript = preload("res://scripts/characters/apex_viper.gd")
const TitanBulwarkScript = preload("res://scripts/characters/titan_bulwark.gd")
const RayPulsarScript = preload("res://scripts/characters/ray_pulsar.gd")
const PhantomKageScript = preload("res://scripts/characters/phantom_kage.gd")
const KuroganeTriggerScript = preload("res://scripts/characters/kurogane_trigger.gd")
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
		"id": &"miku",
		"name": "Miku Hatsune",
		"archetype": "Vocaloid / Idol",
		"quote": "Let's fight!",
		"hp": 880,
		"walk_speed": 350.0,
		"dash_speed": 820.0,
		"speed_grade": "A+",
		"defense_grade": "C",
		"range_grade": "B",
		"complexity": "Medium",
		"hp_bar": 4,
		"spd_bar": 9,
		"def_bar": 4,
		"rng_bar": 6,
		"theme_color": Color(0.0, 0.9, 0.95, 1.0), # Neon Cyan
		"description": "High-velocity rhythmic idol duelist equipped with digital sound pulse combos, 380px Rhythm Dash, and World is Mine protocol.",
		"signature_moves": [
			"[J / Z] Normal Attack: Vocaloid Mic Pulse & Sound Slash Combo",
			"[U] Skill 1: Rhythm Dash (Sonic Twintail Slice)",
			"[I] Skill 2: Frequency Barrier (Holographic Sound Wall)",
			"[O] Ultimate: World is Mine (Disruptive Pop Supernova)",
			"[L] Spark Parry | [X / Shift] Beat Thruster Dash"
		]
	},
	{
		"id": &"reimu",
		"name": "Reimu Hakurei",
		"archetype": "Shrine Maiden",
		"quote": "This is a divine will.",
		"hp": 950,
		"walk_speed": 320.0,
		"dash_speed": 760.0,
		"speed_grade": "B+",
		"defense_grade": "B",
		"range_grade": "A",
		"complexity": "High",
		"hp_bar": 6,
		"spd_bar": 6,
		"def_bar": 5,
		"rng_bar": 8,
		"theme_color": Color(0.95, 0.15, 0.25, 1.0), # Crimson Red
		"description": "Divine shrine maiden mastering paper ofuda talismans, dimensional rift evasions, and Yin-Yang Orb cataclysmic seals.",
		"signature_moves": [
			"[J / Z] Normal Attack: Gohei Wand Purification Strike Combo",
			"[U] Skill 1: Homing Amulet (Tracking Ofuda Charm Barrage)",
			"[I] Skill 2: Dimensional Rift (Spatial Evasion Blink)",
			"[O] Ultimate: Fantasy Seal (Yin-Yang Orb Cataclysm)",
			"[L] Spark Parry | [X / Shift] Shrine Maiden Glide"
		]
	},
	{
		"id": &"marisa",
		"name": "Marisa Kirisame",
		"archetype": "Wizard",
		"quote": "Hehe~ Let's go!",
		"hp": 900,
		"walk_speed": 330.0,
		"dash_speed": 780.0,
		"speed_grade": "A",
		"defense_grade": "D",
		"range_grade": "S+",
		"complexity": "High",
		"hp_bar": 5,
		"spd_bar": 7,
		"def_bar": 3,
		"rng_bar": 10,
		"theme_color": Color(1.0, 0.85, 0.25, 1.0), # Golden Amber
		"description": "High-powered ordinary magician riding a flying broom, unleashing Mini-Hakkero star sparks and the screen-filling Final Master Spark.",
		"signature_moves": [
			"[J / Z] Normal Attack: Mini-Hakkero Star Spark Combo",
			"[U] Skill 1: Witch Leyline Dash (Broom Flight Rush)",
			"[I] Skill 2: Starlight Typhoon (Orbiting Star Clusters)",
			"[O] Ultimate: Final Master Spark (Giant Laser Cannon)",
			"[L] Spark Parry | [X / Shift] Broom Astral Dash"
		]
	},
	{
		"id": &"remilia",
		"name": "Remilia Scarlet",
		"archetype": "Vampire",
		"quote": "All shall be mine...",
		"hp": 1050,
		"walk_speed": 340.0,
		"dash_speed": 800.0,
		"speed_grade": "A",
		"defense_grade": "B+",
		"range_grade": "C",
		"complexity": "Medium",
		"hp_bar": 7,
		"spd_bar": 8,
		"def_bar": 6,
		"rng_bar": 5,
		"theme_color": Color(0.85, 0.25, 0.85, 1.0), # Vampire Scarlet Violet
		"description": "Ancient vampire aristocrat wielding blood claws, bat wing aerial dives, and the unyielding crimson Spear of Gungnir.",
		"signature_moves": [
			"[J / Z] Normal Attack: Vampire Blood Claw & Wing Buffet Combo",
			"[U] Skill 1: Demon King Cradle (Aerial Bat Dive Grab)",
			"[I] Skill 2: Scarlet Nether Mist (Blood Shield & Counter)",
			"[O] Ultimate: Spear the Gungnir (Cosmic Red Piercing Spear)",
			"[L] Spark Parry | [X / Shift] Vampire Bat Warp Dash"
		]
	},
	{
		"id": &"sasuke",
		"name": "Sasuke Uchiha",
		"archetype": "Ninja",
		"quote": "...This is my path.",
		"hp": 940,
		"walk_speed": 340.0,
		"dash_speed": 810.0,
		"speed_grade": "A+",
		"defense_grade": "B",
		"range_grade": "A",
		"complexity": "High",
		"hp_bar": 6,
		"spd_bar": 8,
		"def_bar": 5,
		"rng_bar": 7,
		"theme_color": Color(0.55, 0.40, 1.0, 1.0), # Electric Purple / Indigo
		"description": "Avenger ninja mastering swift Kusanagi kenjutsu, piercing Chidori lightning strikes, and destructive Kirin dragon lightning.",
		"signature_moves": [
			"[J / Z] Normal Attack: Kusanagi Blade Kenjutsu Combo",
			"[U] Skill 1: Chidori Current (Lightning Piercing Thrust)",
			"[I] Skill 2: Fire Style: Fireball Jutsu (Inferno Burst)",
			"[O] Ultimate: Kirin Dragon / Susanoo (Sky-Splitting Lightning)",
			"[L] Spark Parry | [X / Shift] Shunshin Lightning Dash"
		]
	},
	{
		"id": &"2b",
		"name": "2B",
		"archetype": "YoRHa (Android)",
		"quote": "...I will protect you.",
		"hp": 1000,
		"walk_speed": 330.0,
		"dash_speed": 790.0,
		"speed_grade": "A",
		"defense_grade": "A",
		"range_grade": "B",
		"complexity": "Medium",
		"hp_bar": 8,
		"spd_bar": 7,
		"def_bar": 7,
		"rng_bar": 6,
		"theme_color": Color(0.92, 0.94, 0.98, 1.0), # Monochrome Silver
		"description": "YoRHa battle android wielding Virtuous Contract twin katanas, Pod 042 laser support, and lethal Perfect Evade counterattacks.",
		"signature_moves": [
			"[J / Z] Normal Attack: Virtuous Contract Katana Dance Combo",
			"[U] Skill 1: Pod 042 Laser Program (Forward Beam Burst)",
			"[I] Skill 2: Perfect Evade & Mirage Counter",
			"[O] Ultimate: Pod Program: Gravity Hammer & Self-Destruct Rupture",
			"[L] Spark Parry | [X / Shift] Android Glide Dash"
		]
	},
	{
		"id": &"death_kam",
		"name": "Death Kam",
		"archetype": "White Mane Reaper / Pull & Rage Brawler",
		"quote": "Death doesn't chase. It pulls.",
		"hp": 960,
		"walk_speed": 330.0,
		"dash_speed": 790.0,
		"speed_grade": "A",
		"defense_grade": "B",
		"range_grade": "C",
		"complexity": "Medium",
		"hp_bar": 6,
		"spd_bar": 7,
		"def_bar": 5,
		"rng_bar": 4,
		"theme_color": Color(0.93, 0.93, 1.0, 1.0), # Pale Silver-White (Manenya)
		"description": "White-haired reaper who drags his victims in with gaib chain grapples, then answers with rage-fueled haymakers wrapped in ember energy.",
		"signature_moves": [
			"[J / Z] Normal Light: Death Pull Punch (Gaib Chain Yank & Haymaker)",
			"[K] Normal Heavy: Death Kam Rage (Armored Ember Fist, Chip Damage & Wall Bounce)",
			"[U] Skill 1: Grave Chain (Long-Range Anti-Block Pull Grab)",
			"[I] Skill 2: Death's Resolve (40F Full Super Armor)",
			"[O] Ultimate: Final Requiem (Cataclysmic Crimson Nova)",
			"[L] Spark Parry | [X / Shift] Reaper Dash"
		]
	}
]

static func get_character_info(char_id: StringName) -> Dictionary:
	match char_id:
		&"viper":
			return {
				"id": &"viper",
				"name": "Apex-0 \"Viper\"",
				"archetype": "Rushdown / High-Speed Striker",
				"hp": 900,
				"speed_grade": "A+",
				"defense_grade": "C",
				"range_grade": "C",
				"theme_color": Color(0.2, 0.9, 1.0, 1.0),
				"signature_moves": ["Rapier 3-Hit", "Blink Slash", "Deflection Matrix", "Absolute Zero Protocol"]
			}
		&"bulwark":
			return {
				"id": &"bulwark",
				"name": "Titan-V \"Bulwark\"",
				"archetype": "Heavy Grappler / Iron Juggernaut",
				"hp": 1200,
				"speed_grade": "C",
				"defense_grade": "S+",
				"range_grade": "D",
				"theme_color": Color(0.95, 0.45, 0.15, 1.0),
				"signature_moves": ["Iron Hammer Strike", "Hydraulic Piledriver", "Riot Shield Deploy", "Orbital Siege Cannon"]
			}
		&"pulsar":
			return {
				"id": &"pulsar",
				"name": "Ray-X \"Pulsar\"",
				"archetype": "Long-Range Zoner / Spatial Trapper",
				"hp": 950,
				"speed_grade": "B",
				"defense_grade": "B",
				"range_grade": "S+",
				"theme_color": Color(0.7, 0.3, 1.0, 1.0),
				"signature_moves": ["Plasma Pulse", "Photon Railgun", "Disrupter Drone", "Supernova Horizon"]
			}

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
		&"miku":
			fighter = MikuHatsuneScript.new()
			fighter.name = "Miku_P%d" % player_idx
		&"reimu":
			fighter = ReimuHakureiScript.new()
			fighter.name = "Reimu_P%d" % player_idx
		&"marisa":
			fighter = MarisaKirisameScript.new()
			fighter.name = "Marisa_P%d" % player_idx
		&"remilia":
			fighter = RemiliaScarletScript.new()
			fighter.name = "Remilia_P%d" % player_idx
		&"sasuke":
			fighter = SasukeUchihaScript.new()
			fighter.name = "Sasuke_P%d" % player_idx
		&"2b":
			fighter = Yorha2BScript.new()
			fighter.name = "Yorha2B_P%d" % player_idx
		&"death_kam":
			fighter = DeathKamScript.new()
			fighter.name = "DeathKam_P%d" % player_idx
		&"bulwark":
			fighter = TitanBulwarkScript.new()
			fighter.name = "Bulwark_P%d" % player_idx
		&"pulsar":
			fighter = RayPulsarScript.new()
			fighter.name = "Pulsar_P%d" % player_idx
		&"kage":
			fighter = PhantomKageScript.new()
			fighter.name = "Kage_P%d" % player_idx
		&"trigger":
			fighter = KuroganeTriggerScript.new()
			fighter.name = "Trigger_P%d" % player_idx
		&"unit_zero":
			fighter = BossUnitZeroScript.new()
			fighter.name = "UnitZero_P%d" % player_idx
		&"viper", _:
			fighter = ApexViperScript.new()
			fighter.name = "Viper_P%d" % player_idx

	fighter.set("player_index", player_idx)
	fighter.collision_layer = 1
	fighter.collision_mask = 1

	if not fighter.has_node("CollisionShape2D"):
		var col := CollisionShape2D.new()
		col.name = "CollisionShape2D"
		var rect := RectangleShape2D.new()
		rect.size = Vector2(24, 38)
		col.shape = rect
		fighter.add_child(col)

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
