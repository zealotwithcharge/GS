class_name GoodyTwoShoesSticker
extends Sticker

func _init():
	sticker_name = "Goody Two Shoes"
	description = "A's multiplier only resets to 0 when B, C, D or F is played"
	sticker_id = "goody_two_shoes"

func prevents_hand_reset(letter_state) -> bool:
	if letter_state.is_blank():
		return false

	return letter_state.letter == "A" or letter_state.letter == "@"

func modify_score_data(data):
	for letter_state in data["letters"]:
		if letter_state.letter in ["B", "C", "D", "F"]:
			reset_all_a_multipliers()
			break

	return data


func reset_all_a_multipliers():
	for row in game.grid:
		for cell in row:
			if cell.is_blank():
				continue

			if cell.letter == "A" or cell.letter == "@":
				cell.mult = 0
