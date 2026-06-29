extends Node
class_name EnemySpawner

signal all_enemies_defeated

@export var enemy_scene: PackedScene
@export var spawn_margin: float = 300.0
@export var max_enemies: int = 30

var player_ref: Player = null
var alive_enemies: Array[Enemy] = []
var enemies_to_spawn: int = 0
var spawn_interval: float = 1.0
var spawn_timer: float = 0.0
var spawn_queue: Array[PackedScene] = []

func _process(delta: float) -> void:
	if spawn_queue.is_empty() and alive_enemies.is_empty() and enemies_to_spawn <= 0:
		all_enemies_defeated.emit()
		return

	spawn_timer -= delta
	if spawn_timer <= 0.0 and not spawn_queue.is_empty():
		_spawn_one(spawn_queue.pop_front())
		spawn_timer = spawn_interval

func set_player(p: Player) -> void:
	player_ref = p

func start_wave(enemy_configs: Array[Dictionary], interval: float) -> void:
	spawn_interval = interval
	enemies_to_spawn = 0
	spawn_queue.clear()

	for config in enemy_configs:
		for i in range(config.count):
			spawn_queue.append(config.scene)
			enemies_to_spawn += 1

	spawn_queue.shuffle()
	spawn_timer = 0.5

func _spawn_one(scene: PackedScene) -> void:
	if alive_enemies.size() >= max_enemies:
		spawn_queue.push_front(scene)
		spawn_timer = 1.0
		return

	var enemy: Enemy = scene.instantiate()
	enemy.set_player(player_ref)
	enemy.died.connect(func(exp): _on_enemy_died(enemy, exp))

	var angle: float = randf_range(0, TAU)
	var dist: float = randf_range(spawn_margin, spawn_margin + 200)
	if player_ref:
		enemy.global_position = player_ref.global_position + Vector2.from_angle(angle) * dist
	get_parent().add_child(enemy)
	alive_enemies.append(enemy)

func _on_enemy_died(enemy: Enemy, exp: int) -> void:
	alive_enemies.erase(enemy)
	enemies_to_spawn -= 1
	# 给玩家经验
	if player_ref:
		player_ref.gain_exp(exp)
