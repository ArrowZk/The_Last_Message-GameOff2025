extends Control
class_name GlobalFrequencyUI

## UI para cambiar la frecuencia GLOBAL de todas las torres

@export var game_manager: Node

## Nodos UI (créalos en el editor)
@onready var frequency_label: Label = $Panel/VBoxContainer/FrequencyLabel
@onready var blue_button: Button = $Panel/VBoxContainer/HBoxContainer/BlueButton
@onready var yellow_button: Button = $Panel/VBoxContainer/HBoxContainer/YellowButton
@onready var red_button: Button = $Panel/VBoxContainer/HBoxContainer/RedButton
@onready var panel: Panel = $Panel

func _ready() -> void:
	# Buscar GameManager si no está asignado
	if not game_manager:
		game_manager = get_tree().get_first_node_in_group("game_manager")
		if not game_manager:
			push_error("GlobalFrequencyUI: No se encontró GameManager")
			return
	
	# Esperar un frame
	await get_tree().process_frame
	
	setup_buttons()
	connect_signals()
	update_ui()

func setup_buttons() -> void:
	"""Configura los botones de frecuencia"""
	if blue_button:
		blue_button.text = "BLUE"
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#7aa67d")
		style.border_color = Color("1277b6")
		style.border_width_bottom = 5
		style.border_width_left = 5
		style.border_width_right = 5
		style.border_width_top = 5
		style.set_corner_radius_all(5)
		blue_button.add_theme_stylebox_override("normal", style)
	
	if yellow_button:
		yellow_button.text = "YELLOW"
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#7aa67d")
		style.border_color = Color("bbad2a")
		style.border_width_bottom = 5
		style.border_width_left = 5
		style.border_width_right = 5
		style.border_width_top = 5
		style.set_corner_radius_all(5)
		yellow_button.add_theme_stylebox_override("normal", style)
	
	if red_button:
		red_button.text = "RED"
		var style = StyleBoxFlat.new()
		style.bg_color = Color("#7aa67d")
		style.border_color = Color("b12a1a")
		style.border_width_bottom = 5
		style.border_width_left = 5
		style.border_width_right = 5
		style.border_width_top = 5
		style.set_corner_radius_all(5)
		red_button.add_theme_stylebox_override("normal", style)

func connect_signals() -> void:
	"""Conecta señales de botones y GameManager"""
	if blue_button:
		blue_button.pressed.connect(_on_blue_button_pressed)
	
	if yellow_button:
		yellow_button.pressed.connect(_on_yellow_button_pressed)
	
	if red_button:
		red_button.pressed.connect(_on_red_button_pressed)
	
	# Conectar señal del GameManager
	if game_manager and game_manager.has_signal("global_frequency_changed"):
		game_manager.global_frequency_changed.connect(_on_global_frequency_changed)

func update_ui() -> void:
	"""Actualiza la UI con la frecuencia actual"""
	if not game_manager:
		return
	
	var freq_name = game_manager.get_global_frequency_name()
	var freq_color = game_manager.get_global_frequency_color()
	
	if frequency_label:
		frequency_label.text = "GLOBAL FREQUENCY: %s" % freq_name
		frequency_label.modulate = freq_color
	
	# Resaltar botón activo
	highlight_active_button()

func highlight_active_button() -> void:
	"""Resalta el botón de la frecuencia activa"""
	if not game_manager:
		return
	
	var current = game_manager.global_frequency
	
	# Resetear todos
	if blue_button:
		blue_button.modulate = Color(1.0, 1.0, 1.0)
	if yellow_button:
		yellow_button.modulate = Color(1.0, 1.0, 1.0)
	if red_button:
		red_button.modulate = Color(1.0, 1.0, 1.0)
	
	# Resaltar activo
	match current:
		Frequency.FrequencyType.BLUE:
			if blue_button:
				blue_button.modulate = Color(1.5, 1.5, 1.5)
		Frequency.FrequencyType.YELLOW:
			if yellow_button:
				yellow_button.modulate = Color(1.5, 1.5, 1.5)
		Frequency.FrequencyType.RED:
			if red_button:
				red_button.modulate = Color(1.5, 1.5, 1.5)

## ========================================
## CALLBACKS
## ========================================
func _on_blue_button_pressed() -> void:
	if game_manager:
		game_manager.set_global_frequency(Frequency.FrequencyType.BLUE)

func _on_yellow_button_pressed() -> void:
	if game_manager:
		game_manager.set_global_frequency(Frequency.FrequencyType.YELLOW)

func _on_red_button_pressed() -> void:
	if game_manager:
		game_manager.set_global_frequency(Frequency.FrequencyType.RED)

func _on_global_frequency_changed(new_freq: Frequency.FrequencyType) -> void:
	"""Callback cuando cambia la frecuencia global"""
	update_ui()

## ========================================
## INPUT (Atajos de teclado)
## ========================================
func _input(event: InputEvent) -> void:
	if not game_manager:
		return
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				game_manager.set_global_frequency(Frequency.FrequencyType.BLUE)
			KEY_2:
				game_manager.set_global_frequency(Frequency.FrequencyType.YELLOW)
			KEY_3:
				game_manager.set_global_frequency(Frequency.FrequencyType.RED)
			KEY_TAB:
				# Ciclar frecuencias con TAB
				game_manager.cycle_global_frequency()
