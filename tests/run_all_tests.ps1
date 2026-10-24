# Master Test Runner for Fighting to Zero
# Runs all 25 automated test suites across Epic 1 through Epic 6 headless

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectPath = (Resolve-Path "$scriptDir\..").Path
$godotPath = Join-Path $projectPath ".godot_bin\Godot_v4.7.2-stable_win64_console.exe"

$testScenes = @(
    # Epic 1: Core Physics & Combat Mechanics
    "res://tests/test_movement_fsm.tscn",
    "res://tests/test_input_buffer_coyote.tscn",
    "res://tests/test_vector_dash.tscn",
    "res://tests/test_combat_attacks.tscn",
    # Epic 2: Heat System & Defensive Mechanics
    "res://tests/test_heat_component.tscn",
    "res://tests/test_overclock_meltdown.tscn",
    "res://tests/test_blocking_chip.tscn",
    "res://tests/test_spark_parry.tscn",
    # Epic 3: Mecha Archetypes & Roster Implementation
    "res://tests/test_attack_chain_scaling.tscn",
    "res://tests/test_apex_viper.tscn",
    "res://tests/test_titan_bulwark.tscn",
    "res://tests/test_dual_input_system.tscn",
    # Epic 4: Arena, Cliffhanger & Stage Hazards
    "res://tests/test_arena_skyscraper.tscn",
    "res://tests/test_cliffhanger_system.tscn",
    "res://tests/test_ledge_stomp_ring_out.tscn",
    "res://tests/test_match_rules.tscn",
    # Epic 5: Game Modes, UI & Artificial Intelligence
    "res://tests/test_combat_hud.tscn",
    "res://tests/test_main_menu.tscn",
    "res://tests/test_local_versus.tscn",
    "res://tests/test_versus_ai.tscn",
    "res://tests/test_training_mode.tscn",
    # Epic 6: Visual Juice, Sound Effects & Final Polish
    "res://tests/test_hitstop_screen_shake.tscn",
    "res://tests/test_pixel_vfx.tscn",
    "res://tests/test_audio_system.tscn",
    "res://tests/test_performance_stress.tscn",
    # Epic 7: 32-Bit Pixel Character Sprites & Animation Integration
    "res://tests/test_pixel_sprites_visual.tscn",
    "res://tests/test_ghost_trail_and_stage_vfx.tscn",
    # Epic 8: Cyberpunk OST & Mecha Combat Audio Immersion
    "res://tests/test_synthwave_ost.tscn",
    "res://tests/test_mecha_combat_sfx.tscn",
    # Epic 10: Playable 3rd Mecha Roster - Ray-X Pulsar
    "res://tests/test_ray_pulsar.tscn",
    # Epic 11: Character Select Screen & Roster Selection System
    "res://tests/test_character_select.tscn",
    # Epic 12: Underground Reactor Arena & Environmental Steam Hazards
    "res://tests/test_underground_reactor.tscn",
    # Epic 13: Playable 4th Mecha Roster - Phantom-9 Kage (Stance Switcher)
    "res://tests/test_phantom_kage.tscn",
    # Epic 14: Settings Modal, In-Match Pause System & Battle Records Persistence
    "res://tests/test_settings_and_records.tscn",
    # Epic 15: Arcade Ladder & Boss Gauntlet Mode
    "res://tests/test_arcade_ladder.tscn",
    # Skill VFX Diversity & Visual Impact Polish
    "res://tests/test_skill_vfx.tscn"
)

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host " [MASTER TEST RUNNER] FIGHTING TO ZERO (GODOT 4.7)       " -ForegroundColor Cyan
Write-Host " Total Test Suites to Execute: $($testScenes.Count)     " -ForegroundColor Cyan
Write-Host "==========================================================" -ForegroundColor Cyan

$passed = 0
$failed = 0
$failedSuites = @()

$index = 1
foreach ($scene in $testScenes) {
    Write-Host ("[{0:D2}/{1:D2}] Menjalankan {2}..." -f $index, $testScenes.Count, $scene) -NoNewline
    
    $proc = Start-Process -FilePath $godotPath -ArgumentList "--headless", "--path", $projectPath, $scene -Wait -NoNewWindow -PassThru
    
    if ($proc.ExitCode -eq 0) {
        Write-Host " [PASS]" -ForegroundColor Green
        $passed++
    } else {
        Write-Host (" [FAIL] (Exit Code: {0})" -f $proc.ExitCode) -ForegroundColor Red
        $failed++
        $failedSuites += $scene
    }
    $index++
}

Write-Host "==========================================================" -ForegroundColor Cyan
Write-Host (" HASIL AKHIR: {0}/{1} Test Suites LULUS" -f $passed, $testScenes.Count) -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Red" })
Write-Host "==========================================================" -ForegroundColor Cyan

if ($failed -gt 0) {
    Write-Host "Test Suites yang Gagal:" -ForegroundColor Red
    foreach ($f in $failedSuites) {
        Write-Host " - $f" -ForegroundColor Red
    }
    exit 1
} else {
    Write-Host ("SEMUA {0} TEST SUITES DARI EPIC 1 - 15 BERHASIL 100%!" -f $testScenes.Count) -ForegroundColor Green
    exit 0
}
