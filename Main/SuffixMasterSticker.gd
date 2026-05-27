class_name SuffixMasterSticker
extends Sticker

func _init():
	sticker_id = "suffix_master"
	sticker_name = "Suffix Master"
	description = "D, S, and Y are drawn more often."

func modify_letter_weights(weights: Dictionary) -> Dictionary:
	weights["D"] *= 2
	weights["S"] *= 2
	weights["Y"] *= 2
	return weights
