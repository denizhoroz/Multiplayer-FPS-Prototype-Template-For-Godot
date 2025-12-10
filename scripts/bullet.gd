extends Node3D

@export var SPEED = 120.0

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var raycast: RayCast3D = $RayCast

func _process(delta: float) -> void:
	position += transform.basis * Vector3(0, 0, -SPEED) * delta
	if raycast.is_colliding():
		mesh.visible = false
		await get_tree().create_timer(5.0).timeout
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()
