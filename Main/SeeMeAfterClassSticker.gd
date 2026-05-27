class_name SeeMeAfterClassSticker
extends Sticker

func _init():
	sticker_id = "see_me_after_class"
	sticker_name = "See Me After Class"
	description = "Sell during a grade to lower current needed score by 25%. Add that amount to next grade."
	sell_value = 0
	can_sell = true

func on_sell(game):
	if game.game_phase != game.GamePhase.PLAYING:
		print("See Me After Class sold outside a grade. No effect.")
		return

	var reduction = int(game.get_target_score() * 0.25)

	game.current_target_score_modifier -= reduction
	game.next_target_score_modifier += reduction

	print("See Me After Class lowered this grade by ", reduction, " and added it to next grade.")
