class_name TooCoolForSchoolSticker
extends Sticker

func _init():
	sticker_name = "Too Cool For School"
	description = "D's and F's don't lose multipliers."
	sticker_id = "too_cool_for_school"

func prevents_hand_reset(letter_state) -> bool:
	if letter_state.is_blank():
		return false

	return letter_state.letter in ["D", "F"]
