extends Node2D

func _ready() -> void:
	# 初始化依赖注入
	$EnemySpawner.set_player($Player)
	$WaveController.spawner = $EnemySpawner
	$SkillManager.player_ref = $Player

	# Player 引用
	$Player.equipment_manager = $EquipmentManager
	$Player.skill_manager = $SkillManager
	$Player.hud = $HUD

	# 加载装备
	_load_equipped_gear()

	# 信号连接
	$Player.leveled_up.connect(_on_player_leveled_up)
	$Player.player_died.connect(_on_player_died)
	$WaveController.wave_started.connect(_on_wave_started)
	$WaveController.between_waves.connect(_on_between_waves)
	$WaveController.wave_cleared.connect(_on_wave_cleared)
	$HUD/UpgradePopup.upgrade_chosen.connect(_on_upgrade_chosen)

	# 技能输入处理
	_process_skill_input()

	# 开始第一波
	$WaveController.start_first_wave()

func _load_equipped_gear() -> void:
	var sm = SaveManager
	# 加载已装备的武器
	if sm.equipped_weapon_id != "":
		var path = "res://resource/equipment/%s.tres" % sm.equipped_weapon_id
		if ResourceLoader.exists(path):
			$EquipmentManager.equip(ResourceLoader.load(path))
	if sm.equipped_armor_id != "":
		var path = "res://resource/equipment/%s.tres" % sm.equipped_armor_id
		if ResourceLoader.exists(path):
			$EquipmentManager.equip(ResourceLoader.load(path))
	if sm.equipped_accessory_id != "":
		var path = "res://resource/equipment/%s.tres" % sm.equipped_accessory_id
		if ResourceLoader.exists(path):
			$EquipmentManager.equip(ResourceLoader.load(path))

func _process_skill_input() -> void:
	# 使用 Input 轮询处理技能按键
	var input_timer: Timer = Timer.new()
	input_timer.wait_time = 0.1
	input_timer.autostart = true
	input_timer.timeout.connect(_check_skill_input)
	add_child(input_timer)

func _check_skill_input() -> void:
	var dir: Vector2 = $Player.get_move_direction()
	if Input.is_action_just_pressed("skill_1"):
		$SkillManager.try_use_skill(0, dir)
	if Input.is_action_just_pressed("skill_2"):
		$SkillManager.try_use_skill(1, dir)
	if Input.is_action_just_pressed("skill_3"):
		$SkillManager.try_use_skill(2, dir)

func _on_player_leveled_up(new_level: int) -> void:
	var options: Array[Dictionary] = $HUD/UpgradePopup._generate_random_options(
		new_level,
		$SkillManager.owned_skill_ids
	)
	$HUD/UpgradePopup.show_options(options, $SkillManager, $Player)

func _on_player_died() -> void:
	$HUD/GameOverScreen.show_results($WaveController.current_wave)

func _on_wave_started(wave: int) -> void:
	$HUD.set_wave(wave)
	$HUD.hide_wave_break()

func _on_between_waves(seconds_left: float) -> void:
	$HUD.show_wave_break(seconds_left)

func _on_wave_cleared(wave: int) -> void:
	pass  # 可扩展

func _on_upgrade_chosen(choice: Dictionary) -> void:
	# 升级已被 upgrade_popup 处理
	pass
