class_name EvilMathTeacherSticker
extends Sticker

var penalty_active := true

func _init():
	sticker_id = "evil_math_teacher"
	sticker_name = "Evil Math Teacher"
	description = "All letters have -1 growth until X, Y, or Z scores. X, Y, and Z are drawn more often."

func reset():
	penalty_active = true

func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if penalty_active:
		letter_state.growth -= 1

func modify_letter_weights(weights: Dictionary) -> Dictionary:
	weights["X"] *= 3
	weights["Y"] *= 3
	weights["Z"] *= 3
	return weights

func after_combo_triggered(combo, _pattern_id, _word, _combo_score):
	if !penalty_active:
		return

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		var letter_state = game.grid[y][x]

		if letter_state.letter in ["X", "Y", "Z"]:
			penalty_active = false
			print("Evil Math Teacher penalty disabled.")
			return
