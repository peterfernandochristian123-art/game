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

## Menghasilkan suara dorongan jet thruster mecha (Vector Dash)
static func generate_thruster_dash(duration: float = 0.22) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	var last_noise: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)

		# Sub-bass ignition pop pada awal dorongan (0-0.05s)
		var pop_env: float = exp(-t * 40.0)
		var pop_wave: float = sin(2.0 * PI * 85.0 * t) * pop_env * 0.65

		# Resonant filtered noise whoosh untuk hembusan jet thruster
		var whoosh_env: float = sin(progress * PI)
		var white: float = randf() * 2.0 - 1.0
		last_noise = lerpf(last_noise, white, 0.35)
		var jet_whoosh: float = last_noise * whoosh_env * 0.75

		var val: float = clampf(pop_wave + jet_whoosh, -0.98, 0.98)
		data[i] = clampi(int(128.0 + val * 126.0), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan alarm peringatan reaktor zona Overclock (80-99%)
static func generate_overclock_alarm(duration: float = 0.18) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)

		# Dua nada strobo digital cepat (1050 Hz dan 1400 Hz)
		var freq: float = 1050.0 if progress < 0.5 else 1400.0
		var sub_env: float = exp(-fmod(progress, 0.5) * 6.0)
		# Square wave tajam ala alarm digital mecha
		var wave: float = 1.0 if sin(2.0 * PI * freq * t) >= 0.0 else -1.0
		var val: float = wave * sub_env * 0.45
		val = clampf(val, -0.98, 0.98)
		data[i] = clampi(int(128.0 + val * 126.0), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan suara shutdown mati daya darurat (Emergency Meltdown 100%)
static func generate_meltdown_shutdown(duration: float = 0.45) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)

		# Penurunan nada eksponensial (pitch dive dari 600 Hz jatuh ke 60 Hz)
		var current_freq: float = lerpf(600.0, 60.0, pow(progress, 0.7))
		var env: float = (1.0 - progress) * (1.0 - progress)
		var sine: float = sin(2.0 * PI * current_freq * t)

		# Electrical buzz hum (50 Hz / 60 Hz)
		var hum: float = (1.0 if sin(2.0 * PI * 60.0 * t) >= 0.0 else -1.0) * 0.25 * env

		var val: float = clampf(sine * 0.7 * env + hum, -0.98, 0.98)
		data[i] = clampi(int(128.0 + val * 126.0), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan suara benturan baja berbobot berat (Heavy Impact Slam)
static func generate_heavy_impact(duration: float = 0.28) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	var last_noise: float = 0.0
	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)

		# Sub punch (90 Hz decaying ke 40 Hz)
		var sub_freq: float = lerpf(90.0, 40.0, progress)
		var sub_env: float = exp(-progress * 9.0)
		var sub_wave: float = sin(2.0 * PI * sub_freq * t) * sub_env * 0.70

		# Metal crunch noise
		var white: float = randf() * 2.0 - 1.0
		last_noise = lerpf(last_noise, white, 0.5)
		var noise_env: float = exp(-progress * 14.0)
		var metal_crunch: float = last_noise * noise_env * 0.50

		var val: float = clampf(sub_wave + metal_crunch, -0.98, 0.98)
		data[i] = clampi(int(128.0 + val * 126.0), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

## Menghasilkan suara pantulan benturan baja dinding/lantai (Wall/Ledge Bounce)
static func generate_wall_bounce(duration: float = 0.25) -> AudioStreamWAV:
	var total_samples: int = int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(total_samples)

	for i in range(total_samples):
		var t: float = float(i) / float(SAMPLE_RATE)
		var progress: float = float(i) / float(total_samples)

		# Frekuensi logam bergetar (210 Hz dengan modulasi nada)
		var env: float = exp(-progress * 7.5)
		var wave1: float = sin(2.0 * PI * 210.0 * t)
		var wave2: float = sin(2.0 * PI * 315.0 * t) * 0.45
		var clang: float = (wave1 + wave2) * env * 0.75

		var val: float = clampf(clang, -0.98, 0.98)
		data[i] = clampi(int(128.0 + val * 126.0), 0, 255)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

