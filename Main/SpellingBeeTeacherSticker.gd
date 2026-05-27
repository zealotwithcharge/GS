class_name SpellingBeeTeacherSticker
extends Sticker

var target_word := ""

func _init():
	sticker_id = "spelling_bee_teacher"
	sticker_name = "Spelling Bee"
	description = "If the target word scores, gain $5. The target changes after it pays."

func reset():
	pick_new_target_word()

func pick_new_target_word():
	if game == null:
		return

	var words = game.dictionary.keys()

	if words.is_empty():
		target_word = ""
		return

	target_word = words.pick_random()
	print("Spelling Bee word: ", target_word)

func after_combo_triggered(_combo, _pattern_id, word, _combo_score):
	if target_word == "":
		pick_new_target_word()

	if word.to_lower() != target_word:
		return

	game.money += get_money_bonus()
	game.update_stage_ui()

	pick_new_target_word()

func get_money_bonus() -> int:
	if game != null and game.has_sticker_id("teachers_pet"):
		return 10

	return 5
