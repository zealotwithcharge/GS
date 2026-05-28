class_name WordlerSticker
extends Sticker

func _init():
	sticker_name = "Wordler"
	description = "Trigger 5-letter patterns twice."
	sticker_id = "wordler"


func after_combo_triggered(combo, pattern_id, word, _score):
	if !str(pattern_id).ends_with("5"):
		return

	await game.trigger_combo(combo, pattern_id, true, word, false)
