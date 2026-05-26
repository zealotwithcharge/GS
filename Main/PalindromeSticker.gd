class_name PalindromeSticker
extends Sticker

func _init():
	sticker_name = "Palindrome"
	description = "All palindromes trigger 4 times."
	sticker_id = "palindrome"

func after_combo_triggered(combo, pattern_id, word, _score):
	if !is_palindrome(word):
		return

	for i in range(3):
		await game.trigger_combo(combo, pattern_id, true, word, false)

func is_palindrome(word: String) -> bool:
	word = word.to_lower()

	if word.length() < 3:
		return false

	for i in range(word.length() / 2):
		if word.substr(i, 1) != word.substr(word.length() - 1 - i, 1):
			return false

	return true
