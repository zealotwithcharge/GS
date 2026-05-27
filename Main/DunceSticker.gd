class_name DunceSticker
extends Sticker

func _init():
	sticker_name = "Dunce"
	description = "Trigger 3-letter patterns twice. Required score is increased by 20%."
	sticker_id = "dunce"

func modify_target_score(target: int) -> int:
	return int(ceil(target * 1.2))

func after_combo_triggered(combo, pattern_id, word, _score):
	if !str(pattern_id).ends_with("3"):
		return

	await game.trigger_combo(combo, pattern_id, true, word, false)
