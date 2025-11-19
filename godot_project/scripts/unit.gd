extends CharacterBody2D

signal died

var owner_id: int = 1
var health: float = 1.0
var max_health: float = 1.0
var unit_type: String = "soldier"
var game_manager: Node2D

var state: String = "idle"
var target: Node2D = null
var target_pos: Vector2 = Vector2.ZERO
var attack_cooldown: float = 0.0

var is_selected: bool = false

func _ready() -> void:
	add_to_group("units")
	modulate = GameConfig.PLAYER_COLORS[owner_id]

func _process(delta: float) -> void:
	attack_cooldown -= delta

	match state:
		"moving":
			process_movement(delta)
		"attacking":
			process_attack(delta)
		"idle":
			find_nearby_enemies()

	# Keep unit in bounds
	global_position.x = clamp(global_position.x, 5, GameConfig.MAP_WIDTH - 5)
	global_position.y = clamp(global_position.y, 5, GameConfig.MAP_HEIGHT - 5)

	queue_redraw()

func process_movement(delta: float) -> void:
	if target_pos == Vector2.ZERO:
		state = "idle"
		return

	var direction = target_pos - global_position
	var distance = direction.length()

	if distance < 2:
		state = "idle"
		target_pos = Vector2.ZERO
	else:
		var speed = GameConfig.MOVE_SPEED * delta
		var move_dir = direction.normalized()

		# Check collision with enemy walls
		var can_move = true
		for building in game_manager.buildings:
			if building.building_type == "wall" and building.owner_id != owner_id:
				var new_pos = global_position + move_dir * speed
				if building.global_position.distance_to(new_pos) < building.size + 3:
					can_move = false
					break

		if can_move:
			global_position += move_dir * speed

func process_attack(delta: float) -> void:
	if not is_instance_valid(target):
		target = null
		state = "idle"
		return

	var distance = global_position.distance_to(target.global_position)

	# Move towards target if out of range
	if distance > GameConfig.ATTACK_RANGE:
		var direction = (target.global_position - global_position).normalized()
		global_position += direction * GameConfig.MOVE_SPEED * delta
	elif attack_cooldown <= 0:
		# Attack
		var damage = GameConfig.ATTACK_DAMAGE * delta

		# Apply defense bonuses
		if game_manager.is_near_tower(target, target.owner_id):
			damage *= (1.0 - GameConfig.TOWER_DEFENSE_BONUS)
		if game_manager.is_behind_wall(target, self):
			damage *= (1.0 - GameConfig.WALL_DEFENSE_BONUS)

		target.take_damage(damage)
		attack_cooldown = 0.1

func find_nearby_enemies() -> void:
	var nearby = SpatialHash.query(global_position, GameConfig.ATTACK_RANGE)

	for entity in nearby:
		if entity.owner_id != owner_id and entity.owner_id != 0:
			if entity.has_method("take_damage"):
				target = entity
				state = "attacking"
				return

func set_target(new_target: Node2D) -> void:
	target = new_target
	state = "attacking"
	target_pos = Vector2.ZERO

func move_to(pos: Vector2) -> void:
	target_pos = pos
	state = "moving"
	target = null

func take_damage(amount: float) -> void:
	health -= amount

	if health <= 0:
		emit_signal("died")
		game_manager.remove_entity(self)

func select() -> void:
	is_selected = true
	queue_redraw()

func deselect() -> void:
	is_selected = false
	queue_redraw()

func _draw() -> void:
	# Selection highlight
	if is_selected:
		draw_circle(Vector2.ZERO, GameConfig.UNIT_SIZE + 2, Color.WHITE)

	# Unit body
	draw_circle(Vector2.ZERO, GameConfig.UNIT_SIZE, GameConfig.PLAYER_COLORS[owner_id])

	# Health indicator
	if health < max_health:
		var health_color = Color.GREEN if health > 0.5 else Color.RED
		draw_circle(Vector2(0, -6), 2, health_color)

	# Defense bonus indicator
	if game_manager and game_manager.is_near_tower(self, owner_id):
		draw_arc(Vector2.ZERO, GameConfig.UNIT_SIZE + 1, 0, TAU, 32, Color("#60a5fa"), 1.0)
