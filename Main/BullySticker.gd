class_name BullySticker
extends Sticker

func _init():
	sticker_name = "The Bully"
	description = "If one letter triggers 6 more times than any other letter, double your hand score."
	sticker_id = "bully"

func modify_final_hand_score(hand_score: int) -> int:
	if !should_double_score():
		return hand_score

	print("BULLY: doubled hand score")
	return hand_score * 2

func should_double_score() -> bool:
	var highest := -1
	var second_highest := -1

	for row in game.grid:
		for letter_state in row:
			if letter_state.is_blank():
				continue

			var trigger_count = letter_state.patterns_this_hand.size()

			if trigger_count > highest:
				second_highest = highest
				highest = trigger_count
			elif trigger_count > second_highest:
				second_highest = trigger_count

	return highest >= second_highest + 6
