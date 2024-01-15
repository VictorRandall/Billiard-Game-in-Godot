extends Control

const PORT = 4433

signal start_game

var peer = ENetMultiplayerPeer.new()
var is_hosting = false

@export_node_path("Player") var players_turn = null 
@onready var player = preload("res://assets/Player.tscn")

func _ready():
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)

func _on_host_pressed():
	$Menu.visible = false
	$PlayersList.visible = true
	$PlayersList/Label2.text = "No Team Assigned"
	peer.create_server(PORT)
	multiplayer.multiplayer_peer = peer
	is_hosting = true
	add_player()
	print("hosting")

func _on_connect_pressed():
	$PlayersList.visible = true
	$Menu.visible = false
	peer.create_client($Menu/HBoxContainer2/IP.text, PORT)
	multiplayer.multiplayer_peer = peer
	print("joining room")
	$PlayersList/Start.disabled = true
	$PlayersList/Start.visible = false

func add_player(id = 1):
	print(id)
	if $Players.get_child_count() + 1 > $Menu/HBoxContainer2/SpinBox.value:
		multiplayer.multiplayer_peer.disconnect_peer(id,true)
		return
	var player = player.instantiate()
	player.name = str(id)
	$Players.call_deferred("add_child",player)
	update_list()
	#rpc_console_log.rpc("player("+str(id)+") connected")

func remove_player(id: int):
	if not $Players.has_node(str(id)):
		return
	$Players.get_node(str(id)).queue_free()
	update_list()
	#rpc_console_log.rpc("player("+str(id)+") disconnected")

func update_list():
	if $Players.get_child_count() == $Menu/HBoxContainer2/SpinBox.value and is_hosting:
		$PlayersList/Start.disabled = false
		$PlayersList/Start.visible = true
	else:
		$PlayersList/Start.disabled = true
		#$PlayersList/Start.visible = false
		
	var text = ""
	for player in $Players.get_children():
		text = player.nickname + " " + text
	$PlayersList/Label.text = text
	#$PlayersList/Label.text = str($Players.get_children())

func _on_start_pressed():
	$PlayersList.visible = true
	start_game.emit()
	$Game._on_lobby_start_game.rpc()

@rpc("any_peer", "call_local")
func set_player_name(nickname: String, id: int):
	var player = $Players.get_node(str(id))
	for node in $Players.get_children():
		if node.nickname == nickname:
			player.nickname = nickname + str(id)
			return
	print(nickname,id) 
	player.nickname = nickname
	update_list()

func _on_exit_pressed():
	print("disconnect")
	if multiplayer.is_server():
		$Game._game_stopped.rpc()
	else:
		$Game._game_stopped()
	for child in $Players.get_children():
		child.queue_free()
	multiplayer.multiplayer_peer.close()
	$PlayersList.visible = false
	$Menu.visible = true
	$Game/Node3D/Node3D/Camera3D.current = false

func _on_message_submitted(new_text):
	$PlayersList/options/options/Messages.text = ""
	$PlayersList/options/options/Chat.new_message.rpc($Menu/HBoxContainer2/Name.text,new_text)
	print(new_text)
