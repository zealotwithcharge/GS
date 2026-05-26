class_name CheckSticker
extends Sticker

func _init():
	sticker_name = "Check!"
	description = "If a letter scores in two diagonals, gain $4."
	sticker_id = "check"


func modify_score_data(data):
	if !str(data["pattern_id"]).begins_with("D"):
		return data

	for letter_state in data["letters"]:
		var diagonal_triggers := 0

		for pattern_id in letter_state.patterns_this_hand:
			if str(pattern_id).begins_with("D"):
				diagonal_triggers += 1

		if diagonal_triggers == 1:
			game.money += 4
			game.update_stage_ui()



	return data
