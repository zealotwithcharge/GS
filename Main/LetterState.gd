class_name LetterState
extends Resource

static var next_id := 0

var unique_id := -1
var letter := "_"
var mult := 0
var growth := 1

var patterns_this_hand := []
var patterns_this_grade := []

func _init(new_letter := "_"):
	unique_id = next_id
	next_id += 1
	letter = new_letter

func is_blank():
	return letter == "_"

func record_trigger(pattern_id: String):
	patterns_this_hand.append(pattern_id)
	patterns_this_grade.append(pattern_id)

func apply_growth():
	mult += growth
func reset_hand_history():
	patterns_this_hand.clear()
func reset(reset_type: String):
	if reset_type == "hand":
		mult = 0
		growth = 1
		patterns_this_hand.clear()

	elif reset_type == "grade":
		mult = 0
		growth = 1
		patterns_this_hand.clear()
		patterns_this_grade.clear()
