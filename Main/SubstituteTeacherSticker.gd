class_name SubstituteTeacherSticker
extends Sticker

func _init():
	sticker_id = "substitute_teacher"
	sticker_name = "Substitute Teacher"
	description = "Sell this to replace next grade's teacher."
	sell_value = 0
	can_sell = true

func on_sell(game):
	game.reroll_next_teacher()
