extends Control
class_name UpgradePopup

signal upgrade_chosen(option_data: Dictionary)

var _options: Array[Dictionary] = []
var _skill_manager = null
var _player = null

func show_options(options: Array[Dictionary], sm, p) -> void:
	_options = options
	_skill_manager = sm
	_player = p
	visible = true
	get_tree().paused = true

	for i in range(3):
		var opt_container = $OptionsContainer.get_child(i)
		if not opt_container:
			continue
		var btn: Button = opt_container.get_node("Button")
		var label: Label = opt_container.get_node("Label")
		if i < options.size():
			btn.text = options[i].name
			label.text = options[i].description
			btn.visible = true
			btn.disabled = false
			# 断开之前的连接再重新连接
			if btn.pressed.is_connected(_on_chosen):
				btn.pressed.disconnect(_on_chosen)
			btn.pressed.connect(func(): _on_chosen(i), CONNECT_ONE_SHOT)
		else:
			btn.visible = false

func _on_chosen(index: int) -> void:
	if index >= _options.size():
		return
	visible = false
	get_tree().paused = false

	var choice: Dictionary = _options[index]
	match choice.type:
		"new_skill", "new_passive":
			if _skill_manager:
				# 加载技能 resource 并添加
				var skill_path: String = "res://resource/skills/%s.tres" % choice.id
				if ResourceLoader.exists(skill_path):
					var skill = ResourceLoader.load(skill_path)
					_skill_manager.add_skill(skill)
		"stat":
			match choice.stat:
				"attack":
					if _player:
						_player.attack_damage *= (1.0 + choice.value)
				"health":
					if _player:
						_player.max_health *= (1.0 + choice.value)
						_player.current_health = _player.max_health
				"speed":
					if _player:
						_player.move_speed *= (1.0 + choice.value)

	upgrade_chosen.emit(choice)

func _generate_random_options(player_level: int, owned_skill_ids: Array[String]) -> Array[Dictionary]:
	var pool: Array[Dictionary] = []

	# 新技能
	pool.append({"name": "剑气斩", "description": "向前方释放剑气 (新技能)", "type": "new_skill", "id": "sword_wave"})
	pool.append({"name": "影步", "description": "向移动方向闪现 (新技能)", "type": "new_skill", "id": "shadow_step"})
	pool.append({"name": "金钟罩", "description": "每15秒获得3秒无敌 (新被动)", "type": "new_passive", "id": "golden_body"})
	pool.append({"name": "嗜血", "description": "击杀回复5%生命 (新被动)", "type": "new_passive", "id": "bloodthirst"})

	# 属性提升
	pool.append({"name": "功力+10%", "description": "提升10%攻击力", "type": "stat", "stat": "attack", "value": 0.1})
	pool.append({"name": "体魄+15%", "description": "提升15%最大生命", "type": "stat", "stat": "health", "value": 0.15})
	pool.append({"name": "轻功+5%", "description": "提升5%移动速度", "type": "stat", "stat": "speed", "value": 0.05})

	pool.shuffle()
	return pool.slice(0, 3)
