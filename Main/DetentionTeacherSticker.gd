class_name DetentionTeacherSticker
extends Sticker

var detained_sticker_ids := []
var released_count := 0

func _init():
	sticker_id = "detention_teacher"
	sticker_name = "Detention"
	description = "4 stickers are disabled. One is released after each hand."

func reset():
	detained_sticker_ids.clear()
	released_count = 0

	if game == null:
		return

	var candidates := []

	for sticker in game.owned_stickers:
		if sticker.sticker_id == "detention_teacher":
			continue

		candidates.append(sticker)

	candidates.shuffle()

	for i in range(min(4, candidates.size())):
		detained_sticker_ids.append(candidates[i].sticker_id)

	print("Detained stickers: ", detained_sticker_ids)

func after_hand_scored():
	if released_count >= detained_sticker_ids.size():
		return

	released_count += 1
	print("Released sticker: ", detained_sticker_ids[released_count - 1])

func is_sticker_detained(sticker) -> bool:
	var index = detained_sticker_ids.find(sticker.sticker_id)

	if index == -1:
		return false

	return index >= released_count
