class_name VowelLoverSticker
extends Sticker

func _init():
	sticker_id = "vowel_lover"
	sticker_name = "Vowel Lover"
	description = "Double the growth of vowels."


func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if has_affected(letter_state):
		return

	if is_vowel(letter_state.letter):
		letter_state.growth *= 2
		mark_affected(letter_state)

func is_vowel(letter: String) -> bool:
	return letter.to_upper() in ["A", "E", "I", "O", "U"]
	
