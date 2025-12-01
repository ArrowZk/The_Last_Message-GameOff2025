extends Node2D
class_name CurrencyPopup

## Popup flotante que muestra "+50" cuando enemigo muere

@onready var label: Label = $Label

var velocity: Vector2 = Vector2(0, -50)  # Flota hacia arriba
var lifetime: float = 1.0
var fade_speed: float = 2.0

func _ready():
	# Destruir después del lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func setup(amount: int, pos: Vector2):
	"""Configura el popup con cantidad y posición"""
	global_position = pos
	label.text = "+%d" % amount
	
	# Color según cantidad
	if amount >= 50:
		label.modulate = Color(1.0, 0.8, 0.0)  # Dorado
	elif amount >= 20:
		label.modulate = Color(0.0, 1.0, 0.5)  # Verde
	else:
		label.modulate = Color(1.0, 1.0, 1.0)  # Blanco

func _process(delta):
	# Mover hacia arriba
	global_position += velocity * delta
	
	# Fade out
	label.modulate.a -= fade_speed * delta

## ========================================
## FACTORY PARA CREAR POPUPS
## ========================================
static func create(amount: int, pos: Vector2, parent: Node) -> CurrencyPopup:
	"""Crea y agrega un popup al árbol"""
	var popup_scene = preload("res://scenes/ui/currency_popup.tscn")
	var popup = popup_scene.instantiate()
	parent.add_child(popup)
	popup.setup(amount, pos)
	return popup
