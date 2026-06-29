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

# 精灵动画
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _anim_speed: float = 0.12
var _facing_row: int = 0  # 0=前 1=左 2=右 3=后
const FRAME_W: int = 48
const FRAME_H: int = 48

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

	# 精灵方向（不旋转，改切 spritesheet 行）
	if abs(velocity.x) > abs(velocity.y):
		_facing_row = 2 if velocity.x > 10 else 1  # 右 / 左
	else:
		_facing_row = 3 if velocity.y < -10 else 0  # 后 / 前

	# 动画帧更新
	var is_moving: bool = velocity.length_squared() > 1.0
	if is_moving:
		_anim_timer -= delta
		if _anim_timer <= 0.0:
			_anim_timer = _anim_speed
			_anim_frame = (_anim_frame + 1) % 3
	else:
		_anim_frame = 1  # 站立时用中间帧
		_anim_timer = 0.0

	$Sprite2D.region_rect = Rect2(_anim_frame * FRAME_W, _facing_row * FRAME_H, FRAME_W, FRAME_H)

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
			var forward: Vector2 = _get_facing_direction()
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
	# 死亡前刷新 HUD，确保显示归零
	if hud:
		hud.update_health(maxf(0, current_health), max_health)
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

func _get_facing_direction() -> Vector2:
	match _facing_row:
		0: return Vector2.DOWN
		1: return Vector2.LEFT
		2: return Vector2.RIGHT
		3: return Vector2.UP
	return Vector2.DOWN

func get_move_direction() -> Vector2:
	return _get_facing_direction()
