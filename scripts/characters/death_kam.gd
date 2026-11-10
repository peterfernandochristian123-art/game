class_name DeathKam
extends BaseMecha

## Petarung: Death Kam - "White Mane Reaper" (Pria Berambut Putih)
## Archetype: Chain Pull Grappler / Rage Brawler
## Kecepatan Jalan: 330 px/s, Dash: 790 px/s (13 frame)
## Total HP: 960, Mekanik: Death Pull Punch (5L), Death Kam Rage (5H),
## Grave Chain (Skill 1 — tarik gaib anti-block), Death's Resolve (Skill 2 — super armor),
## Final Requiem (Ultimate)

signal pull_executed(target: Node2D)
signal rage_activated()
signal grave_chain_executed(target: Node2D)
signal death_resolve_activated()
signal final_requiem_executed()

const PULL_MIN_RANGE: float = CombatConstants.DEATH_KAM_PULL_MIN_RANGE
const PULL_RANGE: float = CombatConstants.DEATH_KAM_PULL_RANGE
const GRAVE_CHAIN_MIN_RANGE: float = CombatConstants.DEATH_KAM_GRAVE_CHAIN_MIN_RANGE
const GRAVE_CHAIN_RANGE: float = CombatConstants.DEATH_KAM_GRAVE_CHAIN_RANGE
const PULL_CLOSE_DISTANCE: float = CombatConstants.DEATH_KAM_PULL_CLOSE_DISTANCE
const RAGE_ARMOR_FRAMES: int = CombatConstants.DEATH_KAM_RAGE_ARMOR_FRAMES
const RESOLVE_ARMOR_FRAMES: int = CombatConstants.DEATH_KAM_RESOLVE_ARMOR_FRAMES

## State visual tarikan tangan (agar animasi tangan terlihat menjulur/menarik)
var is_pulling_target: bool = false
var pull_visual_frames: int = 0
var pull_visual_max_frames: int = 12
var pull_visual_reach: float = 0.0

var _res_pull_punch = preload("res://resources/attacks/death_kam_pull_punch.tres")
var _res_rage = preload("res://resources/attacks/death_kam_rage.tres")
var _res_grave_chain = preload("res://resources/attacks/death_kam_grave_chain.tres")
var _res_resolve = preload("res://resources/attacks/death_kam_resolve.tres")
var _res_requiem = preload("res://resources/attacks/death_kam_final_requiem.tres")

func _init() -> void:
	max_hp = CombatConstants.DEATH_KAM_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.DEATH_KAM_WALK_SPEED

func _ready() -> void:
	max_hp = CombatConstants.DEATH_KAM_MAX_HP
	current_hp = max_hp
	walk_speed = CombatConstants.DEATH_KAM_WALK_SPEED

	attack_resources = {
		&"5L": _res_pull_punch,
		&"DeathKamPullPunch": _res_pull_punch,
		&"5H": _res_rage,
		&"DeathKamRage": _res_rage,
		&"Skill1": _res_grave_chain,
		&"GraveChain": _res_grave_chain,
		&"Skill2": _res_resolve,
		&"DeathsResolve": _res_resolve,
		&"Ultimate": _res_requiem,
		&"FinalRequiem": _res_requiem
	}

	vfx_profile = preload("res://resources/vfx_profiles/death_kam.tres")

	super._ready()

	# Warna visual khas Death Kam: putih pucat (manenya) + aksen bara kemerahan
	if visual_root and visual_root.has_node("Sprite"):
		var spr = visual_root.get_node("Sprite") as CanvasItem
		if spr:
			spr.modulate = Color(0.98, 0.97, 1.0, 1.0)

	if OS.is_debug_build():
		print("[CHARACTER][DeathKam] Death Kam diinisialisasi. HP: %d, Jalan: %.1f px/s, Dash: %.1f px/s." % [
			max_hp, walk_speed, get_dash_speed()
		])

func get_archetype() -> StringName:
	return &"death_kam"

func get_dash_speed() -> float:
	return CombatConstants.DEATH_KAM_DASH_SPEED

func get_dash_duration() -> int:
	return CombatConstants.DEATH_KAM_DASH_DURATION_FRAMES

## Mencari seluruh fighter lain di scene tree (lawan / target dummy training mode).
func _collect_opponents(node: Node, out: Array) -> void:
	for child in node.get_children():
		if child != self and child is CharacterBody2D and child.has_method("take_hit"):
			if not ("is_eliminated" in child and child.is_eliminated):
				out.append(child)
		if child.get_child_count() > 0:
			_collect_opponents(child, out)

## Menarik musuh terdekat di depan Death Kam ke jarak duel (mekanik "menarik").
## Rules: hanya bisa menarik pada jarak tertentu (min_range..max_range), di depan,
## dan relatif sejajar secara vertikal.
## Mengembalikan target yang berhasil ditarik, atau null jika tidak ada dalam jangkauan.
func _try_pull_opponent(min_range: float, max_range: float) -> Node2D:
	var opponents: Array = []
	var root: Node = get_tree().current_scene if get_tree() else null
	if not root:
		root = get_tree().root if get_tree() else self
	_collect_opponents(root, opponents)

	var best: Node2D = null
	var best_dist: float = INF
	for opp in opponents:
		if not is_instance_valid(opp):
			continue
		var dx: float = opp.global_position.x - global_position.x
		var dy: float = absf(opp.global_position.y - global_position.y)
		if dy > 90.0:
			continue
		# Hanya tarik lawan di depan Death Kam
		if float(facing_direction) * dx <= 0.0:
			continue
		var dist: float = absf(dx)
		# Rule jarak tertentu: harus berada di antara min_range dan max_range
		if dist < min_range or dist > max_range:
			continue
		# Prioritas target terdekat yang masih valid
		if dist < best_dist:
			best_dist = dist
			best = opp

	if not best:
		return null

	# Aktifkan visual tangan menjulur/menarik
	is_pulling_target = true
	pull_visual_frames = pull_visual_max_frames
	pull_visual_reach = clampf(best_dist, min_range, max_range)

	# Tarik lawan ke depan Death Kam (posisi grab rapat)
	best.global_position.x = global_position.x + float(facing_direction) * PULL_CLOSE_DISTANCE
	best.velocity = Vector2(0.0, best.velocity.y * 0.5)
	pull_executed.emit(best)
	_play_pull_voice()
	return best

func _play_pull_voice() -> void:
	# Suara lantang "sini amu" saat tarikan Death Kam berhasil
	var am: Node = null
	if Engine.has_singleton("AudioManager"):
		# Unlikely for script class, fallback below
		pass
	# Coba autoload/node root bernama AudioManager
	if has_node("/root/AudioManager"):
		am = get_node("/root/AudioManager")
	# Coba static instance (AudioManager.instance)
	if am == null:
		var am_script = load("res://scripts/audio/audio_manager.gd")
		if am_script and "instance" in am_script and am_script.instance != null:
			am = am_script.instance
	if am and am.has_method("play_death_kam_pull_voice"):
		am.play_death_kam_pull_voice()

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if pull_visual_frames > 0:
		pull_visual_frames -= 1
		if pull_visual_frames <= 0:
			is_pulling_target = false
			pull_visual_reach = 0.0

func is_death_kam_pulling() -> bool:
	return is_pulling_target and pull_visual_frames > 0

func get_pull_visual_progress() -> float:
	if pull_visual_max_frames <= 0:
		return 0.0
	return float(pull_visual_frames) / float(pull_visual_max_frames)

func get_pull_visual_reach() -> float:
	return pull_visual_reach

## Light Attack (5L): Death Pull Punch — cetakaran gaib menarik lawan mendekat,
## lalu pukulan keras menghantam setelah lawan tertarik ke depannya.
## Hanya aktif pada jarak tertentu (PULL_MIN_RANGE .. PULL_RANGE).
func _execute_death_pull_punch() -> void:
	_try_pull_opponent(PULL_MIN_RANGE, PULL_RANGE)
	var atk = attack_resources.get(&"5L")
	if atk:
		request_attack(atk)

## Heavy Attack (5H): Death Kam Rage — pukulan murka bermuatan energi.
## Super armor 12 frame selama startup; energi tembus guard (chip damage) dan memicu wall bounce.
func _execute_death_kam_rage() -> void:
	super_armor_frames = RAGE_ARMOR_FRAMES
	var atk = attack_resources.get(&"5H")
	if atk:
		request_attack(atk)
	rage_activated.emit()

## Skill 1 (U): Grave Chain — rantai kuburan jarak jauh. Menarik lawan dari kejauhan
## ke depan Death Kam (grab anti-block, mengabaikan normal block).
## Hanya aktif pada jarak tertentu (GRAVE_CHAIN_MIN_RANGE .. GRAVE_CHAIN_RANGE).
func _execute_grave_chain() -> void:
	var pulled := _try_pull_opponent(GRAVE_CHAIN_MIN_RANGE, GRAVE_CHAIN_RANGE)
	var atk = attack_resources.get(&"Skill1")
	if atk:
		request_attack(atk)
	if pulled:
		grave_chain_executed.emit(pulled)

## Skill 2 (I): Death's Resolve — Death Kam mengeras bagai batu nisan.
## Full super armor selama 40 frame terhadap serangan non-grab + letupan dorong.
func _execute_deaths_resolve() -> void:
	super_armor_frames = RESOLVE_ARMOR_FRAMES
	velocity.x = 0.0
	var atk = attack_resources.get(&"Skill2")
	if atk:
		request_attack(atk)
	death_resolve_activated.emit()

## Intersepsi nama serangan: 5L/5H/Skill1/Skill2 Death Kam memakai logika khusus (pull & rage).
func request_attack_by_name(atk_name: StringName) -> void:
	if atk_name == &"5L":
		_execute_death_pull_punch()
		return
	elif atk_name == &"5H":
		_execute_death_kam_rage()
		return
	elif atk_name == &"Skill1":
		_execute_grave_chain()
		return
	elif atk_name == &"Skill2":
		_execute_deaths_resolve()
		return
	super.request_attack_by_name(atk_name)

func execute_skill_1() -> void:
	_execute_grave_chain()

func execute_skill_2() -> void:
	_execute_deaths_resolve()

func execute_ultimate() -> void:
	# Ultimate: Final Requiem — ledakan amarah pamungkas, menguras penuh meter ultimate
	if current_ultimate >= max_ultimate:
		drain_ultimate(max_ultimate)
		invulnerability_frames = 16
		var atk = attack_resources.get(&"Ultimate")
		if atk:
			request_attack(atk)
		final_requiem_executed.emit()

		if OS.is_debug_build():
			print("[ULTIMATE][DeathKam] FINAL REQUIEM MENYALA! Amarah putih menggelegar!")
