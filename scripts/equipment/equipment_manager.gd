extends Node
class_name EquipmentManager

static var instance: EquipmentManager
signal equipment_changed

var weapon_slot: EquipmentResource = null
var armor_slot: EquipmentResource = null
var accessory_slot: EquipmentResource = null

func _ready() -> void:
	instance = self

func equip(item: EquipmentResource) -> void:
	match item.slot:
		EquipmentResource.Slot.WEAPON:
			weapon_slot = item
		EquipmentResource.Slot.ARMOR:
			armor_slot = item
		EquipmentResource.Slot.ACCESSORY:
			accessory_slot = item
	equipment_changed.emit()

func get_total_attack() -> float:
	var total: float = 10.0
	if weapon_slot: total += weapon_slot.attack
	if accessory_slot: total += accessory_slot.attack
	return total

func get_total_health() -> float:
	var total: float = 100.0
	if armor_slot: total += armor_slot.health
	if accessory_slot: total += accessory_slot.health
	return total

func get_total_defense() -> float:
	var total: float = 0.0
	if armor_slot: total += armor_slot.defense
	return total

func get_attack_type() -> int:
	if weapon_slot:
		return weapon_slot.attack_type
	return EquipmentResource.AttackType.MELEE_ARC

func get_attack_range() -> float:
	if weapon_slot:
		return weapon_slot.attack_range
	return 80.0

func get_attack_speed() -> float:
	if weapon_slot:
		return weapon_slot.attack_speed
	return 1.0
