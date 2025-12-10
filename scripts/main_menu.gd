extends Node

func _on_host_pressed():
	Global.game_manager.is_server = true
	Global.game_manager.change_world("res://scenes/test_field.tscn")
	Global.game_manager.change_gui("res://scenes/hud.tscn")

func _on_join_pressed():
	Global.game_manager.is_server = false
	Global.game_manager.change_world("res://scenes/test_field.tscn")
	Global.game_manager.change_gui("res://scenes/hud.tscn")
