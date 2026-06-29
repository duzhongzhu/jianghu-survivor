extends Node
class_name WaveController

static var instance: WaveController

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal between_waves(seconds_left: float)

@export var spawner: EnemySpawner
@export var base_enemy_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var boss_enemy_scene: PackedScene

var current_wave: int = 0
var wave_active: bool = false
var break_timer: float = 0.0
var break_duration: float = 8.0
var _started: bool = false

func _ready() -> void:
	instance = self
	if spawner:
		spawner.all_enemies_defeated.connect(_on_all_enemies_defeated)

func start_first_wave() -> void:
	if _started:
		return
	_started = true
	start_next_wave()

func start_next_wave() -> void:
	current_wave += 1
	wave_active = true
	wave_started.emit(current_wave)

	var configs: Array[Dictionary] = _generate_wave_config(current_wave)
	var interval: float = maxf(0.3, 1.0 - current_wave * 0.05)
	spawner.start_wave(configs, interval)

func _on_all_enemies_defeated() -> void:
	if not wave_active:
		return
	wave_active = false
	wave_cleared.emit(current_wave)
	break_timer = break_duration

func _process(delta: float) -> void:
	if break_timer > 0.0 and not wave_active:
		break_timer -= delta
		between_waves.emit(break_timer)
		if break_timer <= 0.0:
			start_next_wave()

func _generate_wave_config(wave: int) -> Array[Dictionary]:
	var configs: Array[Dictionary] = []
	var total_count: int = _calculate_total_enemies(wave)

	if wave % 10 == 0 and boss_enemy_scene:
		configs.append({"scene": boss_enemy_scene, "count": 1})
		total_count -= 1
	elif wave % 5 == 0 and elite_enemy_scene:
		configs.append({"scene": elite_enemy_scene, "count": 3})
		total_count -= 3

	configs.append({"scene": base_enemy_scene, "count": maxi(0, total_count)})
	return configs

func _calculate_total_enemies(wave: int) -> int:
	return 5 + wave * 3

func _get_health_multiplier(wave: int) -> float:
	return 1.0 + wave * 0.1

func _get_damage_multiplier(wave: int) -> float:
	return 1.0 + wave * 0.08
