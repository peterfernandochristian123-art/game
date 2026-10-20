class_name AudioSynthesizer
extends RefCounted

## Generator Audio Sintesis Procedural Retro 32-Bit (Story 6.3)
## Menghasilkan AudioStreamWAV instan secara terprogram tanpa ketergantungan aset eksternal

const SAMPLE_RATE: int = 22050

## Menghasilkan suara benturan baja berat (Heavy Metal Clang)
static func generate_metal_clang(frequency: float = 340.0, duration: float = 0.22) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)
		# Decay eksponensial cepat
		var env: float = exp(-progress * 8.0)

		# Kombinasi square wave frekuensi dasar dan nada harmoni logam
		var wave1: float = 1.0 if sin(2.0 * PI * frequency * t) >= 0.0 else -1.0
		var wave2: float = sin(2.0 * PI * (frequency * 2.45) * t) * 0.5
		var noise: float = (randf() * 2.0 - 1.0) * 0.3 * exp(-progress * 15.0)

		var val: float = (wave1 * 0.6 + wave2 + noise) * env
		val = clampf(val, -1.0, 1.0)
		var byte_val: int = clampi(int(128.0 + val * 127.0), 0, 255)
		data[i] = byte_val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan suara tangkisan Spark Parry frekuensi tinggi
static func generate_spark_parry(frequency: float = 880.0, duration: float = 0.35) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)
		var env: float = exp(-progress * 5.0)

		# Dual-sine chime dengan modulasi cincin
		var sine1: float = sin(2.0 * PI * frequency * t)
		var sine2: float = sin(2.0 * PI * (frequency * 1.5) * t)
		var chime: float = (sine1 * 0.7 + sine2 * 0.5) * env

		chime = clampf(chime, -1.0, 1.0)
		var byte_val: int = clampi(int(128.0 + chime * 127.0), 0, 255)
		data[i] = byte_val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan suara desisan hidrolik pneumatik / thruster
static func generate_hydraulic_hiss(duration: float = 0.18) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	var last_noise: float = 0.0
	for i in range(total_samples):
		var progress: float = float(i) / float(total_samples)
		# Attack cepat (10%), release halus (90%)
		var env: float = 1.0
		if progress < 0.1:
			env = progress / 0.1
		else:
			env = 1.0 - (progress - 0.1) / 0.9

		# Low-pass filtered noise
		var white: float = randf() * 2.0 - 1.0
		last_noise = lerpf(last_noise, white, 0.25)
		var val: float = clampf(last_noise * env, -1.0, 1.0)
		var byte_val: int = clampi(int(128.0 + val * 127.0), 0, 255)
		data[i] = byte_val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan nada lonceng Announcer / Arcade Cue
static func generate_announcer_chime(duration: float = 0.38) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)

		# Arpeggio 2 nada (440 Hz nada rendah -> 880 Hz nada tinggi)
		var freq: float = 440.0 if progress < 0.35 else 660.0
		var env: float = exp(-fmod(progress, 0.35) * 4.0)

		var val: float = sin(2.0 * PI * freq * t) * env
		val = clampf(val, -1.0, 1.0)
		var byte_val: int = clampi(int(128.0 + val * 127.0), 0, 255)
		data[i] = byte_val

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
