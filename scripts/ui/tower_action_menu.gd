extends Panel
class_name TowerActionMenu

@onready var destroy_button: Button = $VBoxContainer/DestroyButton
@onready var cancel_button: Button = $VBoxContainer/CancelButton

var selected_tower: Node = null

signal tower_destroy_requested(tower)

func _ready():
	# Conectar botones
	destroy_button.pressed.connect(_on_destroy_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	# Esconder al inicio
	hide()

func show_for_tower(tower: Node):
	"""Muestra el menú para una torre específica"""
	selected_tower = tower
	
	# Posicionar el menú cerca de la torre
	var offset = Vector2(-50, -50)  # Arriba de la torre
	global_position = tower.global_position + offset
	
	show()

func _on_destroy_pressed():
	"""Cuando presionan Destruir"""
	if selected_tower:
		tower_destroy_requested.emit(selected_tower)
	hide()

func _on_cancel_pressed():
	"""Cuando presionan Cancelar"""
	hide()

func _input(event):
	"""Cerrar menú con ESC o click fuera"""
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE and visible:
			hide()
