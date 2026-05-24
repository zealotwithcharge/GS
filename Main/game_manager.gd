extends Node

# ============================================================
# Constants
# ============================================================

const HAND_SIZE := 9
const MAX_SELECTED_CARDS := 9
const GRID_SIZE := 5
const GRID_PLACE_SIZE := 5
const HANDS_PER_GRADE := 5
const PREVIEW_SLOT_COUNT := 2 * HAND_SIZE - GRID_PLACE_SIZE

const DRAG_THRESHOLD := 8.0
const PREVIEW_CARD_SCALE := Vector2(0.75, 0.75)
const CARD_SCENE := preload("res://Card.tscn")

const LESSON_IDS := ["H3", "H4", "H5", "V3", "V4", "V5", "D3", "D4", "D5"]


enum GamePhase {
	PLAYING,
	SHOP,
	GAME_OVER,
	WIN
}


# ============================================================
# Node References
# ============================================================

@onready var top_bar = $RootUI/TopBar
@onready var permanent_item_bar = $RootUI/PermanentItemBar
@onready var gameplay_ui = $RootUI/GameplayUI
@onready var shop_panel = $RootUI/ShopPanel

@onready var stage_label = $RootUI/TopBar/StageLabel
@onready var money_label = $RootUI/TopBar/MoneyLabel
@onready var target_label = $RootUI/TopBar/TargetLabel
@onready var hands_label = $RootUI/TopBar/HandsLabel

@onready var score_label = $RootUI/GameplayUI/ScoreLabel
@onready var grid_container = $RootUI/GameplayUI/GridContainer
@onready var selected_container = $RootUI/GameplayUI/SelectedRowControls/SelectedContainer
@onready var shift_left_button = $RootUI/GameplayUI/SelectedRowControls/ShiftLeftButton
@onready var shift_right_button = $RootUI/GameplayUI/SelectedRowControls/ShiftRightButton
@onready var hand_container = $RootUI/GameplayUI/HandContainer

@onready var perma_shop = $RootUI/ShopPanel/PermaShop
@onready var consume_shop = $RootUI/ShopPanel/ConsumeShop
@onready var next_grade_button = $RootUI/ShopPanel/NextGradeButton

@onready var pause_menu = $PauseMenu
@onready var upgrade_list = $PauseMenu/PausePanel/VBoxContainer/UpgradeViewer/UpgradeList
@onready var resume_button = $PauseMenu/PausePanel/VBoxContainer/ResumeButton


# ============================================================
# Run State
# ============================================================

var game_phase := GamePhase.PLAYING
var is_paused := false

var money := 25
var hands_left := HANDS_PER_GRADE
var total_score := 0

var school_index := 0
var grade_index := 0

var deck := []
var discard := []
var hand := []
var selected_cards := []

var grid := []
var current_row := 0
var current_col := 0

var dictionary := {}

var owned_permanents := []
var owned_stickers := []

var shop_permanent_items := []
var shop_consumable_items := []

var preview_offset := 0
var dragging_preview_index := -1
var drag_start_mouse_pos := Vector2.ZERO
var is_dragging_preview_card := false
var drag_ghost = null


# ============================================================
# Data
# ============================================================

var score_upgrades := {
	"H3": 0, "H4": 0, "H5": 0,
	"V3": 0, "V4": 0, "V5": 0,
	"D3": 0, "D4": 0, "D5": 0
}

var schools := [
	{
		"name": "Elementary School",
		"grades": 5,
		"base_target": 100,
		"target_growth": 75,
		"reward": 5
	},
	{
		"name": "Middle School",
		"grades": 4,
		"base_target": 350,
		"target_growth": 125,
		"reward": 8
	},
	{
		"name": "High School",
		"grades": 3,
		"base_target": 750,
		"target_growth": 200,
		"reward": 12
	}
]

var permanent_pool := [
	{"name": "Gold Star", "cost": 6, "description": "Nothing. You rule."},
	{"name": "Pencil Case", "cost": 7, "description": "Placeholder permanent item."},
	{"name": "Eraser", "cost": 8, "description": "Placeholder permanent item."},
	{"name": "Hall Pass", "cost": 9, "description": "Placeholder permanent item."},
	{"name": "Detention Slip", "cost": 10, "description": "Placeholder permanent item."}
]

var consumable_pool := [
	{"id": "H3", "name": "H3", "cost": 6, "direction": "H", "length": 3, "description": "Horizontal 3-letter words score as if they were 1 letter longer."},
	{"id": "H4", "name": "H4", "cost": 5, "direction": "H", "length": 4, "description": "Horizontal 4-letter words score as if they were 1 letter longer."},
	{"id": "H5", "name": "H5", "cost": 3, "direction": "H", "length": 5, "description": "Horizontal 5-letter words score as if they were 1 letter longer."},

	{"id": "V3", "name": "V3", "cost": 6, "direction": "V", "length": 3, "description": "Vertical 3-letter words score as if they were 1 letter longer."},
	{"id": "V4", "name": "V4", "cost": 5, "direction": "V", "length": 4, "description": "Vertical 4-letter words score as if they were 1 letter longer."},
	{"id": "V5", "name": "V5", "cost": 3, "direction": "V", "length": 5, "description": "Vertical 5-letter words score as if they were 1 letter longer."},

	{"id": "D3", "name": "D3", "cost": 7, "direction": "D", "length": 3, "description": "Diagonal 3-letter words score as if they were 1 letter longer."},
	{"id": "D4", "name": "D4", "cost": 5, "direction": "D", "length": 4, "description": "Diagonal 4-letter words score as if they were 1 letter longer."},
	{"id": "D5", "name": "D5", "cost": 3, "direction": "D", "length": 5, "description": "Diagonal 5-letter words score as if they were 1 letter longer."}
]


# ============================================================
# Lifecycle / Input
# ============================================================

func _ready():
	load_dictionary()
	create_starting_deck()
	create_grid()

	pause_menu.visible = false
	shop_panel.visible = false
	gameplay_ui.visible = true

	resume_button.pressed.connect(_on_resume_pressed)
	next_grade_button.pressed.connect(_on_next_grade_pressed)
	shift_left_button.pressed.connect(_on_shift_left_pressed)
	shift_right_button.pressed.connect(_on_shift_right_pressed)

	preview_offset = get_active_window_start()

	# Temporary test sticker.
	owned_stickers.append(VowelLoverSticker.new())

	draw_to_hand()
	update_grid_ui()
	update_stage_ui()


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()


# ============================================================
# Pause Menu
# ============================================================

func toggle_pause_menu():
	if game_phase == GamePhase.GAME_OVER or game_phase == GamePhase.WIN:
		return

	is_paused = !is_paused
	pause_menu.visible = is_paused

	if is_paused:
		update_upgrade_viewer()


func _on_resume_pressed():
	is_paused = false
	pause_menu.visible = false


func update_upgrade_viewer():
	clear_container(upgrade_list)

	for id in LESSON_IDS:
		var pattern_len = int(id.substr(1, 1))
		var upgrade = score_upgrades[id]
		var effective_len = pattern_len + upgrade

		var label = Label.new()

		if upgrade > 0:
			label.text = id + ": (Σ Mult + 1) × " + str(effective_len) + "   [+" + str(upgrade) + "]"
		else:
			label.text = id + ": (Σ Mult + 1) × " + str(pattern_len)

		upgrade_list.add_child(label)


# ============================================================
# Stage / Economy
# ============================================================

func get_current_school():
	return schools[school_index]


func get_current_grade_number():
	return grade_index + 1


func get_target_score():
	var school = get_current_school()
	return school["base_target"] + grade_index * school["target_growth"]


func get_grade_reward():
	var school = get_current_school()
	return school["reward"] + grade_index


func update_stage_ui():
	stage_label.text = get_current_school()["name"] + " - Grade " + str(get_current_grade_number())
	money_label.text = "$" + str(money)
	target_label.text = "Target: " + str(get_target_score())
	hands_label.text = "Hands: " + str(hands_left)
	score_label.text = "Score: " + str(total_score)


func check_grade_result():
	if total_score >= get_target_score():
		complete_grade()
		return

	if hands_left <= 0:
		fail_grade()


func complete_grade():
	game_phase = GamePhase.SHOP

	var reward = get_grade_reward()
	money += reward

	print("Passed ", get_current_school()["name"], " Grade ", get_current_grade_number())
	print("Earned $", reward)

	open_shop()


func fail_grade():
	game_phase = GamePhase.GAME_OVER
	print("FAILED GRADE")


func win_run():
	game_phase = GamePhase.WIN
	gameplay_ui.visible = false
	shop_panel.visible = false
	print("YOU GRADUATED")


func advance_grade():
	grade_index += 1
	reset_grade_stickers()

	if grade_index >= get_current_school()["grades"]:
		grade_index = 0
		school_index += 1

		if school_index >= schools.size():
			win_run()
			return

	start_grade()


func start_grade():
	game_phase = GamePhase.PLAYING

	gameplay_ui.visible = true
	shop_panel.visible = false

	total_score = 0
	hands_left = HANDS_PER_GRADE
	current_row = 0
	current_col = 0

	selected_cards.clear()
	preview_offset = get_active_window_start()

	create_grid()
	update_grid_ui()
	update_hand_ui()
	update_stage_ui()


func reset_grade_stickers():
	for sticker in owned_stickers:
		if sticker.reset_on_grade:
			sticker.reset()


# ============================================================
# Shop
# ============================================================

func open_shop():
	game_phase = GamePhase.SHOP
	gameplay_ui.visible = false
	shop_panel.visible = true

	generate_shop()
	update_stage_ui()


func generate_shop():
	clear_container(perma_shop)
	clear_container(consume_shop)

	shop_permanent_items = get_random_items(permanent_pool, 3)
	shop_consumable_items = get_random_items(consumable_pool, 4)

	for item in shop_permanent_items:
		var button = make_shop_button(item)
		button.pressed.connect(_on_permanent_item_pressed.bind(item, button))
		perma_shop.add_child(button)

	for item in shop_consumable_items:
		var button = make_shop_button(item)
		button.pressed.connect(_on_consumable_item_pressed.bind(item, button))
		consume_shop.add_child(button)


func clear_container(container):
	for child in container.get_children():
		child.queue_free()


func get_random_items(pool, count):
	var copy = pool.duplicate()
	copy.shuffle()

	var result := []

	for i in range(min(count, copy.size())):
		result.append(copy[i])

	return result


func make_shop_button(item):
	var button = Button.new()
	button.text = item["name"] + " - $" + str(item["cost"])
	button.tooltip_text = item["description"]
	button.custom_minimum_size = Vector2(140, 60)

	return button


func _on_permanent_item_pressed(item, button):
	if money < item["cost"]:
		await animate_cant_afford(button)
		return

	money -= item["cost"]
	owned_permanents.append(item)

	update_owned_permanent_ui()
	update_stage_ui()

	await animate_shop_purchase(button)

	button.disabled = true
	button.text = item["name"] + " - BOUGHT"

	print("Bought permanent: ", item["name"])


func _on_consumable_item_pressed(item, button):
	if money < item["cost"]:
		await animate_cant_afford(button)
		return

	money -= item["cost"]

	var id = item["id"]
	score_upgrades[id] += 1

	update_stage_ui()
	update_upgrade_viewer()

	await animate_shop_purchase(button)

	button.disabled = true
	button.text = item["name"] + " - BOUGHT"


func update_owned_permanent_ui():
	clear_container(permanent_item_bar)

	for item in owned_permanents:
		var label = Label.new()
		label.text = item["name"]
		label.tooltip_text = item["description"]
		permanent_item_bar.add_child(label)


func _on_next_grade_pressed():
	if game_phase != GamePhase.SHOP:
		return

	advance_grade()


# ============================================================
# Deck / Hand
# ============================================================

func create_starting_deck():
	deck.clear()

	var letters = [
		"A", "A", "A", "A",
		"E", "E", "E", "E",
		"R", "R", "R",
		"T", "T", "T",
		"O", "O", "O",
		"N", "N",
		"S", "S",
		"L", "L",
		"D", "D",
		"G", "M", "P", "B", "C", "F"
	]

	var uid = 0

	for l in letters:
		deck.append({
			"id": uid,
			"letter": l
		})
		uid += 1

	deck.shuffle()


func draw_card():
	if deck.is_empty():
		reshuffle_discard()

	if deck.is_empty():
		return null

	return deck.pop_back()


func reshuffle_discard():
	deck = discard.duplicate()
	discard.clear()
	deck.shuffle()


func draw_to_hand():
	while hand.size() < HAND_SIZE:
		var card = draw_card()

		if card == null:
			break

		hand.append(card)

	update_hand_ui()


func toggle_select(card):
	if is_paused:
		return

	if selected_cards.has(card):
		selected_cards.erase(card)
	else:
		if selected_cards.size() < MAX_SELECTED_CARDS:
			selected_cards.append(card)

	auto_center_preview()
	update_hand_ui()


func _on_card_pressed(card):
	toggle_select(card)


func _on_selected_card_pressed(card):
	if is_paused:
		return

	selected_cards.erase(card)
	auto_center_preview()
	update_hand_ui()


# ============================================================
# Preview / Placement Window
# ============================================================

func get_active_window_start():
	return int((PREVIEW_SLOT_COUNT - GRID_PLACE_SIZE) / 2)


func auto_center_preview():
	var active_start = get_active_window_start()

	if selected_cards.size() <= GRID_PLACE_SIZE:
		preview_offset = active_start
	else:
		preview_offset = active_start - (selected_cards.size() - GRID_PLACE_SIZE)

	preview_offset = clamp(preview_offset, 0, PREVIEW_SLOT_COUNT - selected_cards.size())


func get_cards_to_place():
	var active_start = get_active_window_start()
	var cards := []

	for slot_index in range(active_start, active_start + GRID_PLACE_SIZE):
		var card_index = slot_index - preview_offset

		if card_index >= 0 and card_index < selected_cards.size():
			cards.append(selected_cards[card_index])

	return cards


func shift_preview_left():
	if is_paused or selected_cards.is_empty():
		return

	preview_offset = max(0, preview_offset - 1)
	update_hand_ui()


func shift_preview_right():
	if is_paused or selected_cards.is_empty():
		return

	var max_offset = PREVIEW_SLOT_COUNT - selected_cards.size()
	preview_offset = min(max_offset, preview_offset + 1)
	update_hand_ui()


func _on_shift_left_pressed():
	shift_preview_left()


func _on_shift_right_pressed():
	shift_preview_right()


# ============================================================
# Preview Drag Reorder
# ============================================================

func _on_preview_card_gui_input(event, card_index):
	if is_paused:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_preview_drag(card_index)
		else:
			end_preview_drag(card_index)

	if event is InputEventMouseMotion and dragging_preview_index != -1:
		update_preview_drag()


func start_preview_drag(card_index):
	dragging_preview_index = card_index
	drag_start_mouse_pos = get_viewport().get_mouse_position()
	is_dragging_preview_card = false


func update_preview_drag():
	var mouse_pos = get_viewport().get_mouse_position()

	if mouse_pos.distance_to(drag_start_mouse_pos) > DRAG_THRESHOLD:
		if !is_dragging_preview_card:
			is_dragging_preview_card = true
			create_drag_ghost(selected_cards[dragging_preview_index])

	update_drag_ghost()


func end_preview_drag(card_index):
	if dragging_preview_index == -1:
		return

	var target_index = get_preview_card_index_under_mouse()

	if is_dragging_preview_card and target_index != -1 and target_index != dragging_preview_index:
		swap_selected_cards(dragging_preview_index, target_index)
	elif !is_dragging_preview_card:
		var card = selected_cards[card_index]
		_on_selected_card_pressed(card)

	clear_drag_ghost()

	dragging_preview_index = -1
	is_dragging_preview_card = false


func get_preview_card_index_under_mouse():
	var mouse_pos = get_viewport().get_mouse_position()

	for slot in selected_container.get_children():
		if slot.get_child_count() == 0:
			continue

		var inner = slot.get_child(0)

		if inner.get_child_count() == 0:
			continue

		var card_ui = inner.get_child(0)
		var rect = Rect2(card_ui.global_position, card_ui.size * card_ui.scale)

		if rect.has_point(mouse_pos):
			return card_ui.get_meta("selected_index")

	return -1


func swap_selected_cards(a, b):
	if a < 0 or b < 0:
		return

	if a >= selected_cards.size() or b >= selected_cards.size():
		return

	var temp = selected_cards[a]
	selected_cards[a] = selected_cards[b]
	selected_cards[b] = temp

	update_hand_ui()


func create_drag_ghost(card):
	clear_drag_ghost()

	drag_ghost = CARD_SCENE.instantiate()
	drag_ghost.setup(card, false)
	drag_ghost.modulate = Color(1, 1, 1, 0.65)
	drag_ghost.scale = PREVIEW_CARD_SCALE
	drag_ghost.z_index = 999
	drag_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE

	get_tree().current_scene.add_child(drag_ghost)
	update_drag_ghost()


func update_drag_ghost():
	if drag_ghost == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	drag_ghost.global_position = mouse_pos - drag_ghost.size * drag_ghost.scale / 2


func clear_drag_ghost():
	if drag_ghost != null:
		drag_ghost.queue_free()
		drag_ghost = null


# ============================================================
# Play Hand
# ============================================================

func play_selected_cards():
	if is_paused:
		return

	if game_phase != GamePhase.PLAYING:
		return

	if selected_cards.is_empty():
		return

	if hands_left <= 0:
		return

	if !can_play_selected_cards():
		print("Invalid long word")
		return

	reset_letter_hand_histories()

	if selected_cards.size() > GRID_PLACE_SIZE:
		await score_long_word_bonus()

	var cards_to_place = get_cards_to_place()
	var played_count = cards_to_place.size()

	for card in cards_to_place:
		place_card_on_grid(card)

	for i in range(GRID_PLACE_SIZE - played_count):
		place_blank_on_grid()

	for card in selected_cards:
		hand.erase(card)
		discard.append(card)

	selected_cards.clear()
	preview_offset = get_active_window_start()

	hands_left -= 1

	draw_to_hand()
	update_grid_ui()
	update_stage_ui()

	await score_grid()

	reset_letters_after_hand()
	check_grade_result()
	update_stage_ui()


func get_selected_word():
	var s = ""

	for card in selected_cards:
		s += card["letter"]

	return s


func can_play_selected_cards():
	if selected_cards.is_empty():
		return false

	if selected_cards.size() <= GRID_PLACE_SIZE:
		return true

	var word = get_selected_word().to_lower()
	return dictionary.has(word)


func score_long_word_bonus():
	var word = get_selected_word()
	var length = word.length()

	if length <= GRID_PLACE_SIZE:
		return

	if !dictionary.has(word.to_lower()):
		return

	var bonus = get_long_word_bonus(length)
	await show_long_word_score(word, bonus)

	total_score += bonus
	score_label.text = "Score: " + str(total_score)


func get_long_word_bonus(length):
	var target = get_target_score()

	match length:
		6:
			return int(target * 0.05)
		7:
			return int(target * 0.10)
		8:
			return int(target * 0.20)
		9:
			return int(target * 0.35)
		_:
			return 0


# ============================================================
# Grid / LetterState
# ============================================================

func create_grid():
	grid.clear()

	for y in range(GRID_SIZE):
		var row := []

		for x in range(GRID_SIZE):
			row.append(LetterState.new("_"))

		grid.append(row)


func place_card_on_grid(card):
	if current_row >= GRID_SIZE:
		print("GRID FULL")
		return

	var letter_state = LetterState.new(card["letter"])

	for sticker in owned_stickers:
		sticker.modify_letter(letter_state)

	grid[current_row][current_col] = letter_state
	advance_grid_cursor()


func place_blank_on_grid():
	if current_row >= GRID_SIZE:
		print("GRID FULL")
		return

	grid[current_row][current_col] = LetterState.new("_")
	advance_grid_cursor()


func advance_grid_cursor():
	current_col += 1

	if current_col >= GRID_SIZE:
		current_col = 0
		current_row += 1


func reset_letter_hand_histories():
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			grid[y][x].reset_hand_history()


func reset_letters_after_hand():
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var letter_state = grid[y][x]

			if letter_state.is_blank():
				continue

			if should_reset_letter_mult_after_hand(letter_state):
				letter_state.mult = 0

			letter_state.patterns_this_hand.clear()


func should_reset_letter_mult_after_hand(letter_state):
	for sticker in owned_stickers:
		if sticker.prevents_hand_reset(letter_state):
			return false

	return true


# ============================================================
# Line Generation
# ============================================================

func get_horizontal_lines():
	var lines := []

	for y in range(GRID_SIZE):
		var line := []

		for x in range(GRID_SIZE):
			line.append([y, x])

		lines.append(line)

	return lines


func get_vertical_lines():
	var lines := []

	for x in range(GRID_SIZE):
		var line := []

		for y in range(GRID_SIZE):
			line.append([y, x])

		lines.append(line)

	return lines


func get_diagonal_lines():
	var lines := []

	for start_x in range(GRID_SIZE):
		lines.append(make_line(0, start_x, 1, 1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_line(start_y, 0, 1, 1))

	for start_x in range(GRID_SIZE):
		lines.append(make_line(0, start_x, 1, -1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_line(start_y, GRID_SIZE - 1, 1, -1))

	return lines


func make_line(start_y, start_x, dy, dx):
	var line := []
	var y = start_y
	var x = start_x

	while y >= 0 and y < GRID_SIZE and x >= 0 and x < GRID_SIZE:
		line.append([y, x])
		y += dy
		x += dx

	return line


# ============================================================
# Scoring
# ============================================================

func score_grid():
	var grade_score := 0

	var horizontal_lines = get_horizontal_lines()
	var vertical_lines = get_vertical_lines()
	var diagonal_lines = get_diagonal_lines()

	for length in range(3, GRID_SIZE + 1):
		grade_score += await score_lines_by_length(horizontal_lines, length, "H")

	for length in range(3, GRID_SIZE + 1):
		grade_score += await score_lines_by_length(vertical_lines, length, "V")

	for length in range(3, GRID_SIZE + 1):
		grade_score += await score_lines_by_length(diagonal_lines, length, "D")

	print("Grade score this hand: ", grade_score)
	return grade_score


func score_lines_by_length(lines, length, direction):
	var score := 0

	for line in lines:
		if line.size() < length:
			continue

		for start in range(0, line.size() - length + 1):
			var combo = line.slice(start, start + length)

			if combo_has_blank(combo):
				continue

			var word = combo_to_string(combo)

			if is_valid_combo(word):
				var pattern_id = direction + str(length)
				var combo_score = score_combo(combo, pattern_id)
				score += combo_score

				print(word, " scored ", combo_score)

				await animate_combo(combo)
				await show_combo_score(combo, combo_score)

	return score


func score_combo(combo, pattern_id):
	var data = build_score_data(combo, pattern_id)

	for sticker in owned_stickers:
		data = sticker.modify_score_data(data)

	var final_score = calculate_score_from_data(data)

	for letter_state in data["letters"]:
		letter_state.record_trigger(pattern_id)
		letter_state.apply_growth()

	return final_score
	
func build_score_data(combo, pattern_id):
	var letter_scores = []

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		var letter_state = grid[y][x]

		letter_scores.append({
			"letter": letter_state,
			"base_mult": letter_state.mult,
			"bonus_mult": 0,
			"multiplier": 1.0
		})

	return {
		"word": combo_to_string(combo),
		"pattern_id": pattern_id,
		"letters": get_letters_from_combo(combo),
		"letter_scores": letter_scores,
		"length": combo.size(),
		"effective_length": combo.size() + score_upgrades[pattern_id],
		"final_multiplier": 1.0,
		"flat_bonus": 0
	}
func calculate_score_from_data(data):
	var mult_total = 1

	for entry in data["letter_scores"]:
		var letter_value = entry["base_mult"] + entry["bonus_mult"]
		letter_value *= entry["multiplier"]
		mult_total += int(letter_value)

	var score = mult_total * data["effective_length"]
	score += data["flat_bonus"]
	score = int(score * data["final_multiplier"])

	return score

func get_letters_from_combo(combo):
	var letters := []

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		letters.append(grid[y][x])

	return letters


func combo_has_blank(combo):
	for letter_state in get_letters_from_combo(combo):
		if letter_state.is_blank():
			return true

	return false


func combo_to_string(combo):
	var s = ""

	for letter_state in get_letters_from_combo(combo):
		s += letter_state.letter

	return s


func is_valid_combo(word: String) -> bool:
	word = word.to_lower()

	if word.length() < 3:
		return false

	if word.contains("_") or word.contains(" "):
		return false

	if dictionary.has(word):
		return true

	return all_same_letter(word)


func all_same_letter(word: String) -> bool:
	if word.length() < 3:
		return false

	var first = word.substr(0, 1)

	if first == "" or first == "_":
		return false

	for i in range(1, word.length()):
		if word.substr(i, 1) != first:
			return false

	return true


func load_dictionary():
	var file = FileAccess.open("res://enable1.txt", FileAccess.READ)

	if file == null:
		push_error("Could not load dictionary at res://enable1.txt")
		return

	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_lower()

		if word != "":
			dictionary[word] = true


# ============================================================
# UI Rendering
# ============================================================

func update_hand_ui():
	clear_container(hand_container)
	clear_container(selected_container)

	for card in hand:
		if selected_cards.has(card):
			continue

		var card_ui = CARD_SCENE.instantiate()
		card_ui.setup(card, false)
		card_ui.pressed.connect(_on_card_pressed.bind(card))

		hand_container.add_child(card_ui)

	update_selected_preview_ui()


func update_selected_preview_ui():
	clear_container(selected_container)

	var active_start = get_active_window_start()

	for i in range(PREVIEW_SLOT_COUNT):
		var slot = create_preview_slot(i, active_start)
		selected_container.add_child(slot)


func create_preview_slot(slot_index, active_start):
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(72, 96)
	slot.add_theme_stylebox_override("panel", make_preview_slot_style(slot_index, active_start))

	var inner = CenterContainer.new()
	slot.add_child(inner)

	var card_index = slot_index - preview_offset

	if card_index >= 0 and card_index < selected_cards.size():
		var card_ui = create_preview_card(card_index, is_active_preview_slot(slot_index, active_start))
		inner.add_child(card_ui)

	return slot


func make_preview_slot_style(slot_index, active_start):
	var style = StyleBoxFlat.new()

	style.bg_color = Color(1, 1, 1, 0.04)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(1, 1, 1, 0.18)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	if is_active_preview_slot(slot_index, active_start):
		style.bg_color = Color(1, 1, 0.85, 0.12)
		style.border_width_left = 3
		style.border_width_top = 3
		style.border_width_right = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.9, 0.82, 0.45, 0.75)

	return style


func is_active_preview_slot(slot_index, active_start):
	return slot_index >= active_start and slot_index < active_start + GRID_PLACE_SIZE


func create_preview_card(card_index, is_active_slot):
	var card = selected_cards[card_index]
	var card_ui = CARD_SCENE.instantiate()

	card_ui.setup(card, false)
	card_ui.scale = PREVIEW_CARD_SCALE
	card_ui.set_meta("selected_index", card_index)
	card_ui.gui_input.connect(_on_preview_card_gui_input.bind(card_index))
	card_ui.pressed.connect(_on_selected_card_pressed.bind(card))

	if dragging_preview_index == card_index and is_dragging_preview_card:
		card_ui.modulate = Color(1, 1, 1, 0.2)
	elif !is_active_slot:
		card_ui.modulate = Color(1, 1, 1, 0.45)

	return card_ui


func update_grid_ui():
	reset_grid_visuals()

	var i = 0

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell = grid_container.get_child(i)
			var label = cell.get_node("Label")
			label.text = grid[y][x].letter
			i += 1


func reset_grid_visuals():
	for cell in grid_container.get_children():
		var label = cell.get_node("Label")
		label.position = Vector2.ZERO
		label.rotation_degrees = 0


# ============================================================
# UI Effects
# ============================================================

func animate_combo(combo):
	var tweens := []

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		var index = y * GRID_SIZE + x
		var cell = grid_container.get_child(index)
		var label = cell.get_node("Label")

		tweens.append(animate_cell(label))

	if tweens.size() > 0:
		await tweens[0].finished


func animate_cell(label):
	label.position = Vector2.ZERO
	label.rotation_degrees = 0

	var tween = create_tween()
	tween.tween_property(label, "position:y", -12, 0.08)
	tween.tween_property(label, "rotation_degrees", -8, 0.04)
	tween.tween_property(label, "rotation_degrees", 8, 0.04)
	tween.tween_property(label, "rotation_degrees", -5, 0.04)
	tween.tween_property(label, "rotation_degrees", 0, 0.04)
	tween.tween_property(label, "position:y", 0, 0.12)

	return tween


func show_combo_score(combo, combo_score):
	var start_pos = get_combo_center_global_position(combo)
	var end_pos = score_label.global_position + score_label.size / 2

	var floating_label = Label.new()
	floating_label.text = "+" + str(combo_score)
	floating_label.global_position = start_pos
	floating_label.z_index = 100
	floating_label.add_theme_font_size_override("font_size", 28)

	add_child(floating_label)

	var tween = create_tween()
	tween.tween_property(floating_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(floating_label, "scale", Vector2(1.0, 1.0), 0.08)
	tween.tween_property(floating_label, "global_position", end_pos, 0.35)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(floating_label, "scale", Vector2(0.4, 0.4), 0.25)

	await tween.finished

	floating_label.queue_free()

	total_score += combo_score
	score_label.text = "Score: " + str(total_score)

	animate_score_label_bump()


func get_combo_center_global_position(combo):
	var pos = Vector2.ZERO

	for grid_pos in combo:
		var y = grid_pos[0]
		var x = grid_pos[1]
		var index = y * GRID_SIZE + x
		var cell = grid_container.get_child(index)

		pos += cell.global_position + cell.size / 2

	return pos / combo.size()


func show_long_word_score(word, bonus):
	var label = Label.new()
	label.text = word + "\nLONG WORD +" + str(bonus)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 32)
	label.z_index = 999
	label.scale = Vector2(0.4, 0.4)
	label.modulate.a = 0.0

	get_tree().current_scene.add_child(label)

	var viewport_size = get_viewport().get_visible_rect().size
	label.global_position = viewport_size / 2 - Vector2(120, 40)

	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.12)
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), 0.18)
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), 0.08)
	tween.tween_interval(0.35)
	tween.tween_property(label, "global_position", score_label.global_position + score_label.size / 2, 0.35)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(label, "scale", Vector2(0.3, 0.3), 0.25)

	await tween.finished

	label.queue_free()
	animate_score_label_bump()


func animate_score_label_bump():
	var bump = create_tween()
	bump.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	bump.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.08)


func animate_shop_purchase(button):
	var original_scale = button.scale
	var original_modulate = button.modulate

	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 1.15, 0.08)
	tween.tween_property(button, "scale", original_scale, 0.08)
	tween.parallel().tween_property(button, "modulate:a", 0.45, 0.15)

	await tween.finished

	button.modulate = original_modulate


func animate_cant_afford(button):
	var original_pos = button.position

	var tween = create_tween()
	tween.tween_property(button, "position:x", original_pos.x - 8, 0.04)
	tween.tween_property(button, "position:x", original_pos.x + 8, 0.04)
	tween.tween_property(button, "position:x", original_pos.x - 5, 0.04)
	tween.tween_property(button, "position:x", original_pos.x + 5, 0.04)
	tween.tween_property(button, "position:x", original_pos.x, 0.04)

	await tween.finished


# ============================================================
# Save / Load
# ============================================================

func save_game():
	var data = {
		"deck": deck,
		"discard": discard,
		"hand": hand,
		"selected_cards": selected_cards,
		"grid": serialize_grid(),
		"row": current_row,
		"col": current_col,
		"total_score": total_score,
		"money": money,
		"hands_left": hands_left,
		"school_index": school_index,
		"grade_index": grade_index,
		"game_phase": game_phase,
		"score_upgrades": score_upgrades
	}

	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))


func load_game():
	if !FileAccess.file_exists("user://save.json"):
		return

	var file = FileAccess.open("user://save.json", FileAccess.READ)
	var json = JSON.parse_string(file.get_as_text())

	if json == null:
		return

	deck = json["deck"]
	discard = json["discard"]
	hand = json["hand"]
	selected_cards = json.get("selected_cards", [])
	grid = deserialize_grid(json.get("grid", []))

	current_row = json["row"]
	current_col = json["col"]

	total_score = json.get("total_score", 0)
	money = json.get("money", 0)
	hands_left = json.get("hands_left", HANDS_PER_GRADE)

	school_index = json.get("school_index", 0)
	grade_index = json.get("grade_index", 0)
	game_phase = json.get("game_phase", GamePhase.PLAYING)
	score_upgrades = json.get("score_upgrades", score_upgrades)

	gameplay_ui.visible = game_phase == GamePhase.PLAYING
	shop_panel.visible = game_phase == GamePhase.SHOP

	update_hand_ui()
	update_grid_ui()
	update_stage_ui()


func serialize_grid():
	var result := []

	for y in range(GRID_SIZE):
		var row := []

		for x in range(GRID_SIZE):
			var letter_state = grid[y][x]
			row.append({
				"letter": letter_state.letter,
				"mult": letter_state.mult,
				"growth": letter_state.growth,
				"patterns_this_hand": letter_state.patterns_this_hand,
				"patterns_this_grade": letter_state.patterns_this_grade
			})

		result.append(row)

	return result


func deserialize_grid(data):
	var result := []

	if data.is_empty():
		create_grid()
		return grid

	for y in range(GRID_SIZE):
		var row := []

		for x in range(GRID_SIZE):
			var cell_data = data[y][x]
			var letter_state = LetterState.new(cell_data.get("letter", "_"))
			letter_state.mult = cell_data.get("mult", 0)
			letter_state.growth = cell_data.get("growth", 1)
			letter_state.patterns_this_hand = cell_data.get("patterns_this_hand", [])
			letter_state.patterns_this_grade = cell_data.get("patterns_this_grade", [])
			row.append(letter_state)

		result.append(row)

	return result
