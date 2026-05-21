extends Button

var card_data


func setup(card, selected):
	card_data = card
	self.text = card["letter"]

	if selected:
		self.modulate = Color(0.7, 1.0, 0.7)
	else:
		self.modulate = Color.WHITE

		
