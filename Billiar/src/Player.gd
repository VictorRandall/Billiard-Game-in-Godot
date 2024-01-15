extends Node
class_name Player

@export var nickname: String
@export var scores_even_number: bool

var update_times: int

func _enter_tree():
	set_multiplayer_authority(name.to_int())
	if is_multiplayer_authority():
		get_parent().get_parent().set_player_name.rpc(get_parent().get_parent().get_node("Menu/HBoxContainer2/Name").text, name.to_int())
		Global.self_peer = name.to_int()
	get_parent().get_parent().update_list()

func _process(delta):
	if Input.is_action_just_pressed("gp_pull") and is_multiplayer_authority():
		print(nickname)
	if update_times > 10:
		get_parent().get_parent().update_list()
	else:
		update_times += 1
