extends Button


func _ready():
	self.pressed.connect(_on_play_button_pressed)
func _on_play_button_pressed():
	get_parent().get_parent().play_selected_cards()
