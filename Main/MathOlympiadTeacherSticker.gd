class_name MathOlympiadTeacherSticker
extends Sticker

func _init():
	sticker_id = "math_olympiad_teacher"
	sticker_name = "Math Olympiad"
	description = "Gain $2 every time X, Y, or Z triggers."

func after_combo_triggered(combo, _pattern_id, _word, _combo_score):
	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		var letter_state = game.grid[y][x]

		if letter_state.letter in ["X", "Y", "Z"]:
			game.money += get_money_bonus()
			game.update_stage_ui()

func get_money_bonus() -> int:
	if game != null and game.has_sticker_id("teachers_pet"):
		return 4

	return 2
