class_name MenuAudio
extends Node

## Helper Audio Sintesis Prosedural untuk UI & Menu (32-bit Arcade Style)
## Menghasilkan nada beep dan konfirmasi retro secara langsung tanpa aset eksternal

static func create_tone_stream(freq: float, duration: float, volume: float = 0.25, is_arpeggio: bool = false, freq_end: float = 0.0) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	stream.stereo = false
	var num_samples := int(stream.mix_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in range(num_samples):
		var t_norm := float(i) / float(num_samples)
		var current_freq := freq
		if freq_end > 0.0:
			current_freq = lerpf(freq, freq_end, t_norm)
		elif is_arpeggio:
			# Arpeggio retro melompat pada 50% durasi
			current_freq = freq if t_norm < 0.5 else freq * 1.5

		var t := float(i) / float(stream.mix_rate)
		# Amplop linier untuk mencegah 'pop/click' audio
		var envelope := 1.0 - t_norm
		var sample := int(sin(t * current_freq * TAU) * 32767.0 * volume * envelope)
		sample = clampi(sample, -32768, 32767)
		data.encode_s16(i * 2, sample)

	stream.data = data
	return stream

static func play_sound(parent: Node, stream: AudioStreamWAV) -> AudioStreamPlayer:
	if not parent or not stream:
		return null
	if DisplayServer.get_name() == "headless" or AudioServer.get_bus_count() == 0:
		return null
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.bus = &"Master"
	parent.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
	return player

static func play_nav_beep(parent: Node) -> AudioStreamPlayer:
	# Nada pendek bernada sedang (720 Hz, 40ms) untuk pergerakan fokus menu
	var stream := create_tone_stream(720.0, 0.04, 0.2)
	return play_sound(parent, stream)

static func play_confirm_chime(parent: Node) -> AudioStreamPlayer:
	# Nada arpeggio retro naik (880 Hz -> 1320 Hz, 120ms) untuk konfirmasi pilihan
	var stream := create_tone_stream(880.0, 0.12, 0.28, true)
	return play_sound(parent, stream)

static func play_cancel_buzz(parent: Node) -> AudioStreamPlayer:
	# Nada turun (320 Hz -> 160 Hz, 80ms) untuk pembatalan / kembali
	var stream := create_tone_stream(320.0, 0.08, 0.2, false, 160.0)
	return play_sound(parent, stream)

static func play_cancel_chime(parent: Node) -> AudioStreamPlayer:
	return play_cancel_buzz(parent)

