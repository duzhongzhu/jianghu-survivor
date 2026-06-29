extends Node
class_name ProjectilePool

static var instance: ProjectilePool

@export var projectile_scene: PackedScene
var _pool: Array[Projectile] = []
var _pool_size: int = 50

func _ready() -> void:
	instance = self
	for i in range(_pool_size):
		var p: Projectile = projectile_scene.instantiate()
		p.monitoring = false
		p.visible = false
		add_child(p)
		_pool.append(p)

static func request() -> Projectile:
	if not instance:
		return null
	for p in instance._pool:
		if not p.monitoring:
			return p
	# 池满则扩展
	var new_p: Projectile = instance.projectile_scene.instantiate()
	instance.add_child(new_p)
	instance._pool.append(new_p)
	return new_p

func return_to_pool(p: Projectile) -> void:
	p.monitoring = false
	p.visible = false
	p.velocity = Vector2.ZERO
