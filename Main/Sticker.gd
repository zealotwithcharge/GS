class_name Sticker
extends Resource

var sticker_name := "Sticker"
var description := ""
var sticker_id := "sticker"
var resets_each_hand := false
var resets_each_grade := true

var affected_letter_ids := {}
func prevents_hand_reset(letter_state) -> bool:
	return false

func prevents_grade_reset(letter_state) -> bool:
	return false
func modify_letter(letter_state):
	pass

func modify_score_data(data):
	return data

func has_affected(letter_state) -> bool:
	return affected_letter_ids.has(letter_state.unique_id)

func mark_affected(letter_state):
	affected_letter_ids[letter_state.unique_id] = true

func reset():
	affected_letter_ids.clear()
	
