class_name Sticker
extends Resource

var sticker_name := "Sticker"
var description := ""
var sticker_id := "sticker"
var resets_each_hand := false
var resets_each_grade := true
var game = null
var is_active := false
var uses_remaining := -1 # -1 = unlimited / not relevant
var sell_value := 0
var can_sell := true

func on_sell(game):
	pass

func can_use(_context := {}) -> bool:
	return is_active and (uses_remaining != 0)

func use(_context := {}) -> bool:
	return false

var affected_letter_ids := {}
func prevents_hand_reset(_letter_state) -> bool:
	return false

func prevents_grade_reset(_letter_state) -> bool:
	return false
func modify_letter(_letter_state):
	pass

func modify_score_data(data):
	return data

func has_affected(letter_state) -> bool:
	return affected_letter_ids.has(letter_state.unique_id)

func mark_affected(letter_state):
	affected_letter_ids[letter_state.unique_id] = true

func reset():
	affected_letter_ids.clear()
	
func after_combo_triggered(_combo, _pattern_id, _word, _score):
	pass
func modify_final_hand_score(hand_score: int) -> int:
	return hand_score
