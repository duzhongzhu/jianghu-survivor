extends Node
class_name SkillManager

signal skill_used(skill_id: String, direction: Vector2)

var active_skills: Array[SkillResource] = []
var passive_skills: Array[SkillResource] = []
var cooldowns: Dictionary = {}
var owned_skill_ids: Array[String] = []
var player_ref: Player = null

var _passive_timers: Dictionary = {}

func _process(delta: float) -> void:
	# 冷却递减
	for skill_id in cooldowns.keys():
		cooldowns[skill_id] = maxf(0.0, cooldowns[skill_id] - delta)
	# 被动技能
	_process_passives(delta)

func add_skill(skill: SkillResource) -> void:
	if skill.id in owned_skill_ids:
		_upgrade_skill(skill)
		return
	owned_skill_ids.append(skill.id)
	match skill.type:
		SkillResource.Type.ACTIVE:
			if active_skills.size() < 3:
				active_skills.append(skill)
				cooldowns[skill.id] = 0.0
		SkillResource.Type.PASSIVE:
			passive_skills.append(skill)

func _upgrade_skill(skill: SkillResource) -> void:
	for s in active_skills + passive_skills:
		if s.id == skill.id:
			s.cooldown *= 0.85
			s.damage_mult *= 1.2
			break

func try_use_skill(slot: int, direction: Vector2) -> bool:
	if slot >= active_skills.size():
		return false
	var skill: SkillResource = active_skills[slot]
	if cooldowns.get(skill.id, 0.0) > 0.0:
		return false
	cooldowns[skill.id] = skill.cooldown
	skill_used.emit(skill.id, direction)
	return true

func _process_passives(delta: float) -> void:
	for skill in passive_skills:
		match skill.passive_trigger:
			SkillResource.PassiveTrigger.INTERVAL:
				if not skill.id in _passive_timers:
					_passive_timers[skill.id] = 0.0
				_passive_timers[skill.id] += delta
				if _passive_timers[skill.id] >= skill.trigger_interval:
					_passive_timers[skill.id] = 0.0
					_apply_buff(skill)

func _apply_buff(skill: SkillResource) -> void:
	match skill.buff_type:
		"invincible":
			if player_ref:
				player_ref.set_invincible(skill.buff_duration)
		"heal":
			if player_ref:
				player_ref.heal(skill.buff_value)

func on_enemy_killed() -> void:
	for skill in passive_skills:
		if skill.passive_trigger == SkillResource.PassiveTrigger.ON_KILL:
			_apply_buff(skill)
