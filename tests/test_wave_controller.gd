extends GutTest

func test_wave_count_formula() -> void:
	var wc: WaveController = autofree(WaveController.new())
	assert_eq(wc._calculate_total_enemies(1), 8)
	assert_eq(wc._calculate_total_enemies(5), 20)
	assert_eq(wc._calculate_total_enemies(10), 35)

func test_enemy_health_scale() -> void:
	var wc: WaveController = autofree(WaveController.new())
	assert_almost_eq(wc._get_health_multiplier(1), 1.1, 0.001)
	assert_almost_eq(wc._get_health_multiplier(5), 1.5, 0.001)
	assert_almost_eq(wc._get_health_multiplier(10), 2.0, 0.001)

func test_enemy_damage_scale() -> void:
	var wc: WaveController = autofree(WaveController.new())
	assert_almost_eq(wc._get_damage_multiplier(1), 1.08, 0.001)
	assert_almost_eq(wc._get_damage_multiplier(5), 1.4, 0.001)
