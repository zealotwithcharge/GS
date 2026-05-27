class_name HistoryTeacherSticker
extends Sticker

func _init():
	sticker_id = "history_teacher"
	sticker_name = "History Teacher"
	description = "Letters have -1 growth until that letter is already on the grid."

func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if !letter_exists_on_grid(letter_state.letter):
		letter_state.growth -= 1

func letter_exists_on_grid(letter: String) -> bool:
	for y in range(game.GRID_SIZE):
		for x in range(game.GRID_SIZE):
			var existing = game.grid[y][x]

			if existing.is_blank():
				continue

			if existing.letter == letter:
				return true

	return false
