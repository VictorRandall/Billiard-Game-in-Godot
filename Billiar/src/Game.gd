extends Node3D

var turn2play: Player
var turn_index: int = 0
var game_started: bool
var balls_moving: bool

var self_id: int

@export var team_even: Array[int] = []
@export var team_odd: Array[int] = []

const MOUSE_SENSITIVITY = 0.4

signal should_check(should:bool)

var held_mouse: bool
@onready var raycast = $Node3D/Stick/RayCast3D

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and game_started:
		if turn2play == null or not turn2play.is_multiplayer_authority():
			if Input.is_action_pressed("gp_click"):
				$Node3D.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
				$Node3D/Node3D.rotate_x(deg_to_rad(-event.relative.y * MOUSE_SENSITIVITY))
				$Node3D/Node3D.rotation_degrees.x = clamp($Node3D/Node3D.rotation_degrees.x,-90,0)
		elif turn2play != null or turn2play.is_multiplayer_authority():
			if Input.is_action_pressed("gp_click"):
				$Node3D/Node3D/Camera3D.position.z = 2.0
				$Node3D/Node3D.rotation_degrees.x = -10.0
				held_mouse = true
				$Node3D.rotate_y(deg_to_rad(-event.relative.x * MOUSE_SENSITIVITY))
				$Node3D/Stick.position.z += event.relative.y * MOUSE_SENSITIVITY * 0.025
				$Node3D/Stick.position.z = clamp($Node3D/Stick.position.z,0.6,1.5)
				update_stick.rpc()
				$ServerStick.global_rotation = $Node3D/Stick.global_rotation

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if game_started:
		$"../PlayersList/Start".visible = false
		$"../PlayersList/Start".disabled = true
	if turn2play != null and game_started:
		$ServerStick.visible = true
		if turn2play.is_multiplayer_authority():
			$Node3D.global_position = $Balls/Main.global_position
			if Input.is_action_just_released("gp_click") and held_mouse:
				$Balls.save_balls_pos.rpc()
				use_stick.rpc()
				ended_turn.rpc()
		else:
			spectate()
	elif turn2play == null and game_started:
		spectate()
	#else:
		#$ServerStick.visible = false

@rpc("any_peer", "call_local")
func ended_turn():
	turn2play = null

func spectate():
	$Node3D.global_position = Vector3.ZERO
	$Node3D/Node3D/Camera3D.position.z += Input.get_axis("gp_zoom_in","gp_zoom_out") * 0.1
	$Node3D/Node3D/Camera3D.position.z = clamp($Node3D/Node3D/Camera3D.position.z,1.0,5.0)
	

@rpc("any_peer", "call_local")
func use_stick():
	#print("authority"+str($Balls/Main.get_multiplayer_authority()))
	$Balls/Main.set_multiplayer_authority(turn2play.name.to_int())
	#print("authority"+str($Balls/Main.get_multiplayer_authority()))
	var distance = raycast.get_collision_point() - raycast.global_position 
	var force = distance * 12.0
	#print(force.length())
	$Balls/Main.set_axis_velocity(force)
	should_check.emit(true)
	turn2play = null

@rpc("any_peer", "call_local")
func update_stick():
	$ServerStick.set_global_position($Node3D/Stick.global_position)
	$ServerStick.set_global_rotation($Node3D/Stick.global_position)

@rpc("any_peer", "call_local")
func _on_lobby_start_game():
	game_started = true
	var host_is_even = bool(randi_range(0,1))
	
	#rpc("add_to_team",host_is_even,$"../Menu/HBoxContainer2/Name".text,1)
	var player_index = 0
	var players_list = ""
	for index in $"../Players".get_child_count():
		var child: Player = $"../Players".get_child(index)
		if child.is_multiplayer_authority():
			self_id = child.name.to_int()
		if host_is_even:
			rpc("add_to_team",index % 2 == 0,child.nickname,child.name.to_int())
		else:
			rpc("add_to_team",index % 2 != 0,child.nickname,child.name.to_int())
			
		print(child.name,child.scores_even_number,index)
	$Node3D/Node3D/Camera3D.current = true
	if $"../Players".get_node(str(self_id)).scores_even_number:
		$"../PlayersList/Label2".text = "you score even numbers"
	else:
		$"../PlayersList/Label2".text = "you score odd numbers"
	turn2play = $"../Players".get_child(0)

@rpc("any_peer", "call_local")
func add_to_team(odd: bool, nickname: String, id: int):
	$"../Players".get_node(str(id)).scores_even_number = not odd

@rpc("any_peer", "call_local")
func get_next_turn():
	turn_index += 1
	if turn_index >= $"../Players".get_children().size():
		turn_index = 0
	turn2play = $"../Players".get_child(turn_index)
	print("turn of "+str(turn2play)+"from "+str(self_id))

func _on_balls_balls_stopped():
	if turn2play == null and game_started:
		get_next_turn.rpc()
		should_check.emit(false)
		print("next")

func _should_reset():
	$Balls.reset_balls.rpc()
	should_check.emit(true)
	if self_id == 1:
		get_next_turn.rpc()

@rpc("any_peer", "call_local")
func _game_stopped():
	$Balls.reset_balls.rpc()
	should_check.emit(false)
	turn2play = null
	game_started = false
