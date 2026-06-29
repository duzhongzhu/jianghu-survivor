extends GutTest

func test_equip_weapon() -> void:
	var mgr: EquipmentManager = autofree(EquipmentManager.new())
	var sword: EquipmentResource = EquipmentResource.new()
	sword.id = "test_sword"
	sword.slot = EquipmentResource.Slot.WEAPON
	sword.attack = 15.0
	mgr.equip(sword)
	assert_eq(mgr.get_total_attack(), 25.0)  # 10 base + 15

func test_unequipped_defaults() -> void:
	var mgr: EquipmentManager = autofree(EquipmentManager.new())
	assert_eq(mgr.get_total_attack(), 10.0)
	assert_eq(mgr.get_total_health(), 100.0)
	assert_eq(mgr.get_attack_type(), EquipmentResource.AttackType.MELEE_ARC)
