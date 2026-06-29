extends Area2D
class_name Projectile

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 3.0
var pierce: bool = false
var hit_enemies: Array[Enemy] = []
var _age: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age > lifetime:
		_return_to_pool()

func launch(from: Vector2, direction: Vector2, speed: float, dmg: float, do_pierce: bool = false) -> void:
	global_position = from
	velocity = direction.normalized() * speed
	damage = dmg
	pierce = do_pierce
	hit_enemies.clear()
	_age = 0.0
	set_deferred("monitoring", true)
	visible = true

func _on_body_entered(body: Node2D) -> void:
	if body is Enemy:
		if pierce and body in hit_enemies:
			return
		body.take_damage(damage)
		hit_enemies.append(body)
		if not pierce:
			_return_to_pool()

func _return_to_pool() -> void:
	set_deferred("monitoring", false)
	visible = false
	if ProjectilePool.instance:
		ProjectilePool.instance.return_to_pool(self)
