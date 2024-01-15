extends Node3D

signal balls_stopped
var check: bool = false

var ball_count: int
var sleep_times: int

class Ball:
	var pos: Vector3
	var rot: Vector3
	var pos_velocity: Vector3
	var rot_velocity: Vector3

var ball_pos_saved: Array[Ball]

func _ready():
	ball_count = get_child_count()
	self.set_multiplayer_authority(1)
	save_balls_pos.rpc()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if check and is_multiplayer_authority() and $Main.is_sleeping():
		print("ee")
		var balls_sleeping: int = 0
		for ball in get_children():
			if ball.is_sleeping():
				#if ball.angular_velocity.length() <= 0.5:
					#ball.angular_velocity = Vector3.ZERO
				#if ball.linear_velocity.length() <= 0.5:
					#ball.linear_velocity = Vector3.ZERO
				balls_sleeping += 1
		
		if balls_sleeping == ball_count:
			sleep_times += 1
			if sleep_times > 10:
				balls_stopped.emit()
				print("yo")
				return
		print(sleep_times)

func _on_game_should_check(should):
	check = should
	print(should)
	if not should:
		sleep_times = 0

@rpc("any_peer", "call_local")
func save_balls_pos():
	#if not is_multiplayer_authority():
		#return
	var new_ball_pos_saved: Array[Ball]
	for child in get_children():
		var ball = Ball.new()
		ball.pos = child.global_position
		ball.rot = child.global_rotation
		ball.pos_velocity = child.linear_velocity
		ball.rot_velocity = child.angular_velocity
		new_ball_pos_saved.append(ball)
	ball_pos_saved = new_ball_pos_saved


@rpc("any_peer", "call_local")
func reset_balls():
	#if not is_multiplayer_authority():
		#return
	for ball_index in get_child_count():
		var ball = ball_pos_saved[ball_index]
		get_child(ball_index).global_position = ball.pos
		get_child(ball_index).global_rotation = ball.rot
		get_child(ball_index).linear_velocity = ball.pos_velocity
		get_child(ball_index).angular_velocity = ball.rot_velocity
	check = true

func _on_area_3d_scored_ball(number):
	ball_count -= 1
