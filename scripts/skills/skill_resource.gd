extends Resource
class_name SkillResource

@export var id: String = ""
@export var display_name: String = ""

enum Type { ACTIVE, PASSIVE }
@export var type: Type = Type.ACTIVE

@export var cooldown: float = 5.0
@export var description: String = ""

# 效果参数
@export var damage_mult: float = 1.0
@export var range: float = 150.0
@export var shape: String = "line"  # line, circle, cone
@export var pierce: bool = false

# 被动专用
enum PassiveTrigger { INTERVAL, ON_KILL, ALWAYS }
@export var passive_trigger: PassiveTrigger = PassiveTrigger.INTERVAL
@export var trigger_interval: float = 15.0
@export var buff_type: String = ""  # "invincible", "heal", "speed"
@export var buff_value: float = 0.0
@export var buff_duration: float = 3.0
