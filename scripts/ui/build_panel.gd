extends Control

@onready var tower_manager := get_node("../TowerManager")

func _on_basic():
	tower_manager.select_tower("basic")

func _on_radar():
	tower_manager.select_tower("radar")

func _on_sniper():
	tower_manager.select_tower("sniper")


func _on_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	match index:
		0:
			_on_basic
