class_name MusicSynthesizer
extends RefCounted

## Generator Musik BGM Sintesis Retro Cyberpunk Synthwave 90-an (Story 8.1)
## Menghasilkan trek BGM looping berformat AudioStreamWAV secara terprogram
## tanpa dependensi file audio eksternal dan terikat pada bus BGM.

const SAMPLE_RATE: int = 22050

## Mengonversi nomor MIDI note ke frekuensi dalam Hertz
static func midi_to_freq(note: int) -> float:
	return 440.0 * pow(2.0, (float(note) - 69.0) / 12.0)

## Menghasilkan Title Theme ("Neon Horizon") - 105 BPM, Key of D Minor, Looping
static func generate_title_theme() -> AudioStreamWAV:
	var bpm: float = 105.0
	var beats_per_bar: int = 4
	var total_bars: int = 4
	var total_beats: int = total_bars * beats_per_bar
	var seconds_per_beat: float = 60.0 / bpm
	var total_duration: float = float(total_beats) * seconds_per_beat
	var total_samples: int = int(SAMPLE_RATE * total_duration)

	var data := PackedByteArray()
	data.resize(total_samples)

	# Chord progression (D Minor): Bar 1: Dm (D3), Bar 2: Bb (Bb2), Bar 3: C (C3), Bar 4: Am (A2)
	var root_notes: Array[int] = [50, 46, 48, 45] # D3, Bb2, C3, A2
	var chord_triads: Array[Array] = [
		[62, 65, 69, 74], # D4, F4, A4, D5 (Dm)
		[58, 62, 65, 70], # Bb3, D4, F4, Bb4 (Bb)
		[60, 64, 67, 72], # C4, E4, G4, C5 (C)
		[57, 60, 64, 69]  # A3, C4, E4, A4 (Am)
	]

	var last_noise: float = 0.0

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_exact: float = t / seconds_per_beat
		var current_bar: int = clampi(int(beat_exact / 4.0), 0, total_bars - 1)
		var beat_in_bar: float = fmod(beat_exact, 1.0)
		var step_16th: int = int(beat_exact * 4.0)

		# 1. DRUMS
		var drum_mix: float = 0.0
		# Kick on beat 0 and beat 2 of each bar
		var beat_int: int = int(beat_exact) % 4
		var time_since_beat: float = fmod(t, seconds_per_beat)
		if beat_int == 0 or beat_int == 2:
			if time_since_beat < 0.16:
				var kick_env: float = exp(-time_since_beat * 24.0)
				var kick_freq: float = 120.0 * (1.0 + exp(-time_since_beat * 40.0) * 2.0)
				drum_mix += sin(2.0 * PI * kick_freq * time_since_beat) * kick_env * 0.45

		# Snare on beat 1 and beat 3
		if beat_int == 1 or beat_int == 3:
			if time_since_beat < 0.20:
				var snare_env: float = exp(-time_since_beat * 18.0)
				var white: float = randf() * 2.0 - 1.0
				last_noise = lerpf(last_noise, white, 0.4)
				var snare_body: float = sin(2.0 * PI * 180.0 * time_since_beat) * 0.3
				drum_mix += (last_noise * 0.7 + snare_body) * snare_env * 0.35

		# Hi-hat on every 8th note
		var eighth_time: float = fmod(t, seconds_per_beat * 0.5)
		if eighth_time < 0.05:
			var hat_env: float = exp(-eighth_time * 65.0)
			var hat_noise: float = randf() * 2.0 - 1.0
			drum_mix += hat_noise * hat_env * 0.15

		# 2. BASSLINE (Pumping 8th note synth bass)
		var root_midi: int = root_notes[current_bar]
		var bass_freq: float = midi_to_freq(root_midi)
		var bass_time: float = fmod(t, seconds_per_beat * 0.5)
		var bass_env: float = exp(-bass_time * 6.5)
		# Sawtooth / square blend
		var bass_phase: float = fmod(t * bass_freq, 1.0)
		var bass_wave: float = (bass_phase * 2.0 - 1.0) * 0.6 + (1.0 if bass_phase < 0.5 else -1.0) * 0.4
		var bass_mix: float = bass_wave * bass_env * 0.30

		# 3. SYNTH ARPEGGIO (16th notes through triad)
		var chords: Array = chord_triads[current_bar]
		var note_idx: int = step_16th % chords.size()
		var arp_midi: int = chords[note_idx]
		var arp_freq: float = midi_to_freq(arp_midi)
		var arp_time: float = fmod(t, seconds_per_beat * 0.25)
		var arp_env: float = exp(-arp_time * 9.0)
		var arp_wave: float = sin(2.0 * PI * arp_freq * t) + sin(2.0 * PI * (arp_freq * 2.0) * t) * 0.25
		var arp_mix: float = arp_wave * arp_env * 0.20

		# Pad subtle chord warmth
		var pad_mix: float = sin(2.0 * PI * midi_to_freq(chords[0]) * t) * 0.08

		var total_signal: float = drum_mix + bass_mix + arp_mix + pad_mix
		total_signal = clampf(total_signal, -0.98, 0.98)
		var byte_val: int = clampi(int(128.0 + total_signal * 126.0), 0, 255)
		data[i] = byte_val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream

## Menghasilkan Arena Battle Theme ("Skyscraper Meltdown") - 128 BPM, Key of A Minor, Looping
static func generate_arena_theme() -> AudioStreamWAV:
	var bpm: float = 128.0
	var beats_per_bar: int = 4
	var total_bars: int = 4
	var total_beats: int = total_bars * beats_per_bar
	var seconds_per_beat: float = 60.0 / bpm
	var total_duration: float = float(total_beats) * seconds_per_beat
	var total_samples: int = int(SAMPLE_RATE * total_duration)

	var data := PackedByteArray()
	data.resize(total_samples)

	# Progression: Am (A2), F (F2), G (G2), Em (E2)
	var root_notes: Array[int] = [45, 41, 43, 40] # A2, F2, G2, E2
	var lead_motifs: Array[Array] = [
		[69, 72, 76, 79, 76, 72, 69, 76], # A4, C5, E5, G5... (Am)
		[65, 69, 72, 77, 72, 69, 65, 72], # F4, A4, C5, F5... (F)
		[67, 71, 74, 79, 74, 71, 67, 74], # G4, B4, D5, G5... (G)
		[64, 67, 71, 76, 71, 67, 64, 71]  # E4, G4, B4, E5... (Em)
	]

	var last_noise: float = 0.0

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var beat_exact: float = t / seconds_per_beat
		var current_bar: int = clampi(int(beat_exact / 4.0), 0, total_bars - 1)
		var step_16th: int = int(beat_exact * 4.0)
		var time_since_beat: float = fmod(t, seconds_per_beat)

		# 1. DRIVING INDUSTRIAL DRUMS
		var drum_mix: float = 0.0
		# Four-on-the-floor driving kick
		if time_since_beat < 0.14:
			var kick_env: float = exp(-time_since_beat * 28.0)
			var kick_freq: float = 150.0 * (1.0 + exp(-time_since_beat * 50.0) * 2.5)
			drum_mix += sin(2.0 * PI * kick_freq * time_since_beat) * kick_env * 0.50

		# Snare / Clap on beat 1 and 3
		var beat_int: int = int(beat_exact) % 4
		if beat_int == 1 or beat_int == 3:
			if time_since_beat < 0.22:
				var snare_env: float = exp(-time_since_beat * 16.0)
				var white: float = randf() * 2.0 - 1.0
				last_noise = lerpf(last_noise, white, 0.45)
				drum_mix += last_noise * snare_env * 0.35

		# Off-beat open hi-hat (on each half-beat)
		var half_beat: float = fmod(t + seconds_per_beat * 0.5, seconds_per_beat)
		if half_beat < 0.09:
			var hat_env: float = exp(-half_beat * 35.0)
			drum_mix += (randf() * 2.0 - 1.0) * hat_env * 0.18

		# 2. 16TH-NOTE ROLLING SYNTH BASS (Cyberpunk bass groove)
		var root_midi: int = root_notes[current_bar]
		# Add octave jump on 3rd 16th note
		var note_offset: int = 12 if (step_16th % 4 == 2) else 0
		var bass_freq: float = midi_to_freq(root_midi + note_offset)
		var bass_step_time: float = fmod(t, seconds_per_beat * 0.25)
		var bass_env: float = exp(-bass_step_time * 12.0)
		var bass_phase: float = fmod(t * bass_freq, 1.0)
		# Aggressive sawtooth
		var bass_saw: float = (bass_phase * 2.0 - 1.0)
		var bass_mix: float = bass_saw * bass_env * 0.32

		# 3. HIGH-ENERGY SYNTH LEAD
		var lead_notes: Array = lead_motifs[current_bar]
		var lead_idx: int = int(step_16th * 0.5) % lead_notes.size()
		var lead_midi: int = lead_notes[lead_idx]
		var lead_freq: float = midi_to_freq(lead_midi)
		# Dual detuned saw for wide retro chorus effect
		var lead_wave1: float = (fmod(t * lead_freq, 1.0) * 2.0 - 1.0)
		var lead_wave2: float = (fmod(t * (lead_freq * 1.008), 1.0) * 2.0 - 1.0)
		var lead_mix: float = (lead_wave1 + lead_wave2) * 0.5 * 0.22

		var total_signal: float = drum_mix + bass_mix + lead_mix
		total_signal = clampf(total_signal, -0.98, 0.98)
		var byte_val: int = clampi(int(128.0 + total_signal * 126.0), 0, 255)
		data[i] = byte_val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = total_samples
	stream.data = data
	return stream
