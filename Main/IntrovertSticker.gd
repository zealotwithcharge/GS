class_name IntrovertSticker
extends Sticker

func _init():
	sticker_name = "Introvert"
	description = "Letters have triple growth for their first 3 triggers. On the fourth, the letter's mult and growth are set to 0 for the rest of the hand."
	sticker_id = "introvert"

func modify_score_data(data):
	for letter_state in data["letters"]:
		var trigger_count = letter_state.patterns_this_hand.size()

		if trigger_count == 0:
			letter_state.growth *= 3

		elif trigger_count == 4:
			letter_state.mult = 0
			letter_state.growth = 0

	return data
