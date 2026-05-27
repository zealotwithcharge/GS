class_name NewKidInSchoolSticker
extends Sticker

func _init():
	sticker_name = "New Kid In School"
	description = "If a letter is only used once on the grid, it has triple growth."
	sticker_id = "new_kid_in_school"

func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if is_only_copy_on_grid(letter_state.letter):
		letter_state.growth *= 3

func is_only_copy_on_grid(letter: String) -> bool:
	var count := 0

	for row in game.grid:
		for cell in row:
			if cell.is_blank():
				continue

			if cell.letter == letter:
				count += 1

	return count == 0
