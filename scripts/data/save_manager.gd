extends Node

var copper_coins: int = 0
var cultivation: int = 0
var owned_equipment_ids: Array[String] = []
var equipped_weapon_id: String = ""
var equipped_armor_id: String = ""
var equipped_accessory_id: String = ""

const SAVE_PATH: String = "user://save_data.json"

func _ready() -> void:
	load_game()

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var data = JSON.parse_string(text)
	if data == null:
		return
	copper_coins = data.get("copper_coins", 0)
	cultivation = data.get("cultivation", 0)
	owned_equipment_ids.assign(data.get("owned_equipment_ids", []))
	equipped_weapon_id = data.get("equipped_weapon_id", "")
	equipped_armor_id = data.get("equipped_armor_id", "")
	equipped_accessory_id = data.get("equipped_accessory_id", "")

func save_game() -> void:
	var data: Dictionary = {
		"copper_coins": copper_coins,
		"cultivation": cultivation,
		"owned_equipment_ids": owned_equipment_ids,
		"equipped_weapon_id": equipped_weapon_id,
		"equipped_armor_id": equipped_armor_id,
		"equipped_accessory_id": equipped_accessory_id,
	}
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func add_reward(coins: int, cult: int) -> void:
	copper_coins += coins
	cultivation += cult
	save_game()
