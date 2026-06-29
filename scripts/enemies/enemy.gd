extends CharacterBody2D
class_name Enemy

signal died(drop_exp: int)

@export var max_health: float = 30.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var exp_drop: int = 10
@export var resource: EnemyResource = null

var current_health: float
var attack_timer: float = 0.0
var player_ref: Player = null

# 精灵动画
var _anim_frame: int = 0
var _anim_timer: float = 0.0
var _anim_speed: float = 0.15
var _facing_row: int = 0
const FRAME_W: int = 48
const FRAME_H: int = 48

func _ready() -> void:
	if resource:
		max_health = resource.max_health
		move_speed = resource.move_speed
		damage = resource.damage
		exp_drop = resource.exp_drop
		if resource.is_elite:
			scale = Vector2.ONE * resource.scale_mult
			max_health *= 3.0
			exp_drop *= 3
		elif resource.is_boss:
			scale = Vector2.ONE * resource.scale_mult
			max_health *= 10.0
			exp_drop *= 10

	current_health = max_health

	# Boss 有头顶血条
	if resource and resource.is_boss:
		var bar: ProgressBar = ProgressBar.new()
		bar.max_value = max_health
		bar.value = current_health
		bar.size = Vector2(40, 6)
		bar.position = Vector2(-20, -30)
		add_child(bar)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player_ref):
		return

	# 追踪玩家
	var dir: Vector2 = (player_ref.global_position - global_position).normalized()
	velocity = dir * move_speed
	move_and_slide()

	# 精灵方向（朝玩家方向）
	if abs(dir.x) > abs(dir.y):
		_facing_row = 2 if dir.x > 0.3 else 1  # 右 / 左
	else:
		_facing_row = 3 if dir.y < -0.3 else 0  # 后 / 前

	# 动画帧
	_anim_timer -= delta
	if _anim_timer <= 0.0:
		_anim_timer = _anim_speed
		_anim_frame = (_anim_frame + 1) % 3

	$Sprite2D.region_rect = Rect2(_anim_frame * FRAME_W, _facing_row * FRAME_H, FRAME_W, FRAME_H)

	# 碰撞攻击玩家
	attack_timer -= delta
	if attack_timer <= 0.0:
		for i in get_slide_collision_count():
			var col: KinematicCollision2D = get_slide_collision(i)
			if col.get_collider() is Player:
				col.get_collider().take_damage(damage)
				attack_timer = attack_cooldown
				break

func set_player(p: Player) -> void:
	player_ref = p

func take_damage(amount: float) -> void:
	current_health -= amount

	# 受伤闪烁
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if is_instance_valid(self):
		modulate = Color.WHITE

	if current_health <= 0:
		die()

func die() -> void:
	died.emit(exp_drop)
	queue_free()
