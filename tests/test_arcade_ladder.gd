extends Node

## Test Suite: Epic 15 - Arcade Ladder & Boss Gauntlet Mode
## Menguji seluruh fungsionalitas Story 15.1, 15.2, 15.3, 15.4

const DialogueDBScript = preload("res://scripts/arcade/dialogue_db.gd")
const DialogueOverlayScript = preload("res://scripts/arcade/dialogue_overlay.gd")
const DialogueOverlayScene = preload("res://scenes/dialogue_overlay.tscn")

const BossUnitZeroScript = preload("res://scripts/characters/boss_unit_zero.gd")
const FighterFactoryScript = preload("res://scripts/characters/fighter_factory.gd")
const AIControllerScript = preload("res://scripts/ai/ai_controller.gd")

const ArcadeLadderManagerScript = preload("res://scripts/arcade/arcade_ladder_manager.gd")
const ArcadeLadderModeScene = preload("res://scenes/arcade_ladder_mode.tscn")

const ArcadeEndingScript = preload("res://scripts/arcade/arcade_ending.gd")
const ArcadeEndingScene = preload("res://scenes/arcade_ending.tscn")
const RecordsManagerScript = preload("res://scripts/core/records_manager.gd")

var log_file: FileAccess = null
var _failed: bool = false

func _log(msg: String) -> void:
	print(msg)
	if log_file:
		log_file.store_line(msg)
		log_file.flush()

func _check(cond: bool, msg: String) -> void:
	if not cond:
		_failed = true
		_log("   [FAIL] " + msg)

func _ready() -> void:
	var out_path: String = ProjectSettings.globalize_path("res://test_arcade_ladder_results.txt")
	log_file = FileAccess.open(out_path, FileAccess.WRITE)
	_log("==================================================")
	_log("[TEST RUNNER] Memulai pengujian Epic 15: Arcade Ladder & Boss Gauntlet...")
	_log("==================================================")

	var tests: Array[Callable] = [
		_test_dialogue_db_matchups_and_epilogues,
		_test_dialogue_overlay_interaction,
		_test_boss_unit_zero_stats_and_overclock,
		_test_ai_nightmare_difficulty_profile,
		_test_arcade_ladder_progression_pipeline,
		_test_arcade_ending_rank_and_records
	]

	var passed: int = 0
	for t in tests:
		_failed = false
		_log("\n--- %s ---" % t.get_method())
		t.call()
		if _failed:
			_log(" [GAGAL]")
		else:
			passed += 1
			_log(" [LULUS]")

	_log("\n==================================================")
	_log("HASIL: %d/%d pengujian lulus." % [passed, tests.size()])
	_log("==================================================")
	get_tree().quit(0 if passed == tests.size() else 1)

func _test_dialogue_db_matchups_and_epilogues() -> void:
	# Test Clash Dialogues
	var clash_vb := DialogueDBScript.get_matchup_intro(&"viper", &"bulwark")
	_check(clash_vb["p1"].contains("blade strike"), "Viper vs Bulwark intro P1 valid: '%s'" % clash_vb["p1"])
	_check(clash_vb["p2"].contains("fancy chrome"), "Viper vs Bulwark intro P2 valid: '%s'" % clash_vb["p2"])

	# Test Final Boss Dialogue
	var clash_boss := DialogueDBScript.get_matchup_intro(&"viper", &"unit_zero")
	_check(clash_boss["p1"].contains("Absolute Zero Protocol"), "Viper vs Unit-0 intro P1 valid.")
	_check(clash_boss["p2"].contains("ERROR 000"), "Unit-0 Boss intro valid: '%s'" % clash_boss["p2"])

	# Test Victory Quotes
	var vic_viper := DialogueDBScript.get_random_victory_quote(&"viper")
	_check(vic_viper.length() > 0, "Victory quote Viper tersedia: '%s'" % vic_viper)

	var vic_kage := DialogueDBScript.get_random_victory_quote(&"kage")
	_check(vic_kage.length() > 0, "Victory quote Kage tersedia: '%s'" % vic_kage)

	# Test Epilogues
	for char_id in [&"viper", &"bulwark", &"pulsar", &"kage"]:
		var epilogue := DialogueDBScript.get_epilogue(char_id)
		_check(epilogue["headline"].length() > 0, "Epilogue headline untuk %s tersedia." % char_id)
		_check(epilogue["body"].length() > 30, "Epilogue body untuk %s memiliki narasi mendalam." % char_id)

func _test_dialogue_overlay_interaction() -> void:
	var overlay = DialogueOverlayScene.instantiate() as Control
	add_child(overlay)
	_check(overlay != null, "Scene dialogue_overlay.tscn berhasil diinstansiasi.")

	# Test start clash
	overlay.start_clash_dialogue(&"viper", &"unit_zero")
	_check(overlay.visible == true, "DialogueOverlay tampak pada layar saat dipanggil.")
	_check(overlay.clash_panel.visible == true, "ClashPanel aktif.")
	_check(overlay.p1_name.text.contains("VIPER"), "P1 Name label memuat nama petarung.")
	_check(overlay.p2_name.text.contains("UNIT-0"), "P2 Name label memuat nama Boss.")

	# Advance / skip typing
	overlay.advance_or_skip()
	_check(overlay.p1_dialogue.text.contains("Absolute Zero"), "Typer effect selesai saat di-skip.")

	# Close
	overlay.advance_or_skip()
	_check(overlay.visible == false, "DialogueOverlay tertutup setelah percakapan selesai.")

	overlay.queue_free()

func _test_boss_unit_zero_stats_and_overclock() -> void:
	var boss = FighterFactoryScript.create_fighter(&"unit_zero", 2)
	add_child(boss)

	_check(boss != null, "BossUnitZero berhasil dibuat via FighterFactory.")
	_check(boss.get_script() == BossUnitZeroScript, "Instance menggunakan script BossUnitZeroScript.")
	_check(boss.max_hp == 1500, "BossUnitZero memiliki Max HP 1500 (Hasil: %d)." % boss.max_hp)
	_check(boss.current_hp == 1500, "BossUnitZero memiliki Current HP 1500.")
	_check(boss.passive_damage_reduction == 0.10, "BossUnitZero memiliki -10% passive boss armor.")
	_check(boss.get_archetype() == &"unit_zero", "Archetype ID adalah &\"unit_zero\".")
	_check(boss.get_dash_speed() == 880.0, "Kecepatan dash Boss mencapai 880 px/s.")

	# Verifikasi status Overclock permanen
	_check(is_equal_approx(boss.heat_gauge, 90.0), "Heat gauge Boss terkunci pada 90.0% (Overclock Zone).")

	# Verifikasi resource jurus khas
	_check(boss.attack_resources.has(&"Skill1"), "Boss memiliki Skill1 (Cataclysm Slash).")
	_check(boss.attack_resources.has(&"Skill2"), "Boss memiliki Skill2 (Shadow Shockwave).")
	_check(boss.attack_resources.has(&"Ultimate"), "Boss memiliki Ultimate (Zero Overload Core Rupture).")

	boss.queue_free()

func _test_ai_nightmare_difficulty_profile() -> void:
	var ai := AIControllerScript.new()
	add_child(ai)

	ai.set_difficulty(AIControllerScript.Difficulty.NIGHTMARE)
	_check(ai.reaction_delay_frames == 3, "Nightmare AI memiliki reaksi 3 frame (Hasil: %d)." % ai.reaction_delay_frames)
	_check(ai.parry_chance >= 0.90, "Nightmare AI memiliki peluang parry presisi >= 90%% (Hasil: %.2f)." % ai.parry_chance)
	_check(ai.combo_extension_chance == 1.0, "Nightmare AI memiliki 100%% kombo ekstensi optimal.")
	_check(ai.aggression >= 0.95, "Nightmare AI memiliki tingkat agresi puncak >= 0.95 (Hasil: %.2f)." % ai.aggression)
	_check(ai.overclock_focus == true, "Nightmare AI mengaktifkan overclock focus.")

	ai.queue_free()

func _test_arcade_ladder_progression_pipeline() -> void:
	var arcade = ArcadeLadderModeScene.instantiate() as Node2D
	add_child(arcade)

	_check(arcade != null, "Scene arcade_ladder_mode.tscn berhasil diinstansiasi.")
	_check(arcade.TOTAL_STAGES == 4, "Total stages terkonfigurasi tepat 4 stages.")
	_check(arcade.stages_data.size() == 4, "Pipeline stages_data memiliki 4 entri.")

	# Cek stage 1 s/d 3 eskalasi
	_check(arcade.stages_data[0]["difficulty"] == AIControllerScript.Difficulty.NOVICE, "Stage 1 berstatus NOVICE.")
	_check(arcade.stages_data[1]["difficulty"] == AIControllerScript.Difficulty.VETERAN, "Stage 2 berstatus VETERAN.")
	_check(arcade.stages_data[2]["difficulty"] == AIControllerScript.Difficulty.ACE, "Stage 3 berstatus ACE.")

	# Cek stage 4 final boss
	var stage4 = arcade.stages_data[3]
	_check(stage4["opponent"] == &"unit_zero", "Lawan Stage 4 adalah Boss &\"unit_zero\".")
	_check(stage4["difficulty"] == AIControllerScript.Difficulty.NIGHTMARE, "Kesulitan Boss Stage 4 adalah NIGHTMARE.")

	arcade.queue_free()

func _test_arcade_ending_rank_and_records() -> void:
	# 1. Test evaluasi peringkat
	var rank_s := ArcadeEndingScript.evaluate_run(190.0, 0, 5, 2)
	_check(rank_s["rank"] == "S", "Run tanpa continue < 240s dengan 5 parry menghasilkan Rank S.")
	_check(rank_s["score"] > 1000000, "Skor Rank S melebihi 1,000,000 PTS (Hasil: %d)." % rank_s["score"])

	var rank_a := ArcadeEndingScript.evaluate_run(300.0, 1, 3, 1)
	_check(rank_a["rank"] == "A", "Run 1 continue < 360s menghasilkan Rank A.")

	var rank_b := ArcadeEndingScript.evaluate_run(400.0, 2, 2, 0)
	_check(rank_b["rank"] == "B", "Run 2 continue menghasilkan Rank B.")

	var rank_c := ArcadeEndingScript.evaluate_run(450.0, 4, 1, 0)
	_check(rank_c["rank"] == "C", "Run >= 3 continue menghasilkan Rank C.")

	# 2. Test integrasi scene dan RecordsManager
	var ending = ArcadeEndingScene.instantiate() as Control
	add_child(ending)

	ending.display_run_results({
		"character": &"viper",
		"clear_time": 200.0,
		"continues": 0,
		"parries": 6,
		"ring_outs": 2
	})

	_check(ending.rank_label.text == "S", "Ending scene menampilkan rank 'S'.")
	_check(ending.epilogue_headline.text.contains("ABSOLUTE ZERO"), "Ending scene menampilkan epilog headline Viper.")

	var rec := RecordsManagerScript.get_instance()
	_check(rec.get_stat("arcade_clears", 0) >= 1, "Statistik 'arcade_clears' bertambah di RecordsManager.")
	_check(rec.get_stat("arcade_best_rank", "-") == "S", "Statistik 'arcade_best_rank' mencatat peringkat 'S'.")

	ending.queue_free()
