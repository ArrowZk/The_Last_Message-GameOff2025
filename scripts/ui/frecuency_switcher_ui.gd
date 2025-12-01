extends PanelContainer
class_name FrequencySwitcherUI

## UI para cambiar frecuencia de torres seleccionadas

## Referencias (asignar en el inspector o autoload)
var selected_tower: TowerBase = null

## Nodos UI
@onready var panel: Panel = $Panel
@onready var tower_name_label: Label = $Panel/VBoxContainer/TowerName
@onready var frequency_label: Label = $Panel/VBoxContainer/CurrentFrequency
@onready var buttons_container: HBoxContainer = $Panel/VBoxContainer/FrequencyButtons

## Botones de frecuencia (creados dinámicamente)
var frequency_buttons := {}

## ========================================
## INICIALIZACIÓN
## ========================================
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.visible = false
	
	create_frequency_buttons()
	
	# Conectar con TowerManager para detectar selección
	var tower_manager = get_node_or_null("/root/Main/TowerManager")
	if tower_manager and tower_manager.has_signal("tower_placed"):
		tower_manager.tower_placed.connect(_on_tower_placed)

func create_frequency_buttons() -> void:
	"""Crea botones para cada frecuencia"""
	for freq_type in [Frequency.FrequencyType.BLUE, Frequency.FrequencyType.YELLOW, Frequency.FrequencyType.RED]:
		var button = Button.new()
		var freq_data = Frequency.get_frequency_data(freq_type)
		
		button.text = freq_data.name
		button.custom_minimum_size = Vector2(80, 40)
		
		# Estilizar con color de frecuencia
		var style = StyleBoxFlat.new()
		style.bg_color = freq_data.color
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", style)
		
		# Conectar señal
		button.pressed.connect(_on_frequency_button_pressed.bind(freq_type))
		
		buttons_container.add_child(button)
		frequency_buttons[freq_type] = button

## ========================================
## SELECCIÓN DE TORRE
## ========================================
func select_tower(tower: TowerBase) -> void:
	"""Selecciona una torre para cambiar su frecuencia"""
	selected_tower = tower
	
	if not selected_tower:
		panel.visible = false
		return
	
	# Actualizar UI
	update_ui()
	panel.visible = true
	
	# Posicionar panel cerca de la torre
	position_panel_near_tower()
	
	# Conectar señales de la torre
	if not selected_tower.frequency_changed.is_connected(_on_tower_frequency_changed):
		selected_tower.frequency_changed.connect(_on_tower_frequency_changed)

func deselect_tower() -> void:
	"""Deselecciona la torre actual"""
	if selected_tower and selected_tower.frequency_changed.is_connected(_on_tower_frequency_changed):
		selected_tower.frequency_changed.disconnect(_on_tower_frequency_changed)
	
	selected_tower = null
	panel.visible = false

func update_ui() -> void:
	"""Actualiza la información mostrada"""
	if not selected_tower:
		return
	
	var info = selected_tower.get_tower_info()
	
	tower_name_label.text = selected_tower.name
	frequency_label.text = "Frecuencia: %s" % info.frequency
	frequency_label.modulate = info.frequency_color
	
	# Actualizar botones (habilitar/deshabilitar según disponibilidad)
	for freq_type in frequency_buttons.keys():
		var button = frequency_buttons[freq_type]
		button.disabled = not selected_tower.can_use_frequency(freq_type)
		
		# Resaltar frecuencia activa
		if freq_type == selected_tower.current_frequency:
			button.modulate = Color(1.5, 1.5, 1.5)
		else:
			button.modulate = Color(1.0, 1.0, 1.0)

func position_panel_near_tower() -> void:
	"""Posiciona el panel cerca de la torre"""
	if not selected_tower:
		return
	
	# Obtener posición en pantalla
	var tower_screen_pos = get_viewport().get_camera_2d().get_screen_center_position()
	var tower_global_pos = selected_tower.global_position
	var offset = tower_global_pos - tower_screen_pos
	
	# Posicionar panel arriba de la torre
	panel.global_position = get_viewport().get_camera_2d().get_screen_center_position() + offset + Vector2(-60, -100)

## ========================================
## CALLBACKS
## ========================================
func _on_frequency_button_pressed(freq: Frequency.FrequencyType) -> void:
	"""Cuando se presiona un botón de frecuencia"""
	if not selected_tower:
		return
	
	selected_tower.set_frequency(freq)
	update_ui()
	
	print("🔄 Frecuencia cambiada a: %s" % Frequency.get_frequency_data(freq).name)

func _on_tower_frequency_changed(new_freq: Frequency.FrequencyType) -> void:
	"""Cuando la torre cambia de frecuencia"""
	update_ui()

func _on_tower_placed(tower: Node, position: Vector2) -> void:
	"""Cuando se coloca una torre nueva"""
	# Opcionalmente seleccionar automáticamente la torre recién colocada
	if tower is TowerBase:
		select_tower(tower)

## ========================================
## INPUT
## ========================================
func _input(event: InputEvent) -> void:
	# Click en el mapa para seleccionar torre
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		check_tower_selection_at_mouse()
	
	# Tecla para deseleccionar
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		deselect_tower()
	
	# Teclas rápidas para cambiar frecuencia (1, 2, 3)
	if selected_tower and event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if selected_tower.can_use_frequency(Frequency.FrequencyType.BLUE):
					selected_tower.set_frequency(Frequency.FrequencyType.BLUE)
			KEY_2:
				if selected_tower.can_use_frequency(Frequency.FrequencyType.YELLOW):
					selected_tower.set_frequency(Frequency.FrequencyType.YELLOW)
			KEY_3:
				if selected_tower.can_use_frequency(Frequency.FrequencyType.RED):
					selected_tower.set_frequency(Frequency.FrequencyType.RED)

func check_tower_selection_at_mouse() -> void:
	"""Detecta si se hizo click en una torre"""
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_2d()
	
	if not camera:
		return
	
	var world_mouse_pos = camera.get_global_mouse_position()
	
	# Buscar torres cerca del click
	var towers = get_tree().get_nodes_in_group("towers")
	var closest_tower: TowerBase = null
	var closest_distance = INF
	
	for tower in towers:
		if tower is TowerBase:
			var distance = tower.global_position.distance_to(world_mouse_pos)
			if distance < 50 and distance < closest_distance:  # Radio de selección: 50px
				closest_distance = distance
				closest_tower = tower
	
	if closest_tower:
		select_tower(closest_tower)
	else:
		deselect_tower()
