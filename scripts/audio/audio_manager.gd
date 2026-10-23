class_name AudioManager
extends Node

## Pengelola Sistem Audio & Announcer 5-Bus Terpadu (Story 6.3, Story 8.1 & Story 8.2)
## Mengatur bus Master, BGM, SFX, Announcer, MechaVoice serta pemutar SFX dan Cyberpunk Synthwave OST

const AudioSynthesizerScript = preload("res://scripts/audio/audio_synthesizer.gd")
const MusicSynthesizerScript = preload("res://scripts/audio/music_synthesizer.gd")

const BUS_MASTER: StringName = &"Master"
const BUS_BGM: StringName = &"BGM"
const BUS_SFX: StringName = &"SFX"
const BUS_ANNOUNCER: StringName = &"Announcer"
const BUS_MECHA_VOICE: StringName = &"MechaVoice"

const THEME_TITLE: StringName = &"title"
const THEME_ARENA: StringName = &"arena"
const THEME_STOP: StringName = &"stop"

const REQUIRED_BUSSES: Array[StringName] = [
	BUS_MASTER,
	BUS_BGM,
	BUS_SFX,
	BUS_ANNOUNCER,
	BUS_MECHA_VOICE
]

static var instance: AudioManager = null

# Audio Streams Sintetis SFX Dasar (Story 6.3)
var sfx_metal_clang: AudioStreamWAV = null
var sfx_spark_parry: AudioStreamWAV = null
var sfx_hydraulic_hiss: AudioStreamWAV = null
var sfx_announcer_chime: AudioStreamWAV = null

# Audio Streams Sintetis SFX Mecha Combat Expansion (Story 8.2)
var sfx_thruster_dash: AudioStreamWAV = null
var sfx_overclock_alarm: AudioStreamWAV = null
var sfx_meltdown_shutdown: AudioStreamWAV = null
var sfx_heavy_impact: AudioStreamWAV = null
var sfx_wall_bounce: AudioStreamWAV = null

# Audio Streams Sintetis BGM (Story 8.1)
var bgm_title: AudioStreamWAV = null
var bgm_arena: AudioStreamWAV = null

# Player Pool SFX & Announcer
var _sfx_players: Array[AudioStreamPlayer] = []
var _announcer_player: AudioStreamPlayer = null
const SFX_POOL_SIZE: int = 8

# Dual BGM Players for Seamless Crossfading
var _bgm_player_a: AudioStreamPlayer = null
var _bgm_player_b: AudioStreamPlayer = null
var _active_bgm_player: AudioStreamPlayer = null
var _current_bgm_theme: StringName = &""
var _bgm_tween: Tween = null

signal announcer_called(cue: String)
signal bgm_changed(theme: StringName)

func _enter_tree() -> void:
	if instance == null:
		instance = self

func _exit_tree() -> void:
	if instance == self:
		instance = null

func _ready() -> void:
	ensure_audio_busses()
	_init_synthesized_sounds()
	_init_audio_players()

	if is_instance_valid(EventBus):
		EventBus.hit_confirmed.connect(_on_hit_confirmed)
		if EventBus.has_signal("parry_triggered"):
			EventBus.parry_triggered.connect(_on_parry_triggered)
		if EventBus.has_signal("round_ended"):
			EventBus.round_ended.connect(_on_round_ended)
		if EventBus.has_signal("cliffhanger_triggered"):
			EventBus.cliffhanger_triggered.connect(_on_cliffhanger_triggered)
		if EventBus.has_signal("state_changed"):
			EventBus.state_changed.connect(_on_state_changed)
		if EventBus.has_signal("overclock_triggered"):
			EventBus.overclock_triggered.connect(_on_overclock_triggered)

## Memastikan kelima bus audio tersedia di AudioServer
func ensure_audio_busses() -> void:
	for bus_name in REQUIRED_BUSSES:
		var idx := AudioServer.get_bus_index(bus_name)
		if idx == -1:
			var new_idx := AudioServer.bus_count
			AudioServer.add_bus(new_idx)
			AudioServer.set_bus_name(new_idx, bus_name)
			AudioServer.set_bus_send(new_idx, BUS_MASTER)

## Mengatur volume bus dalam nilai linear (0.0 sampai 1.0)
func set_bus_volume(bus_name: StringName, linear_val: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		var clamped := clampf(linear_val, 0.0, 1.0)
		if clamped <= 0.001:
			AudioServer.set_bus_mute(idx, true)
		else:
			AudioServer.set_bus_mute(idx, false)
			AudioServer.set_bus_volume_db(idx, linear_to_db(clamped))

## Mendapatkan volume linear saat ini dari bus
func get_bus_volume(bus_name: StringName) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx != -1:
		if AudioServer.is_bus_mute(idx):
			return 0.0
		return db_to_linear(AudioServer.get_bus_volume_db(idx))
	return 1.0

func _init_synthesized_sounds() -> void:
	# SFX Inti (Story 6.3)
	sfx_metal_clang = AudioSynthesizerScript.generate_metal_clang(340.0, 0.20)
	sfx_spark_parry = AudioSynthesizerScript.generate_spark_parry(880.0, 0.32)
	sfx_hydraulic_hiss = AudioSynthesizerScript.generate_hydraulic_hiss(0.18)
	sfx_announcer_chime = AudioSynthesizerScript.generate_announcer_chime(0.35)

	# SFX Mecha Combat Expansion (Story 8.2)
	sfx_thruster_dash = AudioSynthesizerScript.generate_thruster_dash(0.22)
	sfx_overclock_alarm = AudioSynthesizerScript.generate_overclock_alarm(0.18)
	sfx_meltdown_shutdown = AudioSynthesizerScript.generate_meltdown_shutdown(0.45)
	sfx_heavy_impact = AudioSynthesizerScript.generate_heavy_impact(0.28)
	sfx_wall_bounce = AudioSynthesizerScript.generate_wall_bounce(0.25)

func _ensure_bgm_streams() -> void:
	if bgm_title == null:
		bgm_title = MusicSynthesizerScript.generate_title_theme()
	if bgm_arena == null:
		bgm_arena = MusicSynthesizerScript.generate_arena_theme()

func _init_audio_players() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

	_announcer_player = AudioStreamPlayer.new()
	_announcer_player.bus = BUS_ANNOUNCER
	add_child(_announcer_player)

	# BGM Dual Players
	_bgm_player_a = AudioStreamPlayer.new()
	_bgm_player_a.bus = BUS_BGM
	_bgm_player_a.volume_db = -80.0
	add_child(_bgm_player_a)

	_bgm_player_b = AudioStreamPlayer.new()
	_bgm_player_b.bus = BUS_BGM
	_bgm_player_b.volume_db = -80.0
	add_child(_bgm_player_b)

## Memutar musik BGM bertema secara crossfade (Story 8.1)
func play_bgm(theme: StringName, fade_time: float = 0.5) -> void:
	if theme == _current_bgm_theme and _active_bgm_player != null and _active_bgm_player.playing:
		return

	if theme == THEME_STOP:
		stop_bgm(fade_time)
		return

	_ensure_bgm_streams()

	var target_stream: AudioStreamWAV = null
	if theme == THEME_TITLE:
		target_stream = bgm_title
	elif theme == THEME_ARENA:
		target_stream = bgm_arena

	if target_stream == null:
		return

	# Tentukan player target untuk crossfade
	var next_player: AudioStreamPlayer = _bgm_player_b if _active_bgm_player == _bgm_player_a else _bgm_player_a
	var outgoing_player: AudioStreamPlayer = _active_bgm_player

	next_player.stream = target_stream
	next_player.volume_db = -80.0
	next_player.play()

	_active_bgm_player = next_player
	_current_bgm_theme = theme
	bgm_changed.emit(theme)

	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()

	if is_inside_tree() and fade_time > 0.0:
		_bgm_tween = create_tween().set_parallel(true)
		_bgm_tween.tween_property(next_player, "volume_db", 0.0, fade_time)
		if outgoing_player and outgoing_player.playing:
			_bgm_tween.tween_property(outgoing_player, "volume_db", -80.0, fade_time)
			_bgm_tween.chain().tween_callback(outgoing_player.stop)
	else:
		next_player.volume_db = 0.0
		if outgoing_player:
			outgoing_player.stop()

## Menghentikan pemutaran BGM dengan fade out
func stop_bgm(fade_time: float = 0.5) -> void:
	_current_bgm_theme = &""
	if _bgm_tween and _bgm_tween.is_valid():
		_bgm_tween.kill()

	if _active_bgm_player and _active_bgm_player.playing:
		if is_inside_tree() and fade_time > 0.0:
			_bgm_tween = create_tween()
			_bgm_tween.tween_property(_active_bgm_player, "volume_db", -80.0, fade_time)
			_bgm_tween.tween_callback(_active_bgm_player.stop)
		else:
			_active_bgm_player.stop()
	_active_bgm_player = null

func get_current_bgm_theme() -> StringName:
	return _current_bgm_theme

## Static helper untuk pemanggilan cepat dari mana saja
static func play_music(theme: StringName, fade_time: float = 0.5) -> void:
	if instance != null:
		instance.play_bgm(theme, fade_time)

static func stop_music(fade_time: float = 0.5) -> void:
	if instance != null:
		instance.stop_bgm(fade_time)

func play_sfx(stream: AudioStream, bus_target: StringName = BUS_SFX) -> void:
	if not stream:
		return
	for p in _sfx_players:
		if not p.playing:
			p.bus = bus_target
			p.stream = stream
			p.play()
			return

	# Jika semua sibuk, timpa player pertama
	if _sfx_players.size() > 0:
		var p0 = _sfx_players[0]
		p0.bus = bus_target
		p0.stream = stream
		p0.play()

func play_announcer(cue: String) -> void:
	if _announcer_player:
		_announcer_player.stream = sfx_announcer_chime
		_announcer_player.play()
	announcer_called.emit(cue)

# Helper SFX Mecha Langsung (Story 8.2)
func play_thruster_dash() -> void:
	play_sfx(sfx_thruster_dash, BUS_SFX)

func play_overclock_alarm() -> void:
	play_sfx(sfx_overclock_alarm, BUS_SFX)

func play_meltdown_shutdown() -> void:
	play_sfx(sfx_meltdown_shutdown, BUS_SFX)

func play_heavy_impact() -> void:
	play_sfx(sfx_heavy_impact, BUS_SFX)

func play_wall_bounce() -> void:
	play_sfx(sfx_wall_bounce, BUS_SFX)

func _on_hit_confirmed(_attacker: Node2D, _victim: Node2D, hit_data: Variant) -> void:
	var dmg: float = 0.0
	var is_wall_bounce: bool = false
	var is_ground_bounce: bool = false

	if hit_data != null:
		if hit_data is Dictionary:
			dmg = float(hit_data.get("damage", 0.0))
			is_wall_bounce = bool(hit_data.get("wall_bounce", false))
			is_ground_bounce = bool(hit_data.get("ground_bounce", false))
		elif hit_data is Resource:
			if "damage" in hit_data:
				dmg = float(hit_data.damage)
			if "wall_bounce" in hit_data:
				is_wall_bounce = bool(hit_data.wall_bounce)
			if "ground_bounce" in hit_data:
				is_ground_bounce = bool(hit_data.ground_bounce)

	if is_wall_bounce:
		play_wall_bounce()
	elif dmg >= 120.0 or is_ground_bounce:
		play_heavy_impact()
	else:
		play_sfx(sfx_metal_clang, BUS_SFX)

func _on_parry_triggered(_defender: Node2D, _attacker: Node2D) -> void:
	play_sfx(sfx_spark_parry, BUS_SFX)

func _on_state_changed(_character: Node2D, _prev_state: StringName, new_state: StringName) -> void:
	if new_state == &"Dash" or new_state == &"AirDash":
		play_thruster_dash()
	elif new_state == &"Meltdown":
		play_meltdown_shutdown()
		play_announcer("CRITICAL MELTDOWN!")

func _on_overclock_triggered(_character: Node2D, is_active: bool) -> void:
	if is_active:
		play_overclock_alarm()

func _on_round_ended(_winner_id: int, reason: StringName) -> void:
	var cue: String = "K.O.!" if reason == &"ko" else "RING OUT!"
	play_announcer(cue)

func _on_cliffhanger_triggered(_mecha_id: int, _side: StringName) -> void:
	play_sfx(sfx_hydraulic_hiss, BUS_SFX)
