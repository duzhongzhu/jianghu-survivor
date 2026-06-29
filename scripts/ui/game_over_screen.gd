extends Control
class_name GameOverScreen

func _ready() -> void:
	$Panel/ReturnButton.pressed.connect(_on_return)

func show_results(wave: int) -> void:
	visible = true
	var coins: int = wave * 10
	var cult: int = wave * 5

	$Panel/WaveLabel.text = "存活到第 %d 波" % wave
	$Panel/CoinReward.text = "获得铜钱: %d" % coins
	$Panel/CultReward.text = "获得修为: %d" % cult

	SaveManager.add_reward(coins, cult)

func _on_return() -> void:
	get_tree().paused = false
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
