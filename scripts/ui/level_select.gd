extends Control

@export var max_level: int = 2  # Niveles totales
@onready var grid = $TextureRect/MarginContainer/GridContainer

var unlocked_levels: int = 1  # Por ahora solo nivel 1

func _ready() -> void:
	create_level_buttons()
	load_progress()

func create_level_buttons():
	# Limpiar botones existentes
	for child in grid.get_children():
		child.queue_free()
	
	# Crear botón por cada nivel
	for i in range(max_level):
		var button = Button.new()
		button.text = "Level %d" % (i + 1)
		button.custom_minimum_size = Vector2(150, 150)
		
		# Bloquear niveles no desbloqueados
		if i >= unlocked_levels:
			button.disabled = true
			button.text += "\n🔒"
		
		button.pressed.connect(_on_level_selected.bind(i))
		grid.add_child(button)

func _on_level_selected(level_id: int):
	# Guardar nivel seleccionado globalmente
	GLOBAL.selected_level = level_id
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func load_progress():
	# Cargar progreso guardado
	if FileAccess.file_exists("user://save.dat"):
		var file = FileAccess.open("user://save.dat", FileAccess.READ)
		unlocked_levels = file.get_32()
		file.close()
	
	create_level_buttons()

func unlock_next_level():
	unlocked_levels += 1
	save_progress()

func save_progress():
	var file = FileAccess.open("user://save.dat", FileAccess.WRITE)
	file.store_32(unlocked_levels)
	file.close()


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
