extends GutTest

func test_add_active_skill() -> void:
	var mgr: SkillManager = autofree(SkillManager.new())
	var skill: SkillResource = SkillResource.new()
	skill.id = "test_active"
	skill.type = SkillResource.Type.ACTIVE
	skill.cooldown = 3.0
	mgr.add_skill(skill)
	assert_eq(mgr.active_skills.size(), 1)
	assert_true("test_active" in mgr.owned_skill_ids)

func test_skill_cooldown() -> void:
	var mgr: SkillManager = autofree(SkillManager.new())
	var skill: SkillResource = SkillResource.new()
	skill.id = "test_cd"
	skill.type = SkillResource.Type.ACTIVE
	skill.cooldown = 5.0
	mgr.add_skill(skill)
	assert_true(mgr.try_use_skill(0, Vector2.RIGHT))
	assert_false(mgr.try_use_skill(0, Vector2.RIGHT))  # 冷却中
