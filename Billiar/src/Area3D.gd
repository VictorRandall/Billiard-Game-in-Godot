extends Area3D

signal scored_ball(number: int)
signal should_reset

var has_reset: bool
var ball: PoolBall

func _ball_entered(body):
	if body is PoolBall:
		ball = body

func _process(delta):
	if ball != null:
		if ball.number % 2 == 0:
			get_parent().team_even.append(ball.number)
		else:
			get_parent().team_odd.append(ball.number)
		var pos = ball.global_position
		if ball.number != 0:
			ball.queue_free()
		if ball.number == 8 and $"../Balls".ball_count == 1:
			print("game endded")
		if is_multiplayer_authority() and not has_reset:
			print("should_reset")
			has_reset = false
			should_reset.emit()
		var audio_score = AudioStreamPlayer3D.new()
		audio_score.stream = load("res://score.tres")
		add_child(audio_score)
		audio_score.global_position = pos
		audio_score.play()
		scored_ball.emit(ball.number)
		print("ball number: "+str(ball.number))
		ball = null

func _on_body_exited(body):
	pass
