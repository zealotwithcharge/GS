Observations:

Without Discards and limited plays, dead letters like Q, Z, X feel like hand cloggers. 
It seems too punishing to play but not playing them is a permanent debuff; 
there's a sense in which 4 letter words are superior to 5 letter words because it allows you to play a dead letter, unclogging the hand

May be we should consider starting with a bunch of letters, so that they can kinda plan accordingly? so maybe like a max hand size 32
but with no additional draws



Currently, the calculations are very complicated such that I don't really feel like I have agency regarding the grid. 


I think putting the focus on horizontal words & vertical/diagonal letter patterns maybe much more appealing. maybe V/D words should be like rare treat rather than an expected
strategic necessity.

Visually, it's so much more easier to plan around letter patterns for the V/D patterns. 
=
=
=
=
=
=
=
=
=
=


POSSIBLE FIX TO LONG WORD BUG

Yes. The bug is in GS-dev/Main/game_manager.gd, inside play_selected_cards().

This part counts the long word using all selected cards:

if selected_cards.size() >= long_word_requirement:
	await score_long_word_bonus()
But right after that, the grid only receives the cards from the active 5-card preview window:

var cards_to_place = get_cards_to_place()

for card in cards_to_place:
	place_card_on_grid(card)
And get_cards_to_place() only returns cards inside the 5-slot active window:

for slot_index in range(active_start, active_start + GRID_PLACE_SIZE):
So a 6+ letter word can be accepted and get the long-word bonus, while only 5 letters are actually placed on the board. Then score_grid() only scores whatever is on the grid after that, which can make it look like the long word was “counted” but not actually played.

I would also move the empty-row check before the long-word bonus, so the game cannot award a long-word bonus when there is nowhere to place the cards.

Add this helper near the other grid helpers:

func has_empty_row_for_play() -> bool:
	for y in range(GRID_SIZE):
		if row_is_empty(y):
			return true

	return false
Then in play_selected_cards(), change this section:

if selected_cards.size() >= long_word_requirement:
	await score_long_word_bonus()
move_cursor_to_next_empty_row_if_any()
var cards_to_place = get_cards_to_place()
to this:

if !has_empty_row_for_play():
	print("No empty row available")
	return

move_cursor_to_next_empty_row_if_any()
var cards_to_place = get_cards_to_place()

if cards_to_place.is_empty():
	return

if selected_cards.size() >= long_word_requirement:
	await score_long_word_bonus()
That fixes the “counted even though nothing got added” case.

The bigger design question is: should a long word place all letters, or should it only place the chosen 5-letter preview slice? Right now your code is built around placing only 5 letters because the grid row is 5 wide. So long words are currently a bonus for selected cards, not a full grid placement.





2:44 PM
