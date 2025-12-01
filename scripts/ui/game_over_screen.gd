extends CanvasLayer

## ==================================================
## PANTALLA DE GAME OVER
## ==================================================

func _ready():
	hide()
	# Configurar Process Mode para que funcione en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_game_over():
	"""Muestra la pantalla de derrota"""
	show()
	get_tree().paused = true
	
	print("💀 Game Over!")

func _on_retry_button_pressed() -> void:
	"""Reinicia el nivel actual"""
	get_tree().paused = false
	print("Restarting level...")
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	"""Regresa al menú principal"""
	get_tree().paused = false
	print("Returning to main menu")
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
