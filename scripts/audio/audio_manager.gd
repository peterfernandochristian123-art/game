class_name AudioManager
extends Node

## Pengelola Sistem Audio & Announcer 5-Bus Terpadu (Story 6.3)
## Mengatur bus Master, BGM, SFX, Announcer, MechaVoice dan memutar efek sintetis 32-bit retro

const AudioSynthesizerScript = preload("res://scripts/audio/audio_synthesizer.gd")

const BUS_MASTER: StringName = &"Master"
const BUS_BGM: StringName = &"BGM"
const BUS_SFX: StringName = &"SFX"
const BUS_ANNOUNCER: StringName = &"Announcer"
const BUS_MECHA_VOICE: StringName = &"MechaVoice"

const REQUIRED_BUSSES: Array[StringName] = [
	BUS_MASTER,
	BUS_BGM,
	BUS_SFX,
	BUS_ANNOUNCER,
	BUS_MECHA_VOICE
]

# Audio Streams Sintetis
var sfx_metal_clang: AudioStreamWAV = null
var sfx_spark_parry: AudioStreamWAV = null
var sfx_hydraulic_hiss: AudioStreamWAV = null
var sfx_announcer_chime: AudioStreamWAV = null

# Player Pool
var _sfx_players: Array[AudioStreamPlayer] = []
var _announcer_player: AudioStreamPlayer = null
const SFX_POOL_SIZE: int = 6

signal announcer_called(cue: String)

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
	sfx_metal_clang = AudioSynthesizerScript.generate_metal_clang(340.0, 0.20)
	sfx_spark_parry = AudioSynthesizerScript.generate_spark_parry(880.0, 0.32)
	sfx_hydraulic_hiss = AudioSynthesizerScript.generate_hydraulic_hiss(0.18)
	sfx_announcer_chime = AudioSynthesizerScript.generate_announcer_chime(0.35)

func _init_audio_players() -> void:
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

	_announcer_player = AudioStreamPlayer.new()
	_announcer_player.bus = BUS_ANNOUNCER
	add_child(_announcer_player)

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

func _on_hit_confirmed(_attacker: Node2D, _victim: Node2D, _hit_data: Variant) -> void:
	play_sfx(sfx_metal_clang, BUS_SFX)

func _on_parry_triggered(_defender: Node2D, _attacker: Node2D) -> void:
	play_sfx(sfx_spark_parry, BUS_SFX)

func _on_round_ended(_winner_id: int, reason: StringName) -> void:
	var cue: String = "K.O.!" if reason == &"ko" else "RING OUT!"
	play_announcer(cue)

func _on_cliffhanger_triggered(_mecha_id: int, _side: StringName) -> void:
	play_sfx(sfx_hydraulic_hiss, BUS_SFX)
