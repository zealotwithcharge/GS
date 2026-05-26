class_name OmniVowelSticker
extends Sticker

func _init():
	sticker_name = "The Omni-Vowel"
	description = "All vowels become @ and count as any vowel. Required score is increased by 50%."
	sticker_id = "omni_vowel"


func modify_letter(letter_state):
	if letter_state.is_blank():
		return

	if letter_state.letter in ["A", "E", "I", "O", "U"]:
		letter_state.letter = "@"


func modify_target_score(target: int) -> int:
	return int(ceil(target * 1.5))
