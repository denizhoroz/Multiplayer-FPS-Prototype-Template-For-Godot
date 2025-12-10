class_name GameManager extends Node

signal world_loaded(gui)
signal gui_loaded(world)

@export var world: Node3D
@export var gui: Control

var current_world
var current_gui
var is_server: bool

func _ready() -> void:
	Global.game_manager = self
	call_deferred("_init_gui")
	
func _init_gui():
	change_gui("res://scenes/main_menu.tscn")

func change_gui(new_scene: String, delete: bool = true, keep_running: bool = false):
	if current_gui != null:
		if delete:
			current_gui.queue_free()
		elif keep_running:
			current_gui.visible = false
		else:
			gui.remove_child(current_gui)
			
	var new = load(new_scene).instantiate()
	gui.add_child(new)
	current_gui = new
	
	emit_signal("gui_loaded", current_gui)

func change_world(new_scene: String, delete: bool = true, keep_running: bool = false):
	if current_world != null:
		if delete:
			current_world.queue_free()
		elif keep_running:
			current_world.visible = false
		else:
			world.remove_child(current_world)
	
	var new = load(new_scene).instantiate()
	world.add_child(new)
	current_world = new
	
	emit_signal("world_loaded", current_world)
