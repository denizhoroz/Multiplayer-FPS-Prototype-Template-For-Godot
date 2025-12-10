extends CharacterBody3D

signal health_changed(health_value)


@onready var camera_mount: Node3D = $CameraMount
@onready var camera: Camera3D = $CameraMount/Camera3D
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var aim_ray: RayCast3D = $CameraMount/Camera3D/AimRay/RayCast3D
@onready var visuals: Node3D = $Visuals
@onready var current_weapon: Node3D

# Movement variables
@export var anim_state: String = "idle"
const SENSITIVITY = 0.0001 * 50
const SPEED = 8.0
const JUMP_VELOCITY = 8.0
const LEAP_STR = 80.0
var pitch
var is_leaping = false
var can_leap = true
var input_dir: Vector2

# Bobbing variables
const BOB_FREQ = 0.5 * SPEED
const BOB_AMP = 0.02
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75.0
const FOV_CHANGE = 0.1

# Player variables
@export var health = 100

# Multiplayer
func _enter_tree() -> void:
	set_multiplayer_authority(str(name).to_int())

# Ready 
func _ready() -> void:
	if not is_multiplayer_authority(): return

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.current = true
	
	# Disable body for local
	visuals.visible = !is_multiplayer_authority()
	
	# Set current weapon
	current_weapon = $CameraMount/Camera3D/WeaponMount/PistolRig


func _input(event):
	if not is_multiplayer_authority(): return

	# Handle camera rotation
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * SENSITIVITY)
		
		pitch = -event.relative.y * SENSITIVITY
		camera.rotate_x(pitch)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		

func _process(_delta: float) -> void:
	if not is_multiplayer_authority(): return
	# Toggle mouse mode
	if Input.is_action_just_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	# Calculate anims
	if is_multiplayer_authority():
		_calculate_animation_state()
		

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority(): return
	
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Get movement input
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Handle movement
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var input_leap = Input.is_action_just_pressed('leap')
	if is_on_floor(): # Add inertia
		if direction:
			if input_leap and can_leap:
				velocity.x = direction.x * LEAP_STR
				velocity.z = direction.z * LEAP_STR
				leap_timer()
				leap_cooldown()
			else:
				if not is_leaping:
					velocity.x = direction.x * SPEED
					velocity.z = direction.z * SPEED
				if is_leaping:
					velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 10.0)
					velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 10.0)
		else:
			velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 15.0)
			velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 15.0)
	else:
		velocity.x = lerp(velocity.x, direction.x * SPEED, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * SPEED, delta * 3.0)
	
	# Head bobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	var velocity_clamped = clamp(velocity.length(), 0.5, SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	camera.fov = lerp(camera.fov, target_fov, delta * 15.0)
	
	# Set movement animations
	if is_multiplayer_authority():
		sync_animation_state.rpc(anim_state)

	move_and_slide()


func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos

func leap_timer():
	is_leaping = true
	await get_tree().create_timer(0.3).timeout
	is_leaping = false
	
func leap_cooldown():
	can_leap = false
	await get_tree().create_timer(3).timeout
	can_leap = true

func _calculate_animation_state():
	if (input_dir[0] == 0.0 and input_dir[1] == 0.0 and is_on_floor()):
		anim_state = "idle"
	elif !is_on_floor():
		anim_state = "jumping"
	elif (input_dir[1] < 0.0 and input_dir[0] == 0.0) and is_on_floor():
		anim_state = "run_f"
	elif (input_dir[1] > 0.0 and input_dir[0] == 0.0) and is_on_floor():
		anim_state = "run_b"
	elif input_dir[0] < 0.0 and is_on_floor():
		anim_state = "run_l"
	elif input_dir[0] > 0.0 and is_on_floor():
		anim_state = "run_r"


@rpc("any_peer", "call_local")
func sync_animation_state(state: String):
	anim_state = state
	
	# Reset all animation booleans
	animation_tree.set("parameters/conditions/is_idle", false)
	animation_tree.set("parameters/conditions/is_jumping", false)
	animation_tree.set("parameters/conditions/is_running_f", false)
	animation_tree.set("parameters/conditions/is_running_b", false)
	animation_tree.set("parameters/conditions/is_running_l", false)
	animation_tree.set("parameters/conditions/is_running_r", false)

	# Apply received animation
	match state:
		"idle":   animation_tree.set("parameters/conditions/is_idle", true)
		"jumping": animation_tree.set("parameters/conditions/is_jumping", true)
		"run_f":  animation_tree.set("parameters/conditions/is_running_f", true)
		"run_b":  animation_tree.set("parameters/conditions/is_running_b", true)
		"run_l":  animation_tree.set("parameters/conditions/is_running_l", true)
		"run_r":  animation_tree.set("parameters/conditions/is_running_r", true)

@rpc("any_peer")
func receive_damage(damage):
	health -= damage
	
	# Dying
	if health <= 0:
		health = 100
		health_changed.emit(health)
		position = Vector3.ZERO
		
	health_changed.emit(health)
	
