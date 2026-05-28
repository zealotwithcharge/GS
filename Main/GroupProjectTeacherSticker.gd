class_name GroupProjectTeacherSticker
extends Sticker

func _init():
	sticker_id = "group_project_teacher"
	sticker_name = "Group Project"
	description = "Letters do not score until they have 3 or more mult."

func modify_score_data(data: Dictionary) -> Dictionary:
	for entry in data["letter_scores"]:
		if entry["base_mult"] < 2:
			entry["multiplier"] = 0.0

	return data
