extends StaticBody2D

signal destroyed

var owner_id: int = 1
var health: float = GameConfig.TOWER_HEALTH
var max_health: float = GameConfig.TOWER_HEALTH
var building_type: String = "tower"
var size: int = GameConfig.TOWER_SIZE
var game_manager: Node2D

var stored_units: int = 0
var last_spawn_time: float = 0.0

func _ready() -> void:
	add_to_group("buildings")

func _process(delta: float) -> void:
	# Tower attacks enemies in range
	attack_enemies(delta)
	queue_redraw()

func attack_enemies(delta: float) -> void:
	var nearby = SpatialHash.query(global_position, GameConfig.TOWER_RANGE)

	for entity in nearby:
		if entity.is_in_group("units") and entity.owner_id != owner_id:
			entity.take_damage(GameConfig.TOWER_DAMAGE * delta)
			break  # Only attack one target

func update_unit_generation(delta: float) -> void:
	if stored_units >= GameConfig.TOWER_MAX_STORED:
		return

	last_spawn_time += delta

	if last_spawn_time >= GameConfig.TOWER_UNIT_GEN_RATE:
		# Check if there's space to spawn
		var nearby = SpatialHash.query(global_position, GameConfig.TOWER_SPAWN_RADIUS)
		var friendly_count = 0

		for entity in nearby:
			if entity.is_in_group("units") and entity.owner_id == owner_id:
				friendly_count += 1

		if friendly_count < 30:
			# Spawn unit
			var angle = randf() * TAU
			var radius = 15 + randf() * GameConfig.TOWER_SPAWN_RADIUS
			var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * radius

			game_manager.create_unit(spawn_pos, owner_id)
			last_spawn_time = 0.0

func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		emit_signal("destroyed")
		game_manager.remove_entity(self)

func _draw() -> void:
	var color = GameConfig.PLAYER_COLORS[owner_id]

	# Defense aura
	draw_circle(Vector2.ZERO, GameConfig.TOWER_AURA_RANGE, Color(color, 0.1))
	draw_arc(Vector2.ZERO, GameConfig.TOWER_AURA_RANGE, 0, TAU, 64, Color(color, 0.3), 1.0)

	# Attack range (dashed)
	var dash_count = 32
	for i in range(dash_count):
		if i % 2 == 0:
			var start_angle = (float(i) / dash_count) * TAU
			var end_angle = (float(i + 1) / dash_count) * TAU
			draw_arc(Vector2.ZERO, GameConfig.TOWER_RANGE, start_angle, end_angle, 8, Color(color, 0.2), 1.0)

	# Tower body
	draw_circle(Vector2.ZERO, size, color)

	# Tower inner
	draw_circle(Vector2.ZERO, size * 0.6, Color("#0a0a15"))

	# Health bar
	var health_pct = health / max_health
	draw_rect(Rect2(-15, -size - 8, 30, 4), Color("#333333"))

	var health_color = Color.GREEN
	if health_pct <= 0.5:
		health_color = Color("#fbbf24")
	if health_pct <= 0.25:
		health_color = Color.RED

	draw_rect(Rect2(-15, -size - 8, 30 * health_pct, 4), health_color)
