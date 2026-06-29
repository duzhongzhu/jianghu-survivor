# 江湖求生 (Jianghu Survivor) 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 构建一个可玩的俯视角像素武侠波次生存游戏——WASD 移动、自动普攻、波次递增、升级 3 选 1、装备与技能系统。

**Architecture:** Godot 4.x 单场景为主架构，战斗主场景包含 Player/EnemySpawner/WaveController/HUD。装备和技能数据用 `.tres` Resource 定义，管理器类处理逻辑。场景间通过信号通信。

**Tech Stack:** Godot 4.x, GDScript, GUT (测试)

---

## 文件结构总览

```
/project.godot
/default_env.tres

/scenes/
  battle.tscn                    # 主战斗场景
  player.tscn                    # 玩家角色
  enemy_base.tscn                # 敌人基础场景
  projectile.tscn                # 弹幕场景（对象池用）
  main_menu.tscn                 # 主菜单
  equipment_menu.tscn            # 装备配置场景

/scripts/
  player/
    player.gd                    # 移动、自动普攻、技能输入
  enemies/
    enemy.gd                     # 敌人基类（寻路、血量、掉落）
    spawner.gd                   # 波次刷怪逻辑
  projectiles/
    projectile.gd                # 弹幕行为
    projectile_pool.gd           # 对象池
  skills/
    skill_manager.gd             # 技能注册、冷却、触发
  equipment/
    equipment_manager.gd         # 装备槽位、属性合计
  wave/
    wave_controller.gd           # 波次计时、难度递增
  ui/
    hud.gd                       # 血条/经验条/波次显示
    upgrade_popup.gd             # 升级 3 选 1 面板
    game_over_screen.gd          # 死亡结算
    main_menu.gd                 # 主菜单逻辑
    equipment_menu.gd            # 装备配置 UI 逻辑
  data/
    save_manager.gd              # 存档（铜钱/修为/装备）

/resource/
  equipment/
    iron_sword.tres              # 铁剑
    cloth_armor.tres             # 布衣
    jade_pendant.tres            # 玉佩
  skills/
    sword_wave.tres              # 剑气斩（主动）
    shadow_step.tres             # 影步（主动）
    golden_body.tres             # 金钟罩（被动）
    bloodthirst.tres             # 嗜血（被动）
  enemies/
    bandit.tres                  # 山贼喽啰
    assassin.tres                # 刺客

/tests/
  test_wave_controller.gd
  test_equipment_manager.gd
  test_save_manager.gd
  test_skill_manager.gd
  test_enemy.gd
```

---

## Phase 1: 项目基础与玩家移动

### Task 1: 创建 Godot 项目与目录结构

**Files:**
- Create: `project.godot`
- Create: `default_env.tres`
- Create: 所有目录

- [ ] **Step 1: 通过 Godot 编辑器创建项目**

在 Godot 4.x 中创建新项目，路径指向 `D:\Claude\pz`。选择 Compatibility Renderer（更适合像素风格）。

- [ ] **Step 2: 创建目录结构**

在项目根目录创建以下文件夹：
```
/scenes/
/scripts/player/
/scripts/enemies/
/scripts/projectiles/
/scripts/skills/
/scripts/equipment/
/scripts/wave/
/scripts/ui/
/scripts/data/
/resource/equipment/
/resource/skills/
/resource/enemies/
/tests/
```

- [ ] **Step 3: 配置项目设置**

在 Project Settings 中设置：
- Window Width: 960, Height: 640
- Stretch Mode: canvas_items
- Stretch Aspect: keep

- [ ] **Step 4: Commit**

```bash
git init
git add -A
git commit -m "feat: create Godot project and directory structure"
```

---

### Task 2: 玩家移动

**Files:**
- Create: `scenes/player.tscn`
- Create: `scripts/player/player.gd`

- [ ] **Step 1: 创建 Player 场景**

在 `scenes/player.tscn` 中创建 CharacterBody2D 根节点，命名为 Player：
- 添加 CollisionShape2D（圆形碰撞体，半径 16px）
- 添加 Sprite2D（暂用 Godot 内置 icon.svg 代替，32x32）
- 挂载脚本 `scripts/player/player.gd`

- [ ] **Step 2: 编写 player.gd — WASD 移动**

```gdscript
extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0

func _physics_process(delta: float) -> void:
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = input_dir * move_speed
    move_and_slide()
```

- [ ] **Step 3: 配置 Input Map**

在 Project Settings → Input Map 中，创建四个 Action：
- `move_left`: A 键
- `move_right`: D 键
- `move_up`: W 键
- `move_down`: S 键

- [ ] **Step 4: 创建 battle.tscn 并放置 Player**

创建 `scenes/battle.tscn`，根节点 Node2D，命名为 Battle：
- 添加 TileMap 子节点作为地板背景（用简单的灰色矩形 Texture）
- 实例化 Player 场景
- 添加 Camera2D 子节点跟随 Player

- [ ] **Step 5: 运行验证**

在编辑器中按 F5 运行，确认 WASD 控制角色移动。将 battle.tscn 设为主场景。

- [ ] **Step 6: Commit**

```bash
git add scenes/player.tscn scripts/player/player.gd scenes/battle.tscn project.godot
git commit -m "feat: add player WASD movement"
```

---

### Task 3: 自动普攻 — 最近敌人检测

**Files:**
- Modify: `scripts/player/player.gd`
- Create: `scripts/player/player.gd`（加攻击逻辑）

- [ ] **Step 1: 添加 Area2D 检测范围**

在 player.tscn 中：
- 添加 Area2D 子节点，名为 AttackRange
- 添加 CollisionShape2D（圆形，半径 100px）
- AttackRange 的 collision_layer 设为 layer 2（检测敌人用）

- [ ] **Step 2: 编写自动普攻逻辑**

更新 `scripts/player/player.gd`：

```gdscript
extends CharacterBody2D
class_name Player

@export var move_speed: float = 200.0
@export var attack_range: float = 100.0
@export var attack_damage: float = 10.0
@export var attack_speed: float = 1.0  # 每秒攻击次数

var enemies_in_range: Array[Node2D] = []
var nearest_enemy: Node2D = null
var attack_timer: float = 0.0

func _ready() -> void:
    $AttackRange.body_entered.connect(_on_enemy_entered_range)
    $AttackRange.body_exited.connect(_on_enemy_exited_range)
    # 动态更新 Area2D 碰撞半径
    ($AttackRange/CollisionShape2D as CollisionShape2D).shape.radius = attack_range

func _physics_process(delta: float) -> void:
    # 移动
    var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    velocity = input_dir * move_speed
    move_and_slide()

    # 自动普攻
    _update_nearest_enemy()
    attack_timer -= delta
    if attack_timer <= 0.0 and nearest_enemy:
        _attack()

func _on_enemy_entered_range(body: Node2D) -> void:
    if not body in enemies_in_range:
        enemies_in_range.append(body)

func _on_enemy_exited_range(body: Node2D) -> void:
    enemies_in_range.erase(body)

func _update_nearest_enemy() -> void:
    # 清理已销毁的敌人
    enemies_in_range = enemies_in_range.filter(func(e): return is_instance_valid(e))
    nearest_enemy = null
    var min_dist: float = INF
    for enemy in enemies_in_range:
        var dist: float = global_position.distance_squared_to(enemy.global_position)
        if dist < min_dist:
            min_dist = dist
            nearest_enemy = enemy

func _attack() -> void:
    if not is_instance_valid(nearest_enemy):
        return
    attack_timer = 1.0 / attack_speed
    # 对最近敌人造成伤害（enemy.gd 需要 take_damage 方法）
    nearest_enemy.take_damage(attack_damage)
```

- [ ] **Step 3: 验证编译**

在编辑器中检查脚本无语法错误（F5 运行，玩家仍可移动即可，暂无敌人）

- [ ] **Step 4: Commit**

```bash
git add scripts/player/player.gd scenes/player.tscn
git commit -m "feat: add auto-attack nearest enemy detection"
```

---

## Phase 2: 敌人与战斗核心

### Task 4: 敌人基类

**Files:**
- Create: `scenes/enemy_base.tscn`
- Create: `scripts/enemies/enemy.gd`
- Create: `tests/test_enemy.gd`

- [ ] **Step 1: 创建 Enemy 场景**

在 `scenes/enemy_base.tscn` 中创建 CharacterBody2D，命名为 Enemy：
- 添加 CollisionShape2D（圆形，半径 14px）
- 添加 Sprite2D（24x24 红色方块占位）
- Collision layer 设为 layer 2（与玩家检测区分）

- [ ] **Step 2: 编写 enemy.gd**

```gdscript
extends CharacterBody2D
class_name Enemy

signal died(drop_exp: int)

@export var max_health: float = 30.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var attack_cooldown: float = 1.0
@export var exp_drop: int = 10

var current_health: float
var attack_timer: float = 0.0
var player_ref: Player = null

func _ready() -> void:
    current_health = max_health

func _physics_process(delta: float) -> void:
    if not is_instance_valid(player_ref):
        return
    # 追踪玩家
    var dir: Vector2 = (player_ref.global_position - global_position).normalized()
    velocity = dir * move_speed
    move_and_slide()

    # 碰撞攻击玩家
    attack_timer -= delta
    if attack_timer <= 0.0:
        for i in get_slide_collision_count():
            var col: KinematicCollision2D = get_slide_collision(i)
            if col.get_collider() is Player:
                col.get_collider().take_damage(damage)
                attack_timer = attack_cooldown
                break

func set_player(p: Player) -> void:
    player_ref = p

func take_damage(amount: float) -> void:
    current_health -= amount
    # 受伤闪烁
    modulate = Color.RED
    await get_tree().create_timer(0.1).timeout
    modulate = Color.WHITE

    if current_health <= 0:
        die()

func die() -> void:
    died.emit(exp_drop)
    queue_free()
```

- [ ] **Step 3: 编写敌人测试**

创建 `tests/test_enemy.gd`：

```gdscript
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
```

- [ ] **Step 4: 运行测试验证**

在 Godot 编辑器中，使用 GUT 插件运行测试（需先安装 GUT）：
Expected: test_enemy_take_damage PASS, test_enemy_dies_at_zero PASS

- [ ] **Step 5: Commit**

```bash
git add scenes/enemy_base.tscn scripts/enemies/enemy.gd tests/test_enemy.gd
git commit -m "feat: add enemy base class with health and death"
```

---

### Task 5: 敌人刷怪系统

**Files:**
- Create: `scripts/enemies/spawner.gd`

- [ ] **Step 1: 编写 spawner.gd**

```gdscript
extends Node
class_name EnemySpawner

signal all_enemies_defeated

@export var enemy_scene: PackedScene
@export var spawn_margin: float = 300.0  # 生成距玩家最小距离
@export var max_enemies: int = 30

var player_ref: Player = null
var alive_enemies: Array[Enemy] = []
var enemies_to_spawn: int = 0
var wave_enemy_data: Array[Dictionary] = []  # [{enemy_scene, count}]
var spawn_interval: float = 1.0
var spawn_timer: float = 0.0
var spawn_queue: Array[PackedScene] = []

func _ready() -> void:
    pass

func _process(delta: float) -> void:
    if spawn_queue.is_empty() and alive_enemies.is_empty() and enemies_to_spawn <= 0:
        all_enemies_defeated.emit()
        return

    spawn_timer -= delta
    if spawn_timer <= 0.0 and not spawn_queue.is_empty():
        _spawn_one(spawn_queue.pop_front())
        spawn_timer = spawn_interval

func set_player(p: Player) -> void:
    player_ref = p

func start_wave(enemy_configs: Array[Dictionary], interval: float) -> void:
    spawn_interval = interval
    enemies_to_spawn = 0
    spawn_queue.clear()

    for config in enemy_configs:
        for i in range(config.count):
            spawn_queue.append(config.scene)
            enemies_to_spawn += 1

    spawn_queue.shuffle()
    spawn_timer = 0.5  # 预热 0.5 秒后开始生成

func _spawn_one(scene: PackedScene) -> void:
    if alive_enemies.size() >= max_enemies:
        # 超出上限，将场景放回队列延迟生成
        spawn_queue.push_front(scene)
        spawn_timer = 1.0
        return

    var enemy: Enemy = scene.instantiate()
    enemy.set_player(player_ref)
    enemy.died.connect(func(exp): _on_enemy_died(enemy, exp))

    # 在玩家周围随机位置生成
    var angle: float = randf_range(0, TAU)
    var dist: float = randf_range(spawn_margin, spawn_margin + 200)
    if player_ref:
        enemy.global_position = player_ref.global_position + Vector2.from_angle(angle) * dist
    get_parent().add_child(enemy)
    alive_enemies.append(enemy)

func _on_enemy_died(enemy: Enemy, exp: int) -> void:
    alive_enemies.erase(enemy)
    enemies_to_spawn -= 1
```

- [ ] **Step 2: 在 battle.tscn 中集成 Spawner**

在 battle.tscn 中添加 Node 子节点 EnemySpawner，挂载 spawner.gd。将 enemy_base.tscn 拖入 Enemy Scene 导出变量。

- [ ] **Step 3: 验证**

在编辑器中确认无脚本错误。

- [ ] **Step 4: Commit**

```bash
git add scripts/enemies/spawner.gd scenes/battle.tscn
git commit -m "feat: add enemy spawner with wave support"
```

---

### Task 6: 波次控制器

**Files:**
- Create: `scripts/wave/wave_controller.gd`
- Create: `tests/test_wave_controller.gd`

- [ ] **Step 1: 编写 wave_controller.gd**

```gdscript
extends Node
class_name WaveController

signal wave_started(wave_number: int)
signal wave_cleared(wave_number: int)
signal between_waves(seconds_left: float)

@export var spawner: EnemySpawner
@export var base_enemy_scene: PackedScene  # 山贼喽啰

var current_wave: int = 0
var wave_active: bool = false
var break_timer: float = 0.0
var break_duration: float = 8.0

func _ready() -> void:
    if spawner:
        spawner.all_enemies_defeated.connect(_on_all_enemies_defeated)
    start_next_wave()

func start_next_wave() -> void:
    current_wave += 1
    wave_active = true
    wave_started.emit(current_wave)

    var configs: Array[Dictionary] = _generate_wave_config(current_wave)
    var interval: float = maxf(0.3, 1.0 - current_wave * 0.05)
    spawner.start_wave(configs, interval)

func _on_all_enemies_defeated() -> void:
    if not wave_active:
        return
    wave_active = false
    wave_cleared.emit(current_wave)
    # 开始波间休息
    break_timer = break_duration

func _process(delta: float) -> void:
    if break_timer > 0.0 and not wave_active:
        break_timer -= delta
        between_waves.emit(break_timer)
        if break_timer <= 0.0:
            start_next_wave()

func _generate_wave_config(wave: int) -> Array[Dictionary]:
    var total_count: int = 5 + wave * 3
    return [{
        "scene": base_enemy_scene,
        "count": total_count
    }]
```

- [ ] **Step 2: 编写波次测试**

创建 `tests/test_wave_controller.gd`：

```gdscript
extends GutTest

func test_wave_count_formula() -> void:
    var wc: WaveController = autofree(WaveController.new())
    # 验证公式：波次 N 敌人总数 = 5 + N * 3
    assert_eq(wc._calculate_total_enemies(1), 8)
    assert_eq(wc._calculate_total_enemies(5), 20)
    assert_eq(wc._calculate_total_enemies(10), 35)

func test_enemy_health_scale() -> void:
    var wc: WaveController = autofree(WaveController.new())
    # 血量倍率 = 1 + N * 0.1
    assert_almost_eq(wc._get_health_multiplier(1), 1.1, 0.001)
    assert_almost_eq(wc._get_health_multiplier(5), 1.5, 0.001)
    assert_almost_eq(wc._get_health_multiplier(10), 2.0, 0.001)
```

- [ ] **Step 3: 在 wave_controller.gd 中添加静态计算方法**

```gdscript
func _calculate_total_enemies(wave: int) -> int:
    return 5 + wave * 3

func _get_health_multiplier(wave: int) -> float:
    return 1.0 + wave * 0.1

func _get_damage_multiplier(wave: int) -> float:
    return 1.0 + wave * 0.08
```

- [ ] **Step 4: 在 battle.tscn 中集成 WaveController**

添加 Node 子节点 WaveController，挂载 wave_controller.gd。连接 spawner 引用。

- [ ] **Step 5: 运行测试**

```bash
# 在 Godot GUT 面板中
# Expected: test_wave_count_formula PASS, test_enemy_health_scale PASS
```

- [ ] **Step 6: Commit**

```bash
git add scripts/wave/wave_controller.gd tests/test_wave_controller.gd scenes/battle.tscn
git commit -m "feat: add wave controller with scaling difficulty"
```

---

## Phase 3: HUD 与经验系统

### Task 7: HUD — 血条和经验条

**Files:**
- Create: `scripts/ui/hud.gd`

- [ ] **Step 1: 创建 HUD CanvasLayer**

在 battle.tscn 中添加 CanvasLayer 子节点 HUD，挂载 hud.gd。其子节点结构：

```
HUD (CanvasLayer)
├── HealthBar (ProgressBar) — 红色，锚定左上
├── ExpBar (ProgressBar) — 蓝色，锚定左上，HealthBar 下方
├── WaveLabel (Label) — 显示 "第 X 波"
└── EnemyCountLabel (Label) — 显示 "剩余: N"
```

- [ ] **Step 2: 编写 hud.gd**

```gdscript
extends CanvasLayer
class_name HUD

@onready var health_bar: ProgressBar = $HealthBar
@onready var exp_bar: ProgressBar = $ExpBar
@onready var wave_label: Label = $WaveLabel
@onready var enemy_count_label: Label = $EnemyCountLabel

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
```

- [ ] **Step 3: 在 Player 中添加经验系统**

更新 `scripts/player/player.gd`，添加：

```gdscript
# 经验系统
signal leveled_up(new_level: int)

@export var max_health: float = 100.0
var current_health: float
var current_exp: int = 0
var exp_to_next_level: int = 20
var level: int = 1

func _ready() -> void:
    # ... 之前的代码 ...
    current_health = max_health

func gain_exp(amount: int) -> void:
    current_exp += amount
    while current_exp >= exp_to_next_level:
        current_exp -= exp_to_next_level
        level += 1
        exp_to_next_level = int(exp_to_next_level * 1.2)
        leveled_up.emit(level)

func take_damage(amount: float) -> void:
    current_health -= amount
    if current_health <= 0:
        die()

func die() -> void:
    # 死亡逻辑 — 后续任务实现
    pass
```

- [ ] **Step 4: 连接信号**

在 battle.tscn 中，通过编辑器连接信号：
- Player.leveled_up → HUD 更新
- WaveController.wave_started → HUD.set_wave
- 在 hud.gd 中添加 `_process` 每帧同步数据

- [ ] **Step 5: 运行验证**

F5 运行，确认 HUD 显示正常，血条和经验条有值。

- [ ] **Step 6: Commit**

```bash
git add scripts/ui/hud.gd scripts/player/player.gd scenes/battle.tscn
git commit -m "feat: add HUD with health, experience, and wave display"
```

---

### Task 8: 升级 3 选 1 弹窗

**Files:**
- Create: `scripts/ui/upgrade_popup.gd`

- [ ] **Step 1: 创建升级弹窗 UI**

在 battle.tscn 的 HUD 下添加：

```
UpgradePopup (Control, 初始隐藏)
├── Panel (居中，半透明背景)
├── Title (Label — "选择强化")
├── OptionsContainer (HBoxContainer)
│   ├── Option1 (VBoxContainer — Button + Label)
│   ├── Option2 (VBoxContainer — Button + Label)
│   └── Option3 (VBoxContainer — Button + Label)
```

- [ ] **Step 2: 编写 upgrade_popup.gd**

```gdscript
extends Control
class_name UpgradePopup

signal upgrade_chosen(option_data: Dictionary)

var _options: Array[Dictionary] = []

func show_options(options: Array[Dictionary]) -> void:
    _options = options
    visible = true
    get_tree().paused = true

    for i in range(3):
        var btn: Button = $OptionsContainer.get_child(i).get_node("Button")
        var label: Label = $OptionsContainer.get_child(i).get_node("Label")
        if i < options.size():
            btn.text = options[i].name
            label.text = options[i].description
            btn.visible = true
            btn.pressed.connect(func(): _on_chosen(i), CONNECT_ONE_SHOT)
        else:
            btn.visible = false

func _on_chosen(index: int) -> void:
    visible = false
    get_tree().paused = false
    upgrade_chosen.emit(_options[index])

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
```

- [ ] **Step 3: 连接 Player.leveled_up 到 UpgradePopup**

在 battle.tscn 中连接信号：Player.leveled_up → UpgradePopup.show_options

- [ ] **Step 4: Commit**

```bash
git add scripts/ui/upgrade_popup.gd scenes/battle.tscn
git commit -m "feat: add level-up 3-option popup"
```

---

## Phase 4: 装备与技能系统

### Task 9: 装备管理器

**Files:**
- Create: `scripts/equipment/equipment_manager.gd`
- Create: `resource/equipment/iron_sword.tres`
- Create: `resource/equipment/cloth_armor.tres`
- Create: `resource/equipment/jade_pendant.tres`
- Create: `tests/test_equipment_manager.gd`

- [ ] **Step 1: 定义装备 Resource 类**

```gdscript
# scripts/equipment/equipment_resource.gd
extends Resource
class_name EquipmentResource

@export var id: String = ""
@export var display_name: String = ""
enum Slot { WEAPON, ARMOR, ACCESSORY }
@export var slot: Slot = Slot.WEAPON
@export var attack: float = 0.0
@export var health: float = 0.0
@export var defense: float = 0.0
@export var speed_mod: float = 0.0
@export var attack_range: float = 80.0
@export var attack_speed: float = 1.0
enum AttackType { MELEE_ARC, MELEE_CIRCLE, RANGED_SINGLE, RANGED_CONE, RANGED_AOE }
@export var attack_type: AttackType = AttackType.MELEE_ARC
@export var price: int = 100
@export var description: String = ""
```

- [ ] **Step 2: 编写 equipment_manager.gd**

```gdscript
extends Node
class_name EquipmentManager

static var instance: EquipmentManager
signal equipment_changed

func _ready() -> void:
    instance = self

var weapon_slot: EquipmentResource = null
var armor_slot: EquipmentResource = null
var accessory_slot: EquipmentResource = null

func equip(item: EquipmentResource) -> void:
    match item.slot:
        EquipmentResource.Slot.WEAPON:
            weapon_slot = item
        EquipmentResource.Slot.ARMOR:
            armor_slot = item
        EquipmentResource.Slot.ACCESSORY:
            accessory_slot = item
    equipment_changed.emit()

func get_total_attack() -> float:
    var total: float = 10.0  # 基础攻击
    if weapon_slot: total += weapon_slot.attack
    if accessory_slot: total += accessory_slot.attack
    return total

func get_total_health() -> float:
    var total: float = 100.0
    if armor_slot: total += armor_slot.health
    if accessory_slot: total += accessory_slot.health
    return total

func get_attack_type() -> int:
    if weapon_slot:
        return weapon_slot.attack_type
    return EquipmentResource.AttackType.MELEE_ARC

func get_attack_range() -> float:
    if weapon_slot:
        return weapon_slot.attack_range
    return 80.0

func get_attack_speed() -> float:
    if weapon_slot:
        return weapon_slot.attack_speed
    return 1.0
```

- [ ] **Step 3: 创建示例装备 Resource**

在编辑器中创建 Resource 文件：
- `resource/equipment/iron_sword.tres`: Weapon, attack=15, melee_arc, price=100
- `resource/equipment/cloth_armor.tres`: Armor, health=30, defense=5, price=80
- `resource/equipment/jade_pendant.tres`: Accessory, attack=5, health=10, price=120

- [ ] **Step 4: 编写装备测试**

```gdscript
# tests/test_equipment_manager.gd
extends GutTest

func test_equip_weapon() -> void:
    var mgr: EquipmentManager = autofree(EquipmentManager.new())
    var sword: EquipmentResource = EquipmentResource.new()
    sword.id = "test_sword"
    sword.slot = EquipmentResource.Slot.WEAPON
    sword.attack = 15.0
    mgr.equip(sword)
    assert_eq(mgr.get_total_attack(), 25.0)  # 10 base + 15

func test_unequipped_defaults() -> void:
    var mgr: EquipmentManager = autofree(EquipmentManager.new())
    assert_eq(mgr.get_total_attack(), 10.0)
    assert_eq(mgr.get_total_health(), 100.0)
    assert_eq(mgr.get_attack_type(), EquipmentResource.AttackType.MELEE_ARC)
```

- [ ] **Step 5: 运行测试**

Expected: test_equip_weapon PASS, test_unequipped_defaults PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/equipment/ resource/equipment/ tests/test_equipment_manager.gd
git commit -m "feat: add equipment manager with 3-slot system"
```

---

### Task 10: 技能管理器

**Files:**
- Create: `scripts/skills/skill_manager.gd`
- Create: `resource/skills/sword_wave.tres`
- Create: `resource/skills/shadow_step.tres`
- Create: `resource/skills/golden_body.tres`
- Create: `resource/skills/bloodthirst.tres`
- Create: `tests/test_skill_manager.gd`

- [ ] **Step 1: 定义技能 Resource 类**

```gdscript
# scripts/skills/skill_resource.gd
extends Resource
class_name SkillResource

@export var id: String = ""
@export var display_name: String = ""
enum Type { ACTIVE, PASSIVE }
@export var type: Type = Type.ACTIVE
@export var cooldown: float = 5.0
@export var description: String = ""
# 效果参数
@export var damage_mult: float = 1.0
@export var range: float = 150.0
@export var shape: String = "line"  # line, circle, cone
@export var pierce: bool = false
# 被动专用
enum PassiveTrigger { INTERVAL, ON_KILL, ALWAYS }
@export var passive_trigger: PassiveTrigger = PassiveTrigger.INTERVAL
@export var trigger_interval: float = 15.0
@export var buff_type: String = ""  # "invincible", "heal", "speed"
@export var buff_value: float = 0.0
@export var buff_duration: float = 3.0
```

- [ ] **Step 2: 编写 skill_manager.gd**

```gdscript
extends Node
class_name SkillManager

signal skill_used(skill_id: String)

var active_skills: Array[SkillResource] = []       # 已装备主动技 (最多 3)
var passive_skills: Array[SkillResource] = []
var cooldowns: Dictionary = {}  # {skill_id: remaining_seconds}
var owned_skill_ids: Array[String] = []
var player_ref: Player = null

func _ready() -> void:
    _init_passive_skills()

func _process(delta: float) -> void:
    # 更新冷却
    for skill_id in cooldowns.keys():
        cooldowns[skill_id] = maxf(0.0, cooldowns[skill_id] - delta)
    # 被动技能计时
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
    # 找到已拥有技能并强化（降低 15% 冷却或提升 20% 伤害）
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
            SkillResource.PassiveTrigger.ON_KILL:
                # 被动击杀触发由 Player 调用
                pass
            SkillResource.PassiveTrigger.ALWAYS:
                _apply_stat_buff(skill)

var _passive_timers: Dictionary = {}

func _apply_buff(skill: SkillResource) -> void:
    match skill.buff_type:
        "invincible":
            if player_ref:
                player_ref.set_invincible(skill.buff_duration)
        "heal":
            if player_ref:
                player_ref.heal(skill.buff_value)

func _apply_stat_buff(skill: SkillResource) -> void:
    # 常驻属性由外部读取 passive_skills 遍历
    pass

func on_enemy_killed() -> void:
    for skill in passive_skills:
        if skill.passive_trigger == SkillResource.PassiveTrigger.ON_KILL:
            _apply_buff(skill)
```

- [ ] **Step 3: 创建技能 Resource 文件**

在编辑器中创建：
- `sword_wave.tres`: Active, cooldown=5s, shape=line, range=200, damage_mult=2.5, pierce=true
- `shadow_step.tres`: Active, cooldown=8s, shape=none (位移), range=150
- `golden_body.tres`: Passive, interval=15s, buff_type=invincible, buff_duration=3s
- `bloodthirst.tres`: Passive, on_kill trigger, buff_type=heal, buff_value=5

- [ ] **Step 4: 编写技能测试**

```gdscript
# tests/test_skill_manager.gd
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
```

- [ ] **Step 5: 运行测试**

Expected: test_add_active_skill PASS, test_skill_cooldown PASS

- [ ] **Step 6: Commit**

```bash
git add scripts/skills/ resource/skills/ tests/test_skill_manager.gd
git commit -m "feat: add skill manager with active/passive skills"
```

---

## Phase 5: 弹幕与武器系统

### Task 11: 弹幕对象池

**Files:**
- Create: `scenes/projectile.tscn`
- Create: `scripts/projectiles/projectile.gd`
- Create: `scripts/projectiles/projectile_pool.gd`

- [ ] **Step 1: 创建 Projectile 场景**

`scenes/projectile.tscn`：Area2D 根节点 Projectile
- 添加 CollisionShape2D（矩形或圆形，视形状而定）
- 添加 Sprite2D（8x8 小方块占位）
- collision_layer 设 layer 4（弹幕用）

- [ ] **Step 2: 编写 projectile.gd**

```gdscript
extends Area2D
class_name Projectile

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 3.0
var pierce: bool = false
var hit_enemies: Array[Enemy] = []
var _age: float = 0.0

func _physics_process(delta: float) -> void:
    position += velocity * delta
    _age += delta
    if _age > lifetime:
        _return_to_pool()

func launch(from: Vector2, direction: Vector2, speed: float, dmg: float, do_pierce: bool = false) -> void:
    global_position = from
    velocity = direction.normalized() * speed
    damage = dmg
    pierce = do_pierce
    hit_enemies.clear()
    _age = 0.0
    set_deferred("monitoring", true)

func _on_body_entered(body: Node2D) -> void:
    if body is Enemy:
        if pierce and body in hit_enemies:
            return
        body.take_damage(damage)
        hit_enemies.append(body)
        if not pierce:
            _return_to_pool()

func _return_to_pool() -> void:
    set_deferred("monitoring", false)
    ProjectilePool.return_to_pool(self)
```

- [ ] **Step 3: 编写 projectile_pool.gd**

```gdscript
extends Node
class_name ProjectilePool

static var instance: ProjectilePool

@export var projectile_scene: PackedScene
var _pool: Array[Projectile] = []
var _pool_size: int = 50

func _ready() -> void:
    instance = self
    for i in range(_pool_size):
        var p: Projectile = projectile_scene.instantiate()
        p.monitoring = false
        add_child(p)
        _pool.append(p)

static func request() -> Projectile:
    for p in instance._pool:
        if not p.monitoring:
            return p
    # 池满则扩展
    var new_p: Projectile = instance.projectile_scene.instantiate()
    instance.add_child(new_p)
    instance._pool.append(new_p)
    return new_p

static func return_to_pool(p: Projectile) -> void:
    p.monitoring = false
    p.velocity = Vector2.ZERO
```

- [ ] **Step 4: 在 battle.tscn 中集成**

添加 ProjectilePool 子节点，挂载 projectile_pool.gd，设置 projectile_scene 导出变量。

- [ ] **Step 5: Commit**

```bash
git add scenes/projectile.tscn scripts/projectiles/
git commit -m "feat: add projectile pool system"
```

---

### Task 12: 多种攻击形态实现

**Files:**
- Modify: `scripts/player/player.gd`

- [ ] **Step 1: 在 player.gd 中实现攻击形态切换**

```gdscript
# 在 _attack() 方法中根据 attack_type 分发
func _attack() -> void:
    if not is_instance_valid(nearest_enemy):
        return
    attack_timer = 1.0 / attack_speed

    var atk_type: int = EquipmentResource.AttackType.MELEE_ARC
    if EquipmentManager.instance:
        atk_type = EquipmentManager.instance.get_attack_type()

    match atk_type:
        EquipmentResource.AttackType.MELEE_ARC:
            _perform_melee_arc()
        EquipmentResource.AttackType.MELEE_CIRCLE:
            _perform_melee_circle()
        EquipmentResource.AttackType.RANGED_SINGLE:
            _perform_ranged_single()
        EquipmentResource.AttackType.RANGED_CONE:
            _perform_ranged_cone()
        EquipmentResource.AttackType.RANGED_AOE:
            _perform_ranged_aoe()

func _perform_melee_arc() -> void:
    # 前方 120° 扇形：直接伤害范围内的所有敌人
    for enemy in enemies_in_range:
        if is_instance_valid(enemy):
            var to_enemy: Vector2 = enemy.global_position - global_position
            var forward: Vector2 = Vector2.RIGHT.rotated(rotation) if velocity != Vector2.ZERO else Vector2.RIGHT
            if to_enemy.normalized().dot(forward) > cos(deg_to_rad(60)):
                enemy.take_damage(attack_damage)

func _perform_melee_circle() -> void:
    for enemy in enemies_in_range:
        if is_instance_valid(enemy):
            enemy.take_damage(attack_damage * 0.7)

func _perform_ranged_single() -> void:
    var p: Projectile = ProjectilePool.request()
    var dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
    p.launch(global_position, dir, 300.0, attack_damage, false)

func _perform_ranged_cone() -> void:
    for i in range(3):
        var p: Projectile = ProjectilePool.request()
        var base_dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
        var spread: float = -0.2 + i * 0.2
        p.launch(global_position, base_dir.rotated(spread), 300.0, attack_damage * 0.6, false)

func _perform_ranged_aoe() -> void:
    var p: Projectile = ProjectilePool.request()
    var dir: Vector2 = (nearest_enemy.global_position - global_position).normalized()
    p.launch(global_position, dir, 200.0, attack_damage * 1.5, true)  # pierce=true
```

- [ ] **Step 2: 更新 Player 面朝方向**

```gdscript
# 在 _physics_process 中添加：
if velocity.length_squared() > 1.0:
    rotation = velocity.angle()  # 面朝移动方向
```

- [ ] **Step 3: 运行验证**

F5 运行，确认不同武器类型切换有不同攻击效果。

- [ ] **Step 4: Commit**

```bash
git add scripts/player/player.gd
git commit -m "feat: implement 5 attack types (melee arc/circle, ranged single/cone/aoe)"
```

---

## Phase 6: 存档与菜单

### Task 13: 存档管理器

**Files:**
- Create: `scripts/data/save_manager.gd`
- Create: `tests/test_save_manager.gd`

- [ ] **Step 1: 编写 save_manager.gd 并设为 Autoload**

在 Project Settings → Autoload 中添加 `scripts/data/save_manager.gd`，Node Name 设为 `SaveManager`。

```gdscript
extends Node
class_name SaveManager

static var instance: SaveManager

func _ready() -> void:
    instance = self

var copper_coins: int = 0
var cultivation: int = 0
var owned_equipment_ids: Array[String] = []
var equipped_weapon_id: String = ""
var equipped_armor_id: String = ""
var equipped_accessory_id: String = ""

const SAVE_PATH: String = "user://save_data.json"

func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        return
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    var data: Dictionary = JSON.parse_string(file.get_as_text())
    file.close()
    if data == null:
        return
    copper_coins = data.get("copper_coins", 0)
    cultivation = data.get("cultivation", 0)
    owned_equipment_ids = data.get("owned_equipment_ids", [])
    equipped_weapon_id = data.get("equipped_weapon_id", "")
    equipped_armor_id = data.get("equipped_armor_id", "")
    equipped_accessory_id = data.get("equipped_accessory_id", "")

func save_game() -> void:
    var data: Dictionary = {
        "copper_coins": copper_coins,
        "cultivation": cultivation,
        "owned_equipment_ids": owned_equipment_ids,
        "equipped_weapon_id": equipped_weapon_id,
        "equipped_armor_id": equipped_armor_id,
        "equipped_accessory_id": equipped_accessory_id,
    }
    var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "\t"))
    file.close()

func add_reward(coins: int, cult: int) -> void:
    copper_coins += coins
    cultivation += cult
    save_game()
```

- [ ] **Step 2: 编写存档测试**

```gdscript
# tests/test_save_manager.gd
extends GutTest

func test_save_and_load() -> void:
    var mgr: SaveManager = autofree(SaveManager.new())
    mgr.copper_coins = 500
    mgr.cultivation = 200
    mgr.owned_equipment_ids = ["iron_sword"]
    mgr.save_game()
    # 新实例加载
    var mgr2: SaveManager = autofree(SaveManager.new())
    mgr2.load_game()
    assert_eq(mgr2.copper_coins, 500)
    assert_eq(mgr2.cultivation, 200)
    assert_eq(mgr2.owned_equipment_ids, ["iron_sword"])

func test_add_reward() -> void:
    var mgr: SaveManager = autofree(SaveManager.new())
    mgr.copper_coins = 100
    mgr.add_reward(50, 30)
    assert_eq(mgr.copper_coins, 150)
    assert_eq(mgr.cultivation, 30)
```

- [ ] **Step 3: 运行测试**

Expected: test_save_and_load PASS, test_add_reward PASS

- [ ] **Step 4: Commit**

```bash
git add scripts/data/save_manager.gd tests/test_save_manager.gd
git commit -m "feat: add save manager with JSON persistence"
```

---

### Task 14: 主菜单与装备菜单

**Files:**
- Create: `scenes/main_menu.tscn`
- Create: `scripts/ui/main_menu.gd`
- Create: `scenes/equipment_menu.tscn`
- Create: `scripts/ui/equipment_menu.gd`

- [ ] **Step 1: 创建主菜单场景**

`scenes/main_menu.tscn`：Control 根节点
```
MainMenu (Control)
├── Title (Label — "江湖求生")
├── StartButton (Button — "踏入江湖")
├── EquipmentButton (Button — "装备配置")
└── QuitButton (Button — "退出游戏")
```

- [ ] **Step 2: 编写 main_menu.gd**

```gdscript
extends Control

func _ready() -> void:
    if SaveManager.instance:
        SaveManager.instance.load_game()
    $StartButton.pressed.connect(_on_start)
    $EquipmentButton.pressed.connect(_on_equipment)
    $QuitButton.pressed.connect(_on_quit)

func _on_start() -> void:
    get_tree().change_scene_to_file("res://scenes/battle.tscn")

func _on_equipment() -> void:
    get_tree().change_scene_to_file("res://scenes/equipment_menu.tscn")

func _on_quit() -> void:
    get_tree().quit()
```

- [ ] **Step 3: 创建装备菜单场景**

`scenes/equipment_menu.tscn`：Control 根节点
```
EquipmentMenu (Control)
├── Title (Label — "装备配置")
├── CopperLabel (Label — "铜钱: 0")
├── WeaponSlot (ItemList/VBox)
├── ArmorSlot (ItemList/VBox)
├── AccessorySlot (ItemList/VBox)
├── BackButton (Button — "返回")
```

- [ ] **Step 4: 编写 equipment_menu.gd**

```gdscript
extends Control

var all_equipment: Array[EquipmentResource] = []

func _ready() -> void:
    _load_equipment_catalog()
    _refresh_ui()
    $BackButton.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu.tscn"))

func _load_equipment_catalog() -> void:
    all_equipment.clear()
    # 加载 resource/equipment/ 下所有 .tres 文件
    var dir: DirAccess = DirAccess.open("res://resource/equipment/")
    if dir:
        dir.list_dir_begin()
        var file_name: String = dir.get_next()
        while file_name != "":
            if file_name.ends_with(".tres"):
                var res: EquipmentResource = load("res://resource/equipment/" + file_name)
                all_equipment.append(res)
            file_name = dir.get_next()

func _refresh_ui() -> void:
    var coins: int = SaveManager.instance.copper_coins if SaveManager.instance else 0
    var cult: int = SaveManager.instance.cultivation if SaveManager.instance else 0
    $CopperLabel.text = "铜钱: %d  修为: %d" % [coins, cult]
```

- [ ] **Step 5: 设置主菜单为默认场景**

在 Project Settings → Application → Run → Main Scene 设为 `scenes/main_menu.tscn`

- [ ] **Step 6: Commit**

```bash
git add scenes/main_menu.tscn scenes/equipment_menu.tscn scripts/ui/main_menu.gd scripts/ui/equipment_menu.gd
git commit -m "feat: add main menu and equipment menu scenes"
```

---

## Phase 7: 游戏结束与结算

### Task 15: 死亡结算与奖励

**Files:**
- Create: `scripts/ui/game_over_screen.gd`
- Modify: `scripts/player/player.gd`

- [ ] **Step 1: 创建 GameOver 场景**

在 battle.tscn HUD 下添加：
```
GameOverScreen (Control, 初始隐藏)
├── Panel (居中)
├── ResultLabel (Label — "虽败犹荣")
├── WaveLabel (Label — "存活到第 X 波")
├── CoinReward (Label — "获得铜钱: N")
├── CultReward (Label — "获得修为: N")
└── ReturnButton (Button — "返回江湖")
```

- [ ] **Step 2: 编写 game_over_screen.gd**

```gdscript
extends Control
class_name GameOverScreen

func show_results(wave: int) -> void:
    visible = true
    var coins: int = wave * 10
    var cult: int = wave * 5
    $WaveLabel.text = "存活到第 %d 波" % wave
    $CoinReward.text = "获得铜钱: %d" % coins
    $CultReward.text = "获得修为: %d" % cult
    if SaveManager.instance:
        SaveManager.instance.add_reward(coins, cult)
    $ReturnButton.pressed.connect(_on_return)

func _on_return() -> void:
    get_tree().paused = false
    get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
```

- [ ] **Step 3: 在 player.gd 中实现 die()**

```gdscript
func die() -> void:
    $CollisionShape2D.set_deferred("disabled", true)
    get_tree().paused = true
    var wave: int = 0
    if WaveController.instance:
        wave = WaveController.instance.current_wave
    $"/root/Battle/HUD/GameOverScreen".show_results(wave)
```

- [ ] **Step 4: 在 WaveController 中添加 instance 单例引用**

```gdscript
static var instance: WaveController

func _ready() -> void:
    instance = self
    # ... 原有代码
```

- [ ] **Step 5: Commit**

```bash
git add scripts/ui/game_over_screen.gd scripts/player/player.gd scripts/wave/wave_controller.gd
git commit -m "feat: add game over screen with coin/cultivation rewards"
```

---

## Phase 8: 精英与 Boss（基础版）

### Task 16: 精英与 Boss 敌人

**Files:**
- Create: `resource/enemies/bandit.tres`
- Create: `resource/enemies/assassin.tres`
- Modify: `scripts/wave/wave_controller.gd`
- Modify: `scripts/enemies/enemy.gd`

- [ ] **Step 1: 创建敌人 Resource**

```gdscript
# scripts/enemies/enemy_resource.gd
extends Resource
class_name EnemyResource

@export var id: String = ""
@export var display_name: String = ""
@export var max_health: float = 30.0
@export var move_speed: float = 80.0
@export var damage: float = 10.0
@export var exp_drop: int = 10
@export var behavior: String = "chase"  # chase, dash, ranged, shield
@export var dash_speed: float = 300.0
@export var dash_interval: float = 3.0
@export var shield_duration: float = 4.0
@export var shield_interval: float = 10.0
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var scale_mult: float = 1.0
```

- [ ] **Step 2: 更新 wave_controller.gd 添加精英/Boss**

```gdscript
# 更新 _generate_wave_config
@export var elite_enemy_scene: PackedScene  # 刺客/精英
@export var boss_enemy_scene: PackedScene

func _generate_wave_config(wave: int) -> Array[Dictionary]:
    var configs: Array[Dictionary] = []
    var total_count: int = _calculate_total_enemies(wave)

    if wave % 10 == 0:
        # Boss 波：1 个 Boss + 正常敌人
        configs.append({"scene": boss_enemy_scene, "count": 1})
        total_count -= 1
    elif wave % 5 == 0:
        # 精英波：3 个精英 + 正常敌人
        configs.append({"scene": elite_enemy_scene, "count": 3})
        total_count -= 3

    configs.append({"scene": base_enemy_scene, "count": maxi(0, total_count)})
    return configs
```

- [ ] **Step 3: 在 enemy.gd 中添加精英/Boss 逻辑**

```gdscript
@export var resource: EnemyResource

func _ready() -> void:
    if resource:
        max_health = resource.max_health
        move_speed = resource.move_speed
        damage = resource.damage
        exp_drop = resource.exp_drop
        if resource.is_elite or resource.is_boss:
            scale = Vector2.ONE * resource.scale_mult
            max_health *= 3.0 if resource.is_elite else 10.0
            exp_drop *= 3 if resource.is_elite else 10

    current_health = max_health

    # Boss 有血条
    if resource and resource.is_boss:
        var bar: ProgressBar = ProgressBar.new()
        bar.max_value = max_health
        bar.value = current_health
        add_child(bar)
```

- [ ] **Step 4: 创建 Resource 文件**

- `resource/enemies/bandit.tres`: id=bandit, health=30, speed=80, behavior=chase
- `resource/enemies/assassin.tres`: id=assassin, health=20, speed=100, behavior=dash, dash_speed=300, is_elite=true, scale_mult=1.5

- [ ] **Step 5: Commit**

```bash
git add resource/enemies/ scripts/enemies/enemy.gd scripts/wave/wave_controller.gd
git commit -m "feat: add elite and boss enemy support"
```

---

## Phase 9: 整合与打磨

### Task 17: 场景整合与全局连线

**Files:**
- Modify: `scenes/battle.tscn`
- Modify: `scripts/player/player.gd`

- [ ] **Step 1: 在 battle.tscn 中连接所有信号**

确认以下连接在编辑器或 `_ready` 中建立：
- Player.leveled_up → UpgradePopup
- Enemy.died → Player.gain_exp + Spawner._on_enemy_died
- WaveController.wave_started → HUD.set_wave
- WaveController.between_waves → HUD（显示倒计时）
- WaveController.wave_cleared → 无（仅日志）
- UpgradePopup.upgrade_chosen → SkillManager / Player 应用效果
- Player.died → GameOverScreen

- [ ] **Step 2: 在 battle.tscn 根节点添加初始化脚本**

```gdscript
# battle_setup.gd（挂载到 Battle 根节点）
extends Node2D

func _ready() -> void:
    # 给 Spawner 设置 Player 引用
    $EnemySpawner.set_player($Player)
    # 给 WaveController 设置依赖
    $WaveController.spawner = $EnemySpawner
    $WaveController.base_enemy_scene = preload("res://scenes/enemy_base.tscn")
    $WaveController.elite_enemy_scene = preload("res://scenes/enemy_base.tscn")
    $WaveController.boss_enemy_scene = preload("res://scenes/enemy_base.tscn")
    # 给 Player 设置引用
    $Player.equipment_manager = $EquipmentManager
    $Player.skill_manager = $SkillManager
    $Player.hud = $HUD
    # 初始化 SkillManager
    $SkillManager.player_ref = $Player
```

- [ ] **Step 3: 运行并测试完整循环**

F5 → 主菜单 → 踏入江湖 → 移动 WASD → 敌人刷出 → 击杀升级 → 选升级 → 继续战斗 → 被杀死 → 结算 → 返回主菜单 → 再次进入

- [ ] **Step 4: Commit**

```bash
git add scenes/battle.tscn scripts/player/player.gd
git commit -m "feat: wire all scenes and signals, complete game loop"
```

---

### Task 18: 基础像素美术占位

**Files:**
- Create: 各 Sprite 用临时像素图

- [ ] **Step 1: 创建简单像素占位图**

用代码生成或手动创建以下占位贴图（16x16 或 32x32 纯色矩形）：
- `assets/player.png` — 蓝色矩形 32x32
- `assets/enemy_bandit.png` — 红色矩形 24x24
- `assets/enemy_assassin.png` — 紫色矩形 24x24
- `assets/projectile.png` — 黄色小方块 8x8
- `assets/floor_tile.png` — 深灰 32x32 地板砖

- [ ] **Step 2: 更新场景 Sprite 引用**

将 player.tscn、enemy_base.tscn、projectile.tscn 中的 Sprite2D texture 指向对应图片。

- [ ] **Step 3: Commit**

```bash
git add assets/
git commit -m "feat: add placeholder pixel art assets"
```

---

### Task 19: 最终测试与修复

**Files:**
- Create: 各测试整合

- [ ] **Step 1: 运行所有单元测试**

```bash
# 在 GUT 面板中 Run All
# Expected: 全部 PASS（约 10-12 个测试）
```

- [ ] **Step 2: 手动测试清单**

逐项验证：
- [ ] WASD 移动流畅
- [ ] 自动普攻命中最近敌人
- [ ] 敌人追踪玩家并造成伤害
- [ ] 波次递增，敌人数正确
- [ ] 升级弹窗暂停游戏、可 3 选 1
- [ ] 装备系统正确影响属性
- [ ] 技能释放有冷却、方向正确
- [ ] 死亡结算正确计算奖励
- [ ] 存档读写正常
- [ ] 装备菜单可切换装备

- [ ] **Step 3: 修复发现的问题**

记录并逐一解决手动测试中发现的问题。

- [ ] **Step 4: 最终 Commit**

```bash
git add -A
git commit -m "feat: complete jianghu survivor v1.0"
```

---
