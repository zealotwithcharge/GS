class_name AppleSauceSticker
extends Sticker

func _init():
	sticker_name = "Apple Sauce"
	description = "If a letter scores horizontally and vertically, gain $2."
	sticker_id = "apple_sauce"

func modify_score_data(data):
	var current_pattern = str(data["pattern_id"])

	for letter_state in data["letters"]:
		var has_horizontal := false
		var has_vertical := false

		for pattern_id in letter_state.patterns_this_hand:
			var pattern = str(pattern_id)

			if pattern.begins_with("H"):
				has_horizontal = true

			if pattern.begins_with("V"):
				has_vertical = true

		var triggered := false

		# current trigger has not been recorded yet
		if current_pattern.begins_with("H") and has_vertical:
			triggered = true

		elif current_pattern.begins_with("V") and has_horizontal:
			triggered = true

		if triggered:
			game.money += 2
			game.update_stage_ui()

			if game.debug_sticker_sandbox:
				print(
					"APPLE SAUCE PAYOUT | letter=",
					letter_state.letter,
					" current_pattern=",
					current_pattern,
					" previous_patterns=",
					letter_state.patterns_this_hand,
					" money=",
					game.money
				)

	return data
