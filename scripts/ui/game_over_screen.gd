extends Control
class_name GameOverScreen

func show_results(wave: int) -> void:
	visible = true
	var coins: int = wave * 10
	var cult: int = wave * 5

	$Panel/WaveLabel.text = "存活到第 %d 波" % wave
	$Panel/CoinReward.text = "获得铜钱: %d" % coins
	$Panel/CultReward.text = "获得修为: %d" % cult

	if SaveManager.instance:
		SaveManager.instance.add_reward(coins, cult)

	$Panel/ReturnButton.pressed.connect(_on_return, CONNECT_ONE_SHOT)

func _on_return() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
