extends CanvasLayer

## ==================================================
## PANTALLA DE VICTORIA
## ==================================================

@onready var enemies_label = $Panel/VBoxContainer/StatsContainer/EnemiesKilled

func _ready():
	hide()
	# Configurar Process Mode para que funcione en pausa
	process_mode = Node.PROCESS_MODE_ALWAYS

func show_victory(stats: Dictionary):
	"""Muestra la pantalla de victoria con estadísticas"""
	var kills = stats.get("kills", 0)
	enemies_label.text = "Enemies Killed: %d" % kills
	
	show()
	get_tree().paused = true
	
	print("🎉 Victory! | Kills: %d" % kills)

func _on_next_level_button_pressed() -> void:
	
	"""Avanza al siguiente nivel"""
	get_tree().paused = false
	
	# Desbloquear siguiente nivel
	GLOBAL.unlock_next_level()
	GLOBAL.selected_level += 1
	if GLOBAL.selected_level < GLOBAL.max_levels_avaliable:
		print("Loading next level: %d" % GLOBAL.selected_level)
		get_tree().reload_current_scene()

func _on_main_menu_button_pressed() -> void:
	"""Regresa al menú principal"""
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
	print("Returning to main menu")
