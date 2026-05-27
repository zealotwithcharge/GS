class_name EvilMusicTeacherSticker
extends Sticker

const NOTE_ORDER = {
	"C": 0,
	"D": 1,
	"E": 2,
	"F": 3,
	"G": 4,
	"A": 5,
	"B": 6
}

func _init():
	sticker_id = "evil_music_teacher"
	sticker_name = "Evil Music Teacher"
	description = "Note letters must be played in order: C, D, E, F, G, A, B."

func can_play_selected_cards(cards: Array) -> bool:
	var last_note_index := -1

	for card in cards:
		var letter = card["letter"]

		if !NOTE_ORDER.has(letter):
			continue

		var note_index = NOTE_ORDER[letter]

		if note_index < last_note_index:
			return false

		last_note_index = note_index

	return true
