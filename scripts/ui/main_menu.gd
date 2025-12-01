extends Control


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/level_select.tscn")


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/menus/options_menu.tscn")
