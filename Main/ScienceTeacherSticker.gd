class_name ScienceTeacherSticker
extends Sticker

const NOBLE_ELEMENTS = [
	"HE",
	"NE",
	"AR",
	"KR",
	"XE",
	"RN",
	"OG"
]

var penalty_active := true

func _init():
	sticker_id = "science_teacher"
	sticker_name = "Science Teacher"
	description = "All letters have -1 growth until a noble element scores."

func reset():
	penalty_active = true

func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if penalty_active:
		letter_state.growth -= 1

func after_combo_triggered(_combo, _pattern_id, word, _combo_score):
	if !penalty_active:
		return

	var upper_word = word.to_upper()

	for element in NOBLE_ELEMENTS:
		if upper_word.contains(element):
			penalty_active = false
			print("Science Teacher penalty disabled.")
			return
