extends Control

var canvas : CanvasLayer
var main : Node2D
var tower_manager : Node
var game_manager : Node
var level_manager : Node
var main_tower: Node
@onready var status_label: Label = $MarginContainer/VSplitContainer/VBoxContainer/StatusLabel
@onready var currency_label: Label = $MarginContainer/VSplitContainer/CurrencyLabel
@onready var health_bar: ProgressBar = $MarginContainer/HBoxContainer/HealthBar
@onready var wave_label: Label = $MarginContainer/HBoxContainer/WaveLabel
## Escenas de torres (asignar en el inspector)
@export var basic_tower_scene: PackedScene
@export var basic_tower_sprite: Texture2D
@export var radar_tower_scene: PackedScene
@export var radar_tower_sprite: Texture2D

func _ready() -> void:
	canvas = get_parent()
	main = canvas.get_parent()
	tower_manager = main.get_node("TowerManager")
	game_manager = main.get_node("GameManager")
	level_manager = main.get_node("LevelManager")
	if level_manager and level_manager.current_level:
		main_tower = level_manager.current_level.get_node("MainTower")
	currency_label.text = str("Currency: ", game_manager.player_currency)
	connect_signals()

func connect_signals() -> void:
	# Conectar señales del TowerManager
	if tower_manager:
		tower_manager.tower_placed.connect(_on_tower_placed)
		tower_manager.tower_selected.connect(_on_tower_selected)
		tower_manager.placement_cancelled.connect(_on_placement_cancelled)
	if game_manager:
		game_manager.currency_changed.connect(update_currency_display)
		game_manager.wave_started.connect(_on_wave_started)
		game_manager.wave_completed.connect(_on_wave_completed)
	
	if main_tower:
		main_tower.health_changed.connect(_on_health_changed)
		_on_health_changed(main_tower.health)  # Inicializar

func _on_basic():
	if not tower_manager or not basic_tower_scene:
		print("Error: TowerManager o escena de torre no configurada")
		return
	
	var tower_data = {
		"name": "Torre Básica",
		"cost": 100,
		"sprite": basic_tower_sprite,
		"description": "Torre de ataque básico",
		"offset": -24.0
	}
	
	tower_manager.select_tower(basic_tower_scene, tower_data)
	print("Torre seleccionada desde UI")

func _on_tower_placed(tower: Node, position: Vector2) -> void:
	update_status("TOWER PLACED IN: " + str(position))
	
	update_tower_count()

func _on_tower_selected(tower_data: Dictionary) -> void:
	var tower_name = tower_data.get("name", "Torre")
	update_status("PLACING: " + tower_name + " - LEFT CLICK TO CONFIRM, ESC OR RIGTH CLICK TO CANCEL")

func _on_placement_cancelled() -> void:
	update_status("PLACING CANCELED")

func update_status(message: String) -> void:
	if status_label:
		status_label.text = message
	print("UI Status: ", message)

func update_tower_count() -> void:
	if tower_manager:
		var count = tower_manager.get_towers_count()
		print("Torres totales: ", count)

## Ejemplo de función para actualizar UI con recursos
func update_currency_display(player_currency: int) -> void:
	currency_label.text = str("Currency: ", player_currency)

func _on_radar():
	if not tower_manager or not basic_tower_scene:
		print("Error: TowerManager o escena de torre no configurada")
		return
	
	var tower_data = {
		"name": "Torre Radar",
		"cost": 100,
		"sprite": radar_tower_sprite,
		"description": "Torre de ataque por area",
		"offset": -24.0
	}
	
	tower_manager.select_tower(radar_tower_scene, tower_data)
	print("Torre seleccionada desde UI")

func _on_sniper():
	tower_manager.select_tower("sniper")


func _on_t_1_button_pressed() -> void:
	_on_basic()


func _on_t_2_button_pressed() -> void:
	_on_radar()

func _on_health_changed(new_health: float):
	"""Actualiza barra de vida de la torre"""
	if health_bar and main_tower:
		health_bar.value = (new_health / main_tower.max_health) * 100
		#health_label.text = "Base Health: %.0f/%.0f" % [new_health, main_tower.max_health]

func _on_wave_started(wave_index: int):
	"""Actualiza indicador de oleada"""
	if wave_label and game_manager:
		var total = game_manager.waves.size()
		wave_label.text = "Wave %d/%d - IN PROGRESS" % [wave_index + 1, total]

func _on_wave_completed(wave_index: int):
	"""Muestra oleada completada"""
	if wave_label and game_manager:
		var total = game_manager.waves.size()
		var next = wave_index + 2
		
		if next <= total:
			wave_label.text = "Wave %d/%d - COMPLETE | Next wave in 5s" % [wave_index + 1, total]
		else:
			wave_label.text = "All waves complete!"
