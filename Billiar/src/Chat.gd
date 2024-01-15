extends Label

var chat_log: Array[String] = []

@rpc("any_peer", "call_local")
func new_message(from: String, message: String):
	for msg in max(0,chat_log.size() - 14):
		chat_log.remove_at(0)
	chat_log.append(from+": "+message)
	update_messages()

func update_messages():
	var new_text = ""
	for message in chat_log:
		new_text = new_text + message + "\n"
	self.text = new_text
