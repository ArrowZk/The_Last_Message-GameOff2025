extends Camera2D
class_name GameCamera

## ==================================================
## CÁMARA DEL JUEGO - Movement por bordes y zoom
## ==================================================

## Configuración de movimiento
@export var edge_margin: float = 50.0  # Píxeles del borde para activar
@export var camera_speed: float = 500.0
@export var smooth_speed: float = 10.0

## Configuración de zoom
@export var zoom_min: float = 0.5
@export var zoom_max: float = 2.0
@export var zoom_speed: float = 0.1


## Variables internas
var target_position: Vector2
var target_zoom: Vector2
var viewport_size: Vector2

func _ready():
	# Configurar límites
	limit_left = limit_left
	limit_right = limit_right
	limit_top = limit_top
	limit_bottom = limit_bottom
	
	# Inicializar zoom
	target_zoom = zoom
	
	# Centrar en nivel
	call_deferred("center_on_level")

func center_on_level():
	"""Centra la cámara en el nivel al inicio"""
	var center_x = (limit_left + limit_right) / 2.0
	var center_y = (limit_top + limit_bottom) / 2.0
	global_position = Vector2(center_x, center_y)
	target_position = global_position

func _process(delta):
	viewport_size = get_viewport_rect().size
	
	# Movimiento por bordes
	handle_edge_movement(delta)
	
	# Aplicar movimiento suave
	global_position = global_position.lerp(target_position, smooth_speed * delta)
	
	# Aplicar zoom suave
	zoom = zoom.lerp(target_zoom, smooth_speed * delta)

func handle_edge_movement(delta):
	"""Mueve la cámara cuando el mouse está en los bordes"""
	var mouse_pos = get_viewport().get_mouse_position()
	var movement = Vector2.ZERO
	
	# Borde izquierdo
	if mouse_pos.x < edge_margin:
		movement.x -= 1.0
	
	# Borde derecho
	if mouse_pos.x > viewport_size.x - edge_margin:
		movement.x += 1.0
	
	# Borde superior
	if mouse_pos.y < edge_margin:
		movement.y -= 1.0
	
	# Borde inferior
	if mouse_pos.y > viewport_size.y - edge_margin:
		movement.y += 1.0
	
	# Aplicar movimiento
	if movement != Vector2.ZERO:
		target_position += movement.normalized() * camera_speed * delta
		
		# Aplicar límites
		target_position.x = clamp(target_position.x, limit_left, limit_right)
		target_position.y = clamp(target_position.y, limit_top, limit_bottom)

func _input(event):
	"""Maneja zoom con rueda del mouse"""
	if event is InputEventMouseButton:
		# Zoom in (rueda arriba)
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			target_zoom += Vector2.ONE * zoom_speed
			target_zoom = target_zoom.clamp(Vector2.ONE * zoom_min, Vector2.ONE * zoom_max)
		
		# Zoom out (rueda abajo)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			target_zoom -= Vector2.ONE * zoom_speed
			target_zoom = target_zoom.clamp(Vector2.ONE * zoom_min, Vector2.ONE * zoom_max)

func is_mouse_over_ui() -> bool:
	"""Verifica si el mouse está sobre UI"""
	return get_viewport().gui_get_hovered_control() != null

## ==================================================
## CONFIGURAR LÍMITES POR NIVEL
## ==================================================

func set_level_limits(left: int, right: int, top: int, bottom: int):
	"""Configura los límites para el nivel actual"""
	limit_left = left
	limit_right = right
	limit_top = top
	limit_bottom = bottom
	
	print("Camera limits set | L: %d R: %d T: %d B: %d" % [left, right, top, bottom])
	
	# Recentrar si está fuera de límites
	target_position.x = clamp(target_position.x, left, right)
	target_position.y = clamp(target_position.y, top, bottom)
