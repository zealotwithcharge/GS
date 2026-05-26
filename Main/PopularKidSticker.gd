class_name PopularKidSticker
extends Sticker

func _init():
	sticker_name = "The Popular Kid"
	description = "Gain $4 every time a letter is triggered more than 4 times in a hand"


func modify_score_data(data: Dictionary):
	var letters = data["letters"]

	for letter in letters:
		if letter.patterns_this_hand.size() == 4:
			game.money += 4

	return data
