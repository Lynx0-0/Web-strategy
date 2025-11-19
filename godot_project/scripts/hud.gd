extends CanvasLayer

@onready var pixel_label: Label = $TopBar/Resources/PixelCount
@onready var territory_label: Label = $TopBar/Resources/TerritoryCount
@onready var unit_label: Label = $TopBar/Resources/UnitCount
@onready var pop_cap_label: Label = $TopBar/Resources/PopCapCount
@onready var time_label: Label = $BottomBar/TimeLabel
@onready var status_label: Label = $BottomBar/StatusLabel
@onready var selection_label: Label = $BottomBar/SelectionLabel

@onready var wall_button: Button = $Sidebar/BuildButtons/WallButton
@onready var tower_button: Button = $Sidebar/BuildButtons/TowerButton
@onready var selection_info: RichTextLabel = $Sidebar/SelectionInfo

@onready var minimap: Control = $Sidebar/Minimap
@onready var game_overlay: Control = $GameOverlay
@onready var overlay_title: Label = $GameOverlay/OverlayTitle
@onready var restart_button: Button = $GameOverlay/RestartButton

var game_manager: Node2D

func _ready() -> void:
	# Connect button signals
	wall_button.pressed.connect(_on_wall_button_pressed)
	tower_button.pressed.connect(_on_tower_button_pressed)
	restart_button.pressed.connect(_on_restart_button_pressed)

	game_overlay.visible = false

func _process(_delta: float) -> void:
	if not game_manager:
		return

	update_resources()
	update_time()
	update_minimap()

func connect_to_game_manager(manager: Node2D) -> void:
	game_manager = manager
	game_manager.resources_updated.connect(_on_resources_updated)
	game_manager.selection_changed.connect(_on_selection_changed)
	game_manager.game_over.connect(_on_game_over)

func update_resources() -> void:
	if not game_manager:
		return

	var player = game_manager.players[1]
	pixel_label.text = str(int(player.pixels))
	territory_label.text = str(game_manager.get_player_territory_count(1))
	unit_label.text = str(game_manager.get_player_unit_count(1))

	var towers = game_manager.get_player_tower_count(1)
	var pop_cap = GameConfig.BASE_POP_CAP + towers * GameConfig.POP_PER_TOWER
	pop_cap_label.text = str(pop_cap)

func update_time() -> void:
	if not game_manager:
		return

	var minutes = int(game_manager.game_time / 60)
	var seconds = int(game_manager.game_time) % 60
	time_label.text = "Tempo: %02d:%02d" % [minutes, seconds]

func update_minimap() -> void:
	minimap.queue_redraw()

func _on_resources_updated(_player_id: int) -> void:
	update_resources()

func _on_selection_changed(units: Array) -> void:
	var count = units.size()
	selection_label.text = "Selezionate: %d unità" % count

	if count == 0:
		selection_info.text = "Nessuna selezione.\nTrascina per selezionare unità."
	else:
		var avg_health = 0.0
		for u in units:
			avg_health += u.health
		avg_health /= count

		selection_info.text = "[b]%d[/b] unità selezionate\nSalute media: %d%%\nClick destro per comandare." % [count, int(avg_health * 100)]

func _on_game_over(player_won: bool) -> void:
	game_overlay.visible = true

	if player_won:
		overlay_title.text = "VITTORIA!"
		overlay_title.modulate = Color("#4ade80")
	else:
		overlay_title.text = "SCONFITTA"
		overlay_title.modulate = Color("#e94560")

func _on_wall_button_pressed() -> void:
	if game_manager:
		game_manager.set_build_mode("wall")
		update_build_buttons()

func _on_tower_button_pressed() -> void:
	if game_manager:
		game_manager.set_build_mode("tower")
		update_build_buttons()

func _on_restart_button_pressed() -> void:
	if game_manager:
		game_manager.restart_game()
		game_overlay.visible = false

func update_build_buttons() -> void:
	wall_button.button_pressed = game_manager.build_mode == "wall"
	tower_button.button_pressed = game_manager.build_mode == "tower"

func show_message(text: String) -> void:
	status_label.text = text
	status_label.modulate = Color("#ef4444")

	var timer = get_tree().create_timer(2.0)
	await timer.timeout

	status_label.text = "In gioco"
	status_label.modulate = Color("#4ade80")
