extends CanvasLayer

func _ready():
	hide()

func _input(event):
	if event.is_action_pressed("ui_cancel"):  # ESC
		toggle_pause()

func toggle_pause():
	if visible:
		resume()
	else:
		pause()

func pause():
	visible = true
	get_tree().paused = true

func resume():
	visible = false
	get_tree().paused = false

func _on_resume_button_pressed() -> void:
	resume()


func _on_restart_button_pressed() -> void:
	resume()
	get_tree().reload_current_scene()


func _on_main_menu_button_pressed() -> void:
	resume()
	get_tree().change_scene_to_file("res://scenes/ui/menus/main_menu.tscn")
