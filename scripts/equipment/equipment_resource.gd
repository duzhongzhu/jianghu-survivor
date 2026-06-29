extends Resource
class_name EquipmentResource

@export var id: String = ""
@export var display_name: String = ""

enum Slot { WEAPON, ARMOR, ACCESSORY }
@export var slot: Slot = Slot.WEAPON

@export var attack: float = 0.0
@export var health: float = 0.0
@export var defense: float = 0.0
@export var speed_mod: float = 0.0
@export var attack_range: float = 80.0
@export var attack_speed: float = 1.0

enum AttackType { MELEE_ARC, MELEE_CIRCLE, RANGED_SINGLE, RANGED_CONE, RANGED_AOE }
@export var attack_type: AttackType = AttackType.MELEE_ARC
@export var price: int = 100
@export var description: String = ""
