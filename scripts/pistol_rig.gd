extends Node3D

signal ammo_changed(ammo_value)

@onready var weapon_shoot_audio: AudioStreamPlayer3D = $PistolModel/PistolShoot
@onready var weapon_reload_audio: AudioStreamPlayer3D = $PistolModel/PistolReload
@onready var weapon_anim = $PistolModel/AnimationPlayer
@onready var aim_ray: Node3D = $"../../AimRay/RayCast3D"


@export var weapon_damage = 15.0
@export var weapon_fire_rate = 0.15
@export var weapon_fire_enabled = true
@export var weapon_max_magazine = 7
@export var weapon_magazine = 7

func _ready() -> void:
	if !is_multiplayer_authority():
		visible = false

func _input(event):
	if not is_multiplayer_authority(): return
	
	# Handle shooting
	if Input.is_action_just_pressed("fire"):
		if weapon_fire_enabled:
			shoot_weapon()
			
			weapon_magazine -= 1
			ammo_changed.emit(weapon_magazine)
			
			if weapon_magazine > 0:
				# Pistol fire cooldown
				weapon_fire_enabled = false
				await get_tree().create_timer(weapon_fire_rate).timeout
				weapon_fire_enabled = true
			else:
				weapon_fire_enabled = false
	
	# Handle reloading
	if Input.is_action_just_pressed("reload"):
		if !weapon_anim.is_playing() and weapon_magazine != weapon_max_magazine:
			reload_weapon()

func _process(delta: float) -> void:
	pass

func shoot_weapon():
	weapon_anim.stop()
	weapon_anim.play("Armature|Shoot")
	weapon_shoot_audio.volume_db = -28
	weapon_shoot_audio.play()
	if aim_ray.is_colliding():
		if aim_ray.get_collider().is_in_group("enemy"):
			var hit_player = get_player_from_bone(aim_ray.get_collider())
			hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority(), weapon_damage)

func reload_weapon():
	weapon_fire_enabled = false
	weapon_anim.play("Armature|Reload")
	weapon_reload_audio.play()
	await weapon_anim.animation_finished
			
	weapon_magazine = weapon_max_magazine
	ammo_changed.emit(weapon_magazine)
	weapon_fire_enabled = true

	
func get_player_from_bone(bone: PhysicalBone3D):
	var current = bone
	while current:
		if current is CharacterBody3D:
			return current
		current = current.get_parent()
	return null
	
