class_name PETeacherSticker
extends Sticker

func _init():
	sticker_id = "pe_teacher"
	sticker_name = "PE Teacher"
	description = "Patterns without P or E do not score. P and E are drawn more often."

func modify_score_data(data: Dictionary) -> Dictionary:
	var word = data["word"].to_upper()

	if !word.contains("P") and !word.contains("E"):
		data["final_multiplier"] *= 0

	return data

func modify_letter_weights(weights: Dictionary) -> Dictionary:
	weights["P"] *= 3
	weights["E"] *= 2
	return weights
