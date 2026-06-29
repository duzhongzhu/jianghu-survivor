extends CanvasLayer
class_name HUD

@onready var health_bar: ProgressBar = $HealthBar
@onready var exp_bar: ProgressBar = $ExpBar
@onready var wave_label: Label = $WaveLabel
@onready var enemy_count_label: Label = $EnemyCountLabel
@onready var wave_timer_label: Label = $WaveTimerLabel

func update_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current

func update_exp(current: float, to_next: float) -> void:
	exp_bar.max_value = to_next
	exp_bar.value = current

func set_wave(wave: int) -> void:
	wave_label.text = "第 %d 波" % wave

func set_enemy_remaining(count: int) -> void:
	enemy_count_label.text = "剩余: %d" % count

func show_wave_break(seconds_left: float) -> void:
	wave_timer_label.visible = true
	wave_timer_label.text = "下一波: %.0f 秒" % seconds_left

func hide_wave_break() -> void:
	wave_timer_label.visible = false
