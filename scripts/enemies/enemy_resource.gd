extends Resource
class_name EnemyResource

@export var id: String = ""
@export var display_name: String = ""
@export var max_health: float = 30.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var exp_drop: int = 10
@export var behavior: String = "chase"  # chase, dash, ranged, shield
@export var dash_speed: float = 300.0
@export var dash_interval: float = 3.0
@export var shield_duration: float = 4.0
@export var shield_interval: float = 10.0
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var scale_mult: float = 1.0
