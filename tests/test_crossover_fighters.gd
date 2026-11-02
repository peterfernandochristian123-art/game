extends Node

func _ready() -> void:
	print("==================================================")
	print("[VERIFIKASI] Menguji 6 Karakter Crossover...")
	print("==================================================")
	var FighterFactory = preload("res://scripts/characters/fighter_factory.gd")
	var ids: Array[StringName] = [&"miku", &"reimu", &"marisa", &"remilia", &"sasuke", &"2b"]

	for id in ids:
		var f: CharacterBody2D = FighterFactory.create_fighter(id, 1)
		if f == null:
			printerr("GAGAL instansiasi: %s" % id)
			get_tree().quit(1)
			return

		add_child(f)
		print("[OK] Fighter '%s' instansiasi sukses! Max HP: %d, Archetype: %s" % [id, f.max_hp, f.get_archetype()])
		await get_tree().process_frame
		f.queue_free()

	print("==================================================")
	print("SEMUA 6 KARAKTER CROSSOVER LULUS PENGUJIAN!")
	print("==================================================")
	get_tree().quit(0)
