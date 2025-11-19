extends Node2D

signal game_over(player_won: bool)
signal resources_updated(player_id: int)
signal selection_changed(units: Array)

# Game state
var units: Array = []
var buildings: Array = []
var territories: Array = []

var players: Dictionary = {
	1: {
		"id": 1,
		"pixels": GameConfig.STARTING_PIXELS,
		"is_ai": false
	},
	2: {
		"id": 2,
		"pixels": GameConfig.STARTING_PIXELS,
		"is_ai": true
	}
}

var selected_units: Array = []
var build_mode: String = ""
var control_groups: Dictionary = {}

var game_time: float = 0.0
var is_paused: bool = false
var is_game_over: bool = false

var last_income_time: float = 0.0
var last_ai_update: float = 0.0

# Scene references
@onready var unit_scene: PackedScene = preload("res://scenes/unit.tscn")
@onready var tower_scene: PackedScene = preload("res://scenes/tower.tscn")
@onready var wall_scene: PackedScene = preload("res://scenes/wall.tscn")

@onready var units_container: Node2D = $Units
@onready var buildings_container: Node2D = $Buildings
@onready var territories_container: Node2D = $Territories
@onready var selection_box: Node2D = $SelectionBox
@onready var build_preview: Node2D = $BuildPreview
@onready var camera: Camera2D = $Camera2D
@onready var hud = $HUD
@onready var game_renderer: Node2D = $GameRenderer

func _ready() -> void:
	# Connect components
	camera.game_manager = self
	hud.connect_to_game_manager(self)
	game_renderer.game_manager = self
	game_renderer.camera = camera

	# Connect minimap
	var minimap = hud.get_node("Sidebar/MarginContainer/VBoxContainer/Minimap")
	if minimap:
		minimap.game_manager = self

	init_territories()
	spawn_starting_units()
	update_resource_display()

func _process(delta: float) -> void:
	if is_paused or is_game_over:
		return

	game_time += delta

	update_spatial_hash()
	update_ai(delta)
	update_buildings(delta)
	update_territory_ownership()
	update_economy(delta)
	check_win_condition()
	update_hud()

func init_territories() -> void:
	var cols: int = ceili(float(GameConfig.MAP_WIDTH) / GameConfig.TERRITORY_SIZE)
	var rows: int = ceili(float(GameConfig.MAP_HEIGHT) / GameConfig.TERRITORY_SIZE)

	for y in range(rows):
		for x in range(cols):
			var territory = {
				"x": x * GameConfig.TERRITORY_SIZE,
				"y": y * GameConfig.TERRITORY_SIZE,
				"owner": 0
			}
			territories.append(territory)

func spawn_starting_units() -> void:
	# Player 1 base (left side)
	var p1_base_x: float = GameConfig.MAP_WIDTH * 0.15
	var p1_base_y: float = GameConfig.MAP_HEIGHT * 0.5

	# Player 2 base (right side)
	var p2_base_x: float = GameConfig.MAP_WIDTH * 0.85
	var p2_base_y: float = GameConfig.MAP_HEIGHT * 0.5

	# Spawn initial tower for each player
	create_building(Vector2(p1_base_x, p1_base_y), "tower", 1)
	create_building(Vector2(p2_base_x, p2_base_y), "tower", 2)

	# Spawn starting units
	for i in range(100):
		var angle: float = (float(i) / 100.0) * TAU
		var radius: float = 40.0 + randf() * 30.0

		create_unit(
			Vector2(p1_base_x + cos(angle) * radius, p1_base_y + sin(angle) * radius),
			1
		)

		create_unit(
			Vector2(p2_base_x + cos(angle) * radius, p2_base_y + sin(angle) * radius),
			2
		)

	# Center camera on player 1 base
	camera.position = Vector2(p1_base_x, p1_base_y)

func create_unit(pos: Vector2, owner_id: int) -> Node2D:
	var unit = unit_scene.instantiate()
	unit.global_position = pos
	unit.owner_id = owner_id
	unit.game_manager = self
	units_container.add_child(unit)
	units.append(unit)
	return unit

func create_building(pos: Vector2, type: String, owner_id: int) -> Node2D:
	var building: Node2D

	if type == "tower":
		building = tower_scene.instantiate()
	else:
		building = wall_scene.instantiate()

	building.global_position = pos
	building.owner_id = owner_id
	building.game_manager = self
	buildings_container.add_child(building)
	buildings.append(building)

	if type == "tower":
		update_pop_cap()

	return building

func remove_entity(entity: Node2D) -> void:
	if entity.is_in_group("units"):
		units.erase(entity)
		selected_units.erase(entity)
	else:
		buildings.erase(entity)
		if entity.building_type == "tower":
			update_pop_cap()

	entity.queue_free()

func update_spatial_hash() -> void:
	SpatialHash.clear()
	for unit in units:
		if is_instance_valid(unit):
			SpatialHash.insert(unit)
	for building in buildings:
		if is_instance_valid(building):
			SpatialHash.insert(building)

func update_buildings(delta: float) -> void:
	for building in buildings:
		if not is_instance_valid(building):
			continue

		if building.building_type == "tower":
			building.update_unit_generation(delta)

func update_territory_ownership() -> void:
	for territory in territories:
		var center_x: float = territory.x + GameConfig.TERRITORY_SIZE / 2.0
		var center_y: float = territory.y + GameConfig.TERRITORY_SIZE / 2.0

		var nearby = SpatialHash.query(Vector2(center_x, center_y), GameConfig.TERRITORY_SIZE)
		var counts: Dictionary = {1: 0, 2: 0}

		for entity in nearby:
			if entity.is_in_group("units") and is_instance_valid(entity):
				counts[entity.owner_id] += 1

		if counts[1] > counts[2] and counts[1] >= 3:
			territory.owner = 1
		elif counts[2] > counts[1] and counts[2] >= 3:
			territory.owner = 2

func update_economy(delta: float) -> void:
	if game_time - last_income_time > GameConfig.INCOME_INTERVAL:
		for player_id in players.keys():
			var owned_territories: int = 0
			for t in territories:
				if t.owner == player_id:
					owned_territories += 1

			var income: int = owned_territories * GameConfig.INCOME_PER_TERRITORY
			players[player_id].pixels += income

		last_income_time = game_time
		update_resource_display()

func update_pop_cap() -> void:
	for player_id in players.keys():
		var tower_count: int = 0
		for b in buildings:
			if is_instance_valid(b) and b.building_type == "tower" and b.owner_id == player_id:
				tower_count += 1
		# Pop cap is BASE + towers * PER_TOWER

func update_ai(delta: float) -> void:
	if game_time - last_ai_update < GameConfig.AI_UPDATE_INTERVAL:
		return

	var ai_player = players[2]
	var ai_units: Array = []
	var player_units: Array = []
	var player_buildings: Array = []

	for u in units:
		if is_instance_valid(u):
			if u.owner_id == 2:
				ai_units.append(u)
			elif u.owner_id == 1:
				player_units.append(u)

	for b in buildings:
		if is_instance_valid(b) and b.owner_id == 1:
			player_buildings.append(b)

	# Attack if we have enough units
	if ai_units.size() > 50:
		var target = null

		if player_units.size() > 0:
			target = player_units[randi() % player_units.size()]
		elif player_buildings.size() > 0:
			target = player_buildings[0]

		if target:
			var attack_force = ai_units.slice(0, ai_units.size() / 2)
			for unit in attack_force:
				unit.set_target(target)

	# Build defenses
	var ai_tower_count: int = 0
	for b in buildings:
		if is_instance_valid(b) and b.owner_id == 2 and b.building_type == "tower":
			ai_tower_count += 1

	if ai_player.pixels >= GameConfig.TOWER_COST and ai_tower_count < 5:
		var base_x: float = GameConfig.MAP_WIDTH * 0.85
		var base_y: float = GameConfig.MAP_HEIGHT * 0.5
		var offset_x: float = (randf() - 0.5) * 200.0
		var offset_y: float = (randf() - 0.5) * 200.0

		ai_player.pixels -= GameConfig.TOWER_COST
		create_building(Vector2(base_x + offset_x, base_y + offset_y), "tower", 2)

	last_ai_update = game_time

func check_win_condition() -> void:
	var p1_units: int = 0
	var p2_units: int = 0
	var p1_buildings: int = 0
	var p2_buildings: int = 0

	for u in units:
		if is_instance_valid(u):
			if u.owner_id == 1:
				p1_units += 1
			else:
				p2_units += 1

	for b in buildings:
		if is_instance_valid(b):
			if b.owner_id == 1:
				p1_buildings += 1
			else:
				p2_buildings += 1

	if p1_units == 0 and p1_buildings == 0:
		end_game(false)
	elif p2_units == 0 and p2_buildings == 0:
		end_game(true)

func end_game(player_won: bool) -> void:
	is_game_over = true
	emit_signal("game_over", player_won)

func restart_game() -> void:
	# Clear entities
	for u in units:
		if is_instance_valid(u):
			u.queue_free()
	for b in buildings:
		if is_instance_valid(b):
			b.queue_free()

	units.clear()
	buildings.clear()
	selected_units.clear()
	territories.clear()

	game_time = 0.0
	is_game_over = false
	last_income_time = 0.0
	last_ai_update = 0.0

	players[1].pixels = GameConfig.STARTING_PIXELS
	players[2].pixels = GameConfig.STARTING_PIXELS

	init_territories()
	spawn_starting_units()
	update_resource_display()

# Selection and commands
func select_units_in_rect(rect: Rect2) -> void:
	selected_units.clear()

	if rect.size.length() < 5:
		# Click selection
		for u in units:
			if u.owner_id == 1:
				if u.global_position.distance_to(rect.position) < 10:
					selected_units.append(u)
					break
	else:
		# Box selection
		for u in units:
			if u.owner_id == 1 and rect.has_point(u.global_position):
				selected_units.append(u)

	emit_signal("selection_changed", selected_units)

func select_all_player_units() -> void:
	selected_units.clear()
	for u in units:
		if u.owner_id == 1:
			selected_units.append(u)
	emit_signal("selection_changed", selected_units)

func issue_command(target_pos: Vector2) -> void:
	if selected_units.is_empty():
		return

	# Check for enemy target
	var enemy_unit = null
	var enemy_building = null

	for u in units:
		if u.owner_id != 1 and u.global_position.distance_to(target_pos) < 15:
			enemy_unit = u
			break

	if not enemy_unit:
		for b in buildings:
			if b.owner_id != 1 and b.global_position.distance_to(target_pos) < b.size + 10:
				enemy_building = b
				break

	if enemy_unit or enemy_building:
		# Attack command
		var target = enemy_unit if enemy_unit else enemy_building
		for unit in selected_units:
			unit.set_target(target)
	else:
		# Move command with formation
		var count: int = selected_units.size()
		var cols: int = ceili(sqrt(count))
		var spacing: float = 8.0

		for i in range(count):
			var col: int = i % cols
			var row: int = i / cols
			var offset = Vector2(
				(col - cols / 2.0) * spacing,
				(row - count / cols / 2.0) * spacing
			)
			selected_units[i].move_to(target_pos + offset)

func set_build_mode(mode: String) -> void:
	build_mode = mode

func try_place_building(pos: Vector2) -> bool:
	if build_mode.is_empty():
		return false

	var cost: int = GameConfig.TOWER_COST if build_mode == "tower" else GameConfig.WALL_COST
	var size: int = GameConfig.TOWER_SIZE if build_mode == "tower" else GameConfig.WALL_SIZE

	# Check cost
	if players[1].pixels < cost:
		return false

	# Check placement validity
	for b in buildings:
		if b.global_position.distance_to(pos) < b.size + size:
			return false

	# Place building
	players[1].pixels -= cost
	create_building(pos, build_mode, 1)
	update_resource_display()

	build_mode = ""
	return true

func is_near_tower(entity: Node2D, owner_id: int) -> bool:
	for b in buildings:
		if is_instance_valid(b) and b.building_type == "tower" and b.owner_id == owner_id:
			if b.global_position.distance_to(entity.global_position) < GameConfig.TOWER_AURA_RANGE:
				return true
	return false

func is_behind_wall(defender: Node2D, attacker: Node2D) -> bool:
	var direction = attacker.global_position - defender.global_position
	var dist = direction.length()

	for wall in buildings:
		if not is_instance_valid(wall):
			continue
		if wall.building_type != "wall" or wall.owner_id != defender.owner_id:
			continue

		var wall_dist = wall.global_position.distance_to(defender.global_position)
		if wall_dist < dist and wall_dist < 30:
			var wall_angle = atan2(wall.global_position.y - defender.global_position.y,
								   wall.global_position.x - defender.global_position.x)
			var attack_angle = atan2(direction.y, direction.x)
			if abs(wall_angle - attack_angle) < PI / 4:
				return true

	return false

func update_resource_display() -> void:
	emit_signal("resources_updated", 1)

func update_hud() -> void:
	pass  # HUD updates itself

func get_player_territory_count(player_id: int) -> int:
	var count: int = 0
	for t in territories:
		if t.owner == player_id:
			count += 1
	return count

func get_player_unit_count(player_id: int) -> int:
	var count: int = 0
	for u in units:
		if is_instance_valid(u) and u.owner_id == player_id:
			count += 1
	return count

func get_player_tower_count(player_id: int) -> int:
	var count: int = 0
	for b in buildings:
		if is_instance_valid(b) and b.owner_id == player_id and b.building_type == "tower":
			count += 1
	return count
