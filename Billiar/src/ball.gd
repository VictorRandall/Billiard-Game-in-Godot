extends RigidBody3D
class_name PoolBall

@export var number: int

var audio_hit: AudioStreamPlayer3D

func _init():
	audio_hit = AudioStreamPlayer3D.new()
	audio_hit.stream = load("res://hit.tres")
	add_child(audio_hit)

func _physics_process(delta):
	for body in get_colliding_bodies():
		var weight = 0.05
		if body is PoolBall:
			if (linear_velocity.length_squared() > weight or body.linear_velocity.length_squared() > weight):
				audio_hit.play()
	
