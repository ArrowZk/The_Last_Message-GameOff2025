extends Node
class_name TowerManager

## Referencias a nodos del nivel
@onready var level_manager = get_node_or_null("../LevelManager")
@onready var tower_root = get_node_or_null("../Towers")
@onready var tower_action_menu = get_node_or_null("../CanvasLayer/TowerActionMenu")
@onready var audio_player = AudioStreamPlayer.new()

var tilemap_layer: TileMapLayer = null
var camera: Camera2D = null

## Ghost/Silueta de torre
var ghost_tower: Sprite2D = null
var selected_tower_scene: PackedScene = null
var selected_tower_data: Dictionary = {}

## Estado del manager
var is_placing_tower: bool = false
var can_place: bool = false
var current_tile_pos: Vector2i
var occupied_cells := {}  # Dictionary: Vector2i -> Node (la torre)

## Ajuste de ancla para colocar la torre
var CELL_ANCHOR := Vector2(0,0)  # Centro del tile
var TOWER_HEIGHT_OFFSET : float

## Colores para el ghost
const VALID_COLOR = Color(0, 1, 0, 0.6)  # Verde semi-transparente
const INVALID_COLOR = Color(1, 0, 0, 0.6)  # Rojo semi-transparente

## Señales
signal tower_placed(tower: Node, position: Vector2)
signal tower_selected(tower_data: Dictionary)
signal placement_cancelled()

func _ready() -> void:
	setup_references()
	create_ghost()
	set_process_input(true)
	add_child(audio_player)
	# Conectar señal del menú
	if tower_action_menu:
		tower_action_menu.tower_destroy_requested.connect(_on_tower_destroy_requested)

func setup_references() -> void:
	# Obtener cámara
	camera = get_viewport().get_camera_2d()
	
	# Esperar un frame para que el nivel se cargue
	await get_tree().process_frame
	
	# Buscar TileMapLayer del nivel cargado
	if level_manager and level_manager.current_level and level_manager.current_level:
		tilemap_layer = level_manager.current_level.get_node_or_null("TileMapLayer")
		if not tilemap_layer:
			push_warning("No se encontró TileMapLayer en el nivel actual")
	else:
		# Búsqueda alternativa
		var level = get_tree().get_first_node_in_group("level")
		if level:
			tilemap_layer = level.get_node_or_null("TileMapLayer")
	
	if not tower_root:
		push_warning("No se encontró nodo Towers")

func create_ghost() -> void:
	ghost_tower = Sprite2D.new()
	ghost_tower.z_index = 100  # Encima de todo
	ghost_tower.modulate = VALID_COLOR
	ghost_tower.visible = false
	add_child(ghost_tower)

func _process(delta: float) -> void:
	if is_placing_tower and tilemap_layer:
		update_ghost_position()
		check_placement_validity()

func _input(event: InputEvent) -> void:
	# Cancelar con click derecho o ESC
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if is_placing_tower:
			cancel_placement()
			return
	
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if is_placing_tower:
			cancel_placement()
			return
	
	# Confirmar colocación con clic izquierdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("=== CLICK DETECTADO ===")
		print("is_placing_tower: ", is_placing_tower)
		print("can_place: ", can_place)
		print("is_mouse_over_ui: ", is_mouse_over_ui())
		
		if not is_placing_tower:
			# NO hay torre seleccionada para colocar
			# Verificar si hicieron click en una torre existente
			check_tower_click()
			return
		
		# Ignorar clicks sobre UI
		if is_mouse_over_ui():
			print("❌ Click sobre UI ignorado")
			return
		
		if can_place:
			print("✅ Colocando torre...")
			place_tower()
		else:
			print("❌ No se puede colocar aquí")
			print("   - Tile pos: ", current_tile_pos)
			print("   - Occupied cells: ", occupied_cells.keys())
			# Audio de error
			#play_sound("res://audio/sfx/error.wav")
		
func select_tower(tower_scene: PackedScene, tower_data: Dictionary = {}) -> void:
	"""
	Inicia el modo de colocación de torre
	tower_scene: La escena empaquetada de la torre
	tower_data: Datos adicionales (costo, sprite, etc.)
	"""
	if not tower_scene:
		push_error("TowerManager: No se proporcionó escena de torre válida")
		return
	
	if not tilemap_layer:
		push_error("TowerManager: TileMapLayer no está disponible")
		return
	
	selected_tower_scene = tower_scene
	selected_tower_data = tower_data
	is_placing_tower = true
	
	# Configurar sprite del ghost
	if tower_data.has("sprite") and tower_data.sprite:
		ghost_tower.texture = tower_data.sprite
		TOWER_HEIGHT_OFFSET = tower_data.offset
		print(TOWER_HEIGHT_OFFSET)
	else:
		# Intentar obtener sprite de la escena
		var temp_instance = tower_scene.instantiate()
		if temp_instance.has_node("Sprite2D"):
			ghost_tower.texture = temp_instance.get_node("Sprite2D").texture
		temp_instance.queue_free()
	
	ghost_tower.visible = true
	tower_selected.emit(tower_data)

func check_tower_click() -> void:
	"""Verifica si se hizo click en una torre existente"""
	var mouse_pos = get_global_mouse_position()
	var clicked_tower = get_tower_at_position(mouse_pos)
	
	if clicked_tower:
		show_tower_menu(clicked_tower)

func get_tower_at_position(pos: Vector2) -> Node:
	"""Busca si hay una torre en la posición del click"""
	if not tower_root:
		return null
	
	var closest_tower = null
	var closest_distance = 50.0  # Radio de detección en píxeles
	
	for tower in tower_root.get_children():
		var distance = tower.global_position.distance_to(pos)
		if distance < closest_distance:
			closest_distance = distance
			closest_tower = tower
	
	return closest_tower

func show_tower_menu(tower: Node) -> void:
	"""Muestra el menú de acciones para una torre"""
	if tower_action_menu:
		tower_action_menu.show_for_tower(tower)

func _on_tower_destroy_requested(tower: Node) -> void:
	"""Callback cuando el jugador confirma destruir torre"""
	print("💥 Destruyendo torre: ", tower.name)
	
	# Reembolso
	var refund = 0
	if "cost" in tower:
		refund = int(tower.cost * 0.5)  # 50% de reembolso
		var game_manager = get_tree().get_first_node_in_group("game_manager")
		if game_manager:
			game_manager.add_currency(refund)
			print("💰 Reembolso: ", refund)
	
	remove_tower(tower)

func update_ghost_position() -> void:
	if not tilemap_layer or not ghost_tower:
		return
	
	# Obtener posición del mouse en el mundo
	var global_mouse = get_global_mouse_position()
	
	# Convertir a coordenadas locales del TileMapLayer
	var local_mouse = tilemap_layer.to_local(global_mouse)
	
	# Obtener celda (Vector2i)
	var cell = tilemap_layer.local_to_map(local_mouse)
	current_tile_pos = cell
	
	# Obtener la posición local (origen) de la celda
	var local_cell_pos = tilemap_layer.map_to_local(cell)
	
	# Calcular offset según ancla (convertir tile_size a Vector2)
	var tile_size = Vector2(tilemap_layer.tile_set.tile_size)
	var offset = tile_size * CELL_ANCHOR
	
	#Offset para que sea visualmente aceptable
	offset.y += TOWER_HEIGHT_OFFSET
	
	# Transformar a global
	var global_cell_pos = tilemap_layer.to_global(local_cell_pos + offset)
	
	ghost_tower.global_position = global_cell_pos

func check_placement_validity() -> void:
	if not tilemap_layer:
		can_place = false
		ghost_tower.modulate = INVALID_COLOR
		return
	
	# Verificar si el tile permite construcción
	var tile_data = tilemap_layer.get_cell_tile_data(current_tile_pos)
	
	if tile_data == null:
		can_place = false
		ghost_tower.modulate = INVALID_COLOR
		return
	
	# Verificar custom data "TowerPlacement"
	var can_build = tile_data.get_custom_data("TowerPlacement")
	
	# Debug
	if can_build != true:
		# print("⚠️ Tile ", current_tile_pos, " no tiene TowerPlacement habilitado")
		pass
	
	if can_build:
		# Verificar que no haya otra torre en esa posición
		can_place = not occupied_cells.has(current_tile_pos)
		
		if not can_place:
			# print("⚠️ Tile ", current_tile_pos, " ya está ocupado")
			pass
	else:
		can_place = false
	
	# Verificar costo
	if can_place:
		var cost = selected_tower_data.get("cost", 0)
		can_place = can_afford(cost)
	
	# Actualizar color del ghost
	ghost_tower.modulate = VALID_COLOR if can_place else INVALID_COLOR

func place_tower() -> void:
	if not can_place or not selected_tower_scene:
		return
	
	# Verificar costo
	var cost = selected_tower_data.get("cost", 0)
	if not can_afford(cost):
		print("No tienes suficientes recursos para construir esta torre")
		return
	
	# Instanciar torre
	var tower = selected_tower_scene.instantiate()
	
	# Calcular posición exacta con ancla
	var local_cell_pos = tilemap_layer.map_to_local(current_tile_pos)
	var tile_size = Vector2(tilemap_layer.tile_set.tile_size)
	var offset = tile_size * CELL_ANCHOR
	
	# Ajustar
	offset.y += TOWER_HEIGHT_OFFSET
	
	var world_pos = tilemap_layer.to_global(local_cell_pos + offset)
	
	tower.global_position = world_pos
	
	# Agregar al contenedor
	if tower_root:
		tower_root.add_child(tower)
	else:
		get_tree().current_scene.add_child(tower)
	#play_sound("res://audio/sfx/tower_place.wav")
	
	# Configurar frecuencia global
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and tower.has_method("set_frequency"):
		# Esperar un frame para que la torre se inicialice
		await get_tree().process_frame
		if tower.has_method("can_use_frequency") and tower.can_use_frequency(game_manager.global_frequency):
			tower.set_frequency(game_manager.global_frequency)
	
	# Marcar celda como ocupada
	occupied_cells[current_tile_pos] = tower
	
	# Emitir señal
	tower_placed.emit(tower, world_pos)
	
	# Deducir costo
	deduct_resources(cost)
	
	print("Torre colocada en: ", world_pos, " (tile: ", current_tile_pos, ")")

func can_afford(cost: int) -> bool:
	"""Verifica si el jugador puede pagar la torre"""
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if game_manager and game_manager.has_method("get_currency"):
		return game_manager.get_currency() >= cost
	return false

func deduct_resources(cost: int) -> void:
	"""Deduce el costo de la torre"""
	var game_manager = get_node_or_null("/root/Main/GameManager")
	if game_manager and game_manager.has_method("spend_currency"):
		game_manager.spend_currency(cost)

func cancel_placement() -> void:
	"""Cancela el modo de colocación de torre"""
	is_placing_tower = false
	can_place = false
	selected_tower_scene = null
	selected_tower_data = {}
	
	if ghost_tower:
		ghost_tower.visible = false
	
	placement_cancelled.emit()
	print("Colocación de torre cancelada")

func play_sound(sound_path: String):
	if FileAccess.file_exists(sound_path):
		audio_player.stream = load(sound_path)
		audio_player.play()

## Métodos de utilidad
func get_global_mouse_position() -> Vector2:
	"""Obtiene la posición del mouse en coordenadas globales"""
	if camera:
		return camera.get_global_mouse_position()
	return get_viewport().get_mouse_position()

func is_mouse_over_ui() -> bool:
	"""Comprueba si el mouse está sobre un Control UI que bloquea clicks"""
	var hovered = get_viewport().gui_get_hovered_control()
	
	if hovered == null:
		return false
	
	var blocking_controls = ["Button", "TextEdit", "LineEdit", "ItemList", "OptionButton", "CheckBox"]
	
	for control_type in blocking_controls:
		if hovered.is_class(control_type):
			return true
	
	if hovered.mouse_filter == Control.MOUSE_FILTER_STOP:
		return true
	
	return false

func get_mouse_tile_position() -> Vector2i:
	"""Retorna la posición del tile bajo el mouse"""
	if not tilemap_layer:
		return Vector2i.ZERO
	
	var global_mouse = get_global_mouse_position()
	var local_mouse = tilemap_layer.to_local(global_mouse)
	return tilemap_layer.local_to_map(local_mouse)

func get_towers_count() -> int:
	"""Retorna el número de torres colocadas"""
	if tower_root:
		return tower_root.get_child_count()
	return 0

func remove_tower(tower: Node) -> void:
	"""Elimina una torre del juego"""
	if tower and is_instance_valid(tower):
		# Buscar y eliminar de occupied_cells
		for cell in occupied_cells.keys():
			if occupied_cells[cell] == tower:
				occupied_cells.erase(cell)
				break
		
		tower.queue_free()

func get_all_towers() -> Array:
	"""Retorna array con todas las torres activas"""
	if tower_root:
		return tower_root.get_children()
	return []

func debug_clear_occupied() -> void:
	"""Limpia todas las celdas ocupadas (útil para debugging)"""
	occupied_cells.clear()
	print("Celdas ocupadas limpiadas")
