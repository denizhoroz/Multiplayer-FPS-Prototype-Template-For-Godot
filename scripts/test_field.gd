extends Node3D


const Player = preload("res://scenes/player.tscn")
const PORT = 56560
var enet_peer = ENetMultiplayerPeer.new()

var health_bar
var ammo_text

func _ready():
	Global.game_manager.connect("gui_loaded", Callable(self, "setup_gui"))
	
	if Global.game_manager.is_server:
		server_initialize()
	else:
		client_initialize()

func server_initialize():
	enet_peer.create_server(PORT)
	multiplayer.multiplayer_peer = enet_peer
	add_player(multiplayer.get_unique_id())
	
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

func client_initialize():
	enet_peer.create_client("localhost", PORT)
	multiplayer.multiplayer_peer = enet_peer
	
func add_player(peer_id):
	if not multiplayer.is_server(): return  # Only server can spawn players
	
	var player = Player.instantiate()
	player.name = str(peer_id)
	add_child(player)
	
	if multiplayer.get_unique_id() == peer_id:
		player.health_changed.connect(update_health_bar)
		player.current_weapon.ammo_changed.connect(update_ammo_text)

func remove_player(peer_id):
	var player = get_node_or_null(str(peer_id))
	if player:
		player.queue_free()

func setup_gui(gui):
	health_bar = gui.get_node("HUD/HealthBar")
	ammo_text = gui.get_node("HUD/AmmoText")
	
func update_health_bar(health_value):
	health_bar.value = health_value

func update_ammo_text(ammo_value):
	ammo_text.text = "%s/7" % ammo_value

func _on_multiplayer_spawner_spawned(node: Node) -> void:
	if node.is_multiplayer_authority():
		node.health_changed.connect(update_health_bar)
		node.current_weapon.ammo_changed.connect(update_ammo_text)
