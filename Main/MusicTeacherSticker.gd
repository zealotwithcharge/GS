class_name MusicTeacherSticker
extends Sticker

const NOTE_LETTERS = ["C", "D", "E", "F", "G", "A", "B"]

func _init():
	sticker_id = "music_teacher"
	sticker_name = "Music Teacher"
	description = "Note letters gain +1 growth."

func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if letter_state.letter in NOTE_LETTERS:
		letter_state.growth += get_growth_bonus()

func get_growth_bonus() -> int:
	if game != null and game.has_sticker_id("teachers_pet"):
		return 2

	return 1
