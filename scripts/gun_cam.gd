extends Camera3D

@onready var sub_viewport: SubViewport = $".."
@export var MAIN_CAMERA: Camera3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if !is_multiplayer_authority():
		sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_NEVER
		visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	global_transform = global_transform.interpolate_with(MAIN_CAMERA.global_transform, 0.7)
	
	
