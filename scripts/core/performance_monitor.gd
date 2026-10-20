class_name PerformanceMonitor
extends Node

## Pengawas Kinerja & Audit Memori Real-Time 60 FPS (Story 6.4)
## Memantau konsumsi RAM, frame rate, dan kebocoran node untuk memastikan standar turnamen e-sports

const MAX_SAFE_MEMORY_MB: float = 600.0
const TARGET_FPS: int = 60

func _ready() -> void:
	lock_engine_60_fps()

## Mengunci konfigurasi deterministik 60 FPS Engine & Fisika
static func lock_engine_60_fps() -> void:
	Engine.max_fps = TARGET_FPS
	Engine.physics_ticks_per_second = TARGET_FPS

## Mendapatkan penggunaan memori statis dalam MegaByte (MB)
static func get_memory_usage_mb() -> float:
	var bytes: int = Performance.get_monitor(Performance.MEMORY_STATIC)
	return float(bytes) / (1024.0 * 1024.0)

## Mendapatkan FPS rata-rata saat ini
static func get_fps() -> float:
	return Performance.get_monitor(Performance.TIME_FPS)

## Mendapatkan jumlah node yatim piatu (orphan nodes / potensi leak)
static func get_orphan_count() -> int:
	return Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)

## Mendapatkan total node yang aktif di SceneTree
static func get_node_count() -> int:
	return Performance.get_monitor(Performance.OBJECT_NODE_COUNT)

## Memvalidasi apakah penggunaan memori berada di bawah batas aman 600 MB
static func is_memory_healthy() -> bool:
	return get_memory_usage_mb() < MAX_SAFE_MEMORY_MB

## Menghasilkan ringkasan laporan diagnostik performa
static func get_diagnostic_report() -> Dictionary:
	return {
		"fps": get_fps(),
		"memory_mb": get_memory_usage_mb(),
		"is_healthy": is_memory_healthy(),
		"orphan_nodes": get_orphan_count(),
		"total_nodes": get_node_count(),
		"max_fps_setting": Engine.max_fps,
		"physics_ticks": Engine.physics_ticks_per_second
	}
