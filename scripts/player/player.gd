extends CharacterBody2D
class_name Player

signal leveled_up(new_level: int)
signal player_died

@export var move_speed: float = 200.0
@export var attack_range: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0
@export var max_health: float = 100.0

var current_health: float
var enemies_in_range: Array[Node2D] = []
var nearest_enemy: Node2D = null
var attack_timer: float = 0.0

# 经验系统
var current_exp: int = 0
var exp_to_next_level: int = 20
var level: int = 1

# 引用
var equipment_manager = null
var skill_manager = null
var hud = null

func _ready() -> void:
	current_health = max_health
	$AttackRange.body_entered.connect(_on_enemy_entered_range)
	$AttackRange.body_exited.connect(_on_enemy_exited_range)
	($AttackRange/CollisionShape2D as CollisionShape2D).shape.radius = attack_range

func _physics_process(delta: float) -> void:
	# 移动
	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_dir * move_speed
	move_and_slide()

	# 面朝方向
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle()

	# 自动普攻
	_update_nearest_enemy()
	attack_timer -= delta
	if attack_timer <= 0.0 and nearest_enemy:
		_attack()

	# 更新 HUD
	if hud:
		hud.update_health(current_health, max_health)
		hud.update_exp(current_exp, exp_to_next_level)

func _on_enemy_entered_range(body: Node2D) -> void:
	if not body in enemies_in_range:
		enemies_in_range.append(body)

func _on_enemy_exited_range(body: Node2D) -> void:
	enemies_in_range.erase(body)

func _update_nearest_enemy() -> void:
	enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
	nearest_enemy = null
	var min_dist: float = INF
	for enemy in enemies_in_range:
		var dist: float = global_position.distance_squared_to(enemy.global_position)
		if dist < min_dist:
			min_dist = dist
			nearest_enemy = enemy

func _attack() -> void:
	if not is_instance_valid(nearest_enemy):
		return

	var atk_spd: float = attack_speed
	var atk_dmg: float = attack_damage

	if equipment_manager:
		atk_spd = equipment_manager.get_attack_speed()
		atk_dmg = equipment_manager.get_total_attack()

	attack_timer = 1.0 / atk_spd

	var atk_type: int = 0  # MELEE_ARC default
	if equipment_manager:
		atk_type = equipment_manager.get_attack_type()

	match atk_type:
		0: _perform_melee_arc()
		1: _perform_melee_circle()
		2: _perform_ranged_single()
		3: _perform_ranged_cone()
		4: _perform_ranged_aoe()

func _perform_melee_arc() -> void:
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			var to_enemy: Vector2 = enemy.global_position - global_position
			var forward: Vector2 = Vector2.RIGHT.rotated(rotation)
			if to_enemy.normalized().dot(forward) > cos(deg_to_rad(60)):
				enemy.take_damage(attack_damage)

func _perform_melee_circle() -> void:
	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			enemy.take_damage(attack_damage * 0.7)

func _perform_ranged_single() -> void:
	var p: Projectile = ProjectilePool.request()
	var dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
	p.launch(global_position, dir, 300.0, attack_damage, false)

func _perform_ranged_cone() -> void:
	for i in range(3):
		var p: Projectile = ProjectilePool.request()
		var base_dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
		var spread: float = -0.2 + i * 0.2
		p.launch(global_position, base_dir.rotated(spread), 300.0, attack_damage * 0.6, false)

func _perform_ranged_aoe() -> void:
	var p: Projectile = ProjectilePool.request()
	var dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
	p.launch(global_position, dir, 200.0, attack_damage * 1.5, true)

func gain_exp(amount: int) -> void:
	current_exp += amount
	while current_exp >= exp_to_next_level:
		current_exp -= exp_to_next_level
		level += 1
		exp_to_next_level = int(exp_to_next_level * 1.2)
		leveled_up.emit(level)

func take_damage(amount: float) -> void:
	# 应用防御减伤
	var defense: float = 0.0
	if equipment_manager:
		defense = equipment_manager.get_total_defense()
	var actual_damage: float = maxf(1.0, amount - defense * 0.5)
	current_health -= actual_damage
	if current_health <= 0:
		die()

func heal(amount: float) -> void:
	current_health = minf(max_health, current_health + amount)

func set_invincible(duration: float) -> void:
	set_collision_layer_value(1, false)
	await get_tree().create_timer(duration).timeout
	set_collision_layer_value(1, true)

func die() -> void:
	$CollisionShape2D.set_deferred("disabled", true)
	player_died.emit()
	get_tree().paused = true

func get_move_direction() -> Vector2:
	return velocity.normalized() if velocity.length_squared() > 1.0 else Vector2.RIGHT
