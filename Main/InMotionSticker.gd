class_name InMotionSticker
extends Sticker

func _init():
	sticker_id = "in_motion"
	sticker_name = "In Motion"
	description = "I, N, and G are drawn more often."

func modify_letter_weights(weights: Dictionary) -> Dictionary:
	weights["I"] *= 2
	weights["N"] *= 2
	weights["G"] *= 2
	return weights
