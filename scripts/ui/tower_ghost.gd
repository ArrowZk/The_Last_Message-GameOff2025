extends Node2D
class_name TowerGhost
@onready var sprite: Sprite2D = $Sprite2D

const VALID_COLOR = Color(0, 1, 0, 0.6)
const INVALID_COLOR = Color(1, 0, 0, 0.6)

var is_valid: bool = false

func _ready() -> void:
	# Asegurar que comienza invisible
	visible = false
	z_index = 100

func set_preview_scene(tower_scene: PackedScene) -> void:
	"""Configura el sprite del ghost desde una escena de torre"""
	if not tower_scene:
		return
	
	var temp_instance = tower_scene.instantiate()
	
	#Obtener el sprite de la torre
	if temp_instance.has_node("Sprite2D"):
		var tower_sprite = temp_instance.get_node("Sprite2D")
		sprite.texture = tower_sprite.texture
		sprite.offset = tower_sprite.offset
		sprite.scale = tower_sprite.scale
	
	temp_instance.queue_free()

func set_preview_texture(texture: Texture2D) -> void:
	"""Configura directamente la textura del ghost"""
	if sprite:
		sprite.texture = texture

func set_valid(valid: bool) -> void:
	"""Actualiza el color según si la posición es válida"""
	is_valid = valid
	sprite.modulate = VALID_COLOR if valid else INVALID_COLOR

func show_ghost() -> void:
	visible = true

func hide_ghost() -> void:
	visible = false
