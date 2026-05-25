class_name PopularKidSticker
extends Sticker

func _init():
	sticker_name = "The Popular Kid"
	description = "Gain $4 every time a letter is triggered more than 4 times in a hand"
	
func modify_score_data(data: Dictionary) -> void:
	var letter = data.get("letter", null)
	if letter == null:
		return
	var triggers_this_hand = letter.patterns_this_hand.size()
	if triggers_this_hand > 4:
		data["money"] += 4
