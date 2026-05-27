class_name DyslexiaSticker
extends Sticker

func _init():
	sticker_name = "Dyslexia"
	description = "Every valid anagram triggers. Required score is doubled."
	sticker_id = "dyslexia"

func modify_target_score(target: int) -> int:
	return target * 2
