extends GutTest

func test_enemy_take_damage() -> void:
	var enemy: Enemy = autofree(Enemy.new())
	enemy.max_health = 30.0
	enemy.current_health = 30.0
	enemy.take_damage(10.0)
	assert_eq(enemy.current_health, 20.0)

func test_enemy_dies_at_zero() -> void:
	var enemy: Enemy = autofree(Enemy.new())
	enemy.max_health = 30.0
	enemy.current_health = 5.0
	watch_signals(enemy)
	enemy.take_damage(10.0)
	assert_signal_emitted(enemy, "died")
