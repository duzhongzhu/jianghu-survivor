extends GutTest

func test_add_reward() -> void:
	var mgr: SaveManager = autofree(SaveManager.new())
	mgr.copper_coins = 100
	mgr.add_reward(50, 30)
	assert_eq(mgr.copper_coins, 150)
	assert_eq(mgr.cultivation, 30)
