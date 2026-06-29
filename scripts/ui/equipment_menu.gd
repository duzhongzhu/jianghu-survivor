extends Control

var all_equipment: Array[EquipmentResource] = []

func _ready() -> void:
	_load_equipment_catalog()
	_refresh_ui()
	$BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _load_equipment_catalog() -> void:
	all_equipment.clear()
	var dir: DirAccess = DirAccess.open("res://resource/equipment/")
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res = load("res://resource/equipment/" + file_name)
			if res is EquipmentResource:
				all_equipment.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()

func _refresh_ui() -> void:
	var coins: int = 0
	var cult: int = 0
	if SaveManager:
		coins = SaveManager.copper_coins
		cult = SaveManager.cultivation
	$CopperLabel.text = "铜钱: %d  修为: %d" % [coins, cult]

	# 清空旧列表
	for child in $WeaponList.get_children():
		if child is Button:
			child.queue_free()

	# 按槽位显示装备
	for eq in all_equipment:
		var slot_container: VBoxContainer = null
		match eq.slot:
			EquipmentResource.Slot.WEAPON: slot_container = $WeaponList
			EquipmentResource.Slot.ARMOR: slot_container = $ArmorList
			EquipmentResource.Slot.ACCESSORY: slot_container = $AccessoryList

		if slot_container:
			var btn: Button = Button.new()
			btn.text = "%s - %d铜钱" % [eq.display_name, eq.price]
			btn.pressed.connect(func(): _buy_equipment(eq), CONNECT_ONE_SHOT)
			slot_container.add_child(btn)

func _buy_equipment(eq: EquipmentResource) -> void:
	if not SaveManager:
		return
	if SaveManager.copper_coins < eq.price:
		return
	SaveManager.copper_coins -= eq.price
	SaveManager.owned_equipment_ids.append(eq.id)
	SaveManager.save_game()
	# 如果是武器则装备
	if eq.slot == EquipmentResource.Slot.WEAPON:
		SaveManager.equipped_weapon_id = eq.id
	elif eq.slot == EquipmentResource.Slot.ARMOR:
		SaveManager.equipped_armor_id = eq.id
	elif eq.slot == EquipmentResource.Slot.ACCESSORY:
		SaveManager.equipped_accessory_id = eq.id
	_refresh_ui()
