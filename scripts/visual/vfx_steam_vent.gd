class_name VFXSteamVent
extends CPUParticles2D

## Efek Visual Pembuangan Uap Panas / Exhaust Venting (Story 6.2)
## Mengeluarkan uap vertikal saat suhu mecha mencapai zona Overclock (>= 80%)
## dan berubah warna merah membara saat mendekati Meltdown

var target_mecha: Node2D = null

func _ready() -> void:
	emitting = false
	amount = 12
	lifetime = 0.4
	direction = Vector2(0, -1)
	spread = 25.0
	gravity = Vector2(0, -80)
	initial_velocity_min = 30.0
	initial_velocity_max = 60.0
	scale_amount_min = 2.0
	scale_amount_max = 4.5
	
	color = Color(0.85, 0.95, 1.0, 0.5)

	# Cari parent mecha jika belum di-bind manual
	if not target_mecha and get_parent() is CharacterBody2D:
		bind_mecha(get_parent() as Node2D)

func bind_mecha(mecha: Node2D) -> void:
	target_mecha = mecha
	if target_mecha.has_signal("heat_changed"):
		if not target_mecha.heat_changed.is_connected(_on_heat_changed):
			target_mecha.heat_changed.connect(_on_heat_changed)

func _on_heat_changed(current_heat: float, _max_heat: float) -> void:
	update_heat_visual(current_heat)

func update_heat_visual(current_heat: float) -> void:
	if current_heat >= 95.0:
		# Suhu Kritis / Meltdown: Uap merah membara tebal
		emitting = true
		amount = 18
		color = Color(1.0, 0.25, 0.1, 0.8)
		initial_velocity_max = 90.0
	elif current_heat >= 80.0:
		# Overclock Zone: Uap panas putih kebiruan aktif
		emitting = true
		amount = 10
		color = Color(0.7, 0.95, 1.0, 0.55)
		initial_velocity_max = 50.0
	else:
		# Suhu normal: Tutup ventilasi
		emitting = false
