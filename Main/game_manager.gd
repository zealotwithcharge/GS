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
const MAX_SAME_LETTER_IN_HAND := 3
const MAX_BOARD_ECHO_MULTIPLIER := 1.5
const DRAG_THRESHOLD := 8.0
const PREVIEW_CARD_SCALE := Vector2(0.75, 0.75)
const CARD_SCENE := preload("res://Card.tscn")
const DISCARDS_PER_GRADE := 3
const LESSON_IDS := ["H3", "H4", "H5", "V3", "V4", "V5", "D3", "D4", "D5"]
const HAND_DUPLICATE_PENALTY := 0.35
const MIN_DRAW_WEIGHT_MULTIPLIER := 0.15



# ============================================================
# Debug Sticker Sandbox
# ============================================================

#set to true for debug mode
@export var debug_sticker_sandbox := true
@export var debug_log_trigger_order := true
var debug_trigger_event_index := 0
var debug_trigger_frequency_totals := {}
@export var debug_animation_speed := 2.0

@export var debug_auto_play_hands := true
@export var debug_auto_select_next_row := true
@export var debug_add_test_stickers := true
@export var debug_impossible_target_score := 999999999
# CHANGE THIS TO TEST DIFFERENT STICKERS
var debug_test_stickers = [
	PalindromeSticker
]
# CHANGE THIS TO CONTROL VALID DEBUG WORDS
var debug_dictionary_words := [
	"lmn",
	"mno",
	"klmn",
	"lmno",
	"klmno",

	"kpu",
	"fkpu",

	"hmrw",
	"chmrw",
	"ejoty",

	"gms",
	"bhnt",
	"cio",
	"hlp",
	"dhlp",

	"eim",
	"eimq",
	"imqu",
	"eimqu"
]
var debug_draw_order := [
	"A","B","C","D","E",
	"F","G","H","I","J",
	"K","L","M","N","O",
	"P","Q","R","S","T",
	"U","V","W","X","Y"
]

var debug_draw_index := 0
enum GamePhase {
	PLAYING,
	SHOP,
	GAME_OVER,
	WIN
}
enum HandViewMode {
	LINEAR,
	CIRCLE
}

var teacher_order := []
var current_teacher = null
var hand_view_mode := HandViewMode.CIRCLE

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
@onready var circle_hand_container = $RootUI/GameplayUI/BoardAndCircleHBox/HandArea/CircleHandContainer
@onready var linear_hand_container = $RootUI/GameplayUI/LinearHandContainer
@onready var hand_view_toggle_button = $RootUI/GameplayUI/HBoxContainer/HandViewToggleButton

@onready var score_label = $RootUI/GameplayUI/ScoreLabel
@onready var grid_container = $RootUI/GameplayUI/BoardAndCircleHBox/GridArea/GridContainer
@onready var selected_container = $RootUI/GameplayUI/SelectedRowControls/SelectedContainer
@onready var shift_left_button = $RootUI/GameplayUI/SelectedRowControls/ShiftLeftButton
@onready var shift_right_button = $RootUI/GameplayUI/SelectedRowControls/ShiftRightButton

@onready var play_button = $RootUI/GameplayUI/HBoxContainer/PlayButton
@onready var discard_button = $RootUI/GameplayUI/HBoxContainer/DiscardButton
@onready var lock_button = $RootUI/GameplayUI/HBoxContainer/VBoxContainer/LockButton
@onready var clear_button = $RootUI/GameplayUI/HBoxContainer/VBoxContainer/ClearButton
@onready var restart_button = $PauseMenu/PausePanel/VBoxContainer/RestartRunButton

@onready var perma_shop = $RootUI/ShopPanel/PermaShop
@onready var consume_shop = $RootUI/ShopPanel/ConsumeShop
@onready var next_grade_button = $RootUI/ShopPanel/NextGradeButton

@onready var teacher_list = $PauseMenu/PausePanel/VBoxContainer/TeacherViewer/TeacherList
@onready var pause_menu = $PauseMenu
@onready var upgrade_list = $PauseMenu/PausePanel/VBoxContainer/UpgradeViewer/UpgradeList
@onready var resume_button = $PauseMenu/PausePanel/VBoxContainer/ResumeButton
@onready var quit_button = $PauseMenu/PausePanel/VBoxContainer/QuitGameButton


# ============================================================
# Run State
# ============================================================

var game_phase := GamePhase.PLAYING
var is_paused := false
var discards_left := DISCARDS_PER_GRADE
var money := 25
var hands_left := HANDS_PER_GRADE
var total_score := 0

var school_index := 0
var grade_index := 0

var base_letter_weights := {
	"A": 8,
	"E": 10,
	"I": 8,
	"O": 8,
	"U": 5,

	"N": 5,
	"R": 5,
	"T": 3,
	"S": 3,
	"L": 3,
	"D": 3,

	"G": 2,
	"M": 2,
	"P": 2,
	"B": 2,
	"C": 2,
	"F": 2,
	"H": 2,
	"V": 2,
	"W": 2,
	"Y": 2,

	"J": 1,
	"K": 1,
	"Q": 1,
	"X": 1,
	"Z": 1
}

var board_echo_strength := 0.2
var hand := []
var selected_cards := []
var locked_cards := []

var grid := []
var current_row := 0
var current_col := 0

var dictionary := {}

var owned_permanents := []
var owned_stickers := []
var teacher_stickers := []

var shop_permanent_items := []
var shop_consumable_items := []

var preview_offset := 0
var dragging_preview_index := -1
var drag_start_mouse_pos := Vector2.ZERO
var is_dragging_preview_card := false
var drag_ghost = null

var debug_letter_draw_index := 0
var debug_played_rows := 0


# ============================================================
# Data
# ============================================================

var score_upgrades := {
	"H3": 0, "H4": 0, "H5": 0,
	"V3": 0, "V4": 0, "V5": 0,
	"D3": 0, "D4": 0, "D5": 0
}

var teacher_pool := [
	{
		"name": "Ms. Vowels",
		"description": "Vowels grow faster this grade.",
		"stickers": [VowelLoverSticker]
	},
	{
		"name": "Mr. Plain",
		"description": "No modifier this grade.",
		"stickers": []
	},
		{
		"name": "Mr. Plain2",
		"description": "No modifier this grade.",
		"stickers": []
	},
		{
		"name": "Mr. Plain3",
		"description": "No modifier this grade.",
		"stickers": []
	},
		{
		"name": "Mr. Plain4",
		"description": "No modifier this grade.",
		"stickers": []
	},
]

var schools := [
	{
		"name": "Elementary School",
		"grades": 5,
		"base_target": 500,
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

var sticker_pool := [
	{
		"id": "vowel_lover",
		"name": "Vowel Lover",
		"cost": 8,
		"description": "Double the growth of vowels.",
		"sticker": VowelLoverSticker
	},
	{
		"id": "popular_kid",
		"name": "The Popular Kid",
		"cost": 8,
		"description": "Gain $4 every time a letter is triggered for a 5th time in a hand.",
		"sticker": PopularKidSticker
	},
	{
		"id": "goody_two_shoes",
		"name": "Goody Two Shoes",
		"cost": 7,
		"description": "A's multiplier only resets to 0 when B, C, D or F is played.",
		"sticker": GoodyTwoShoesSticker
	},
	{
		"id": "omni_vowel",
		"name": "The Omni-Vowel",
		"cost": 12,
		"description": "All vowels become @ and count as any vowel. Required score is increased by 50%.",
		"sticker": OmniVowelSticker
	},
	{
	"id": "too_cool_for_school",
	"name": "Too Cool For School",
	"cost": 7,
	"description": "D's and F's don't lose multipliers.",
	"sticker": TooCoolForSchoolSticker
},{
	"id": "pencil_sharpener",
	"name": "Pencil Sharpener",
	"cost": 8,
	"description": "You need one less letter to get the long word bonus.",
	"sticker": PencilSharpenerSticker
},{
	"id": "check",
	"name": "Check!",
	"cost": 8,
	"description": "If a letter scores in two diagonals, gain $4.",
	"sticker": CheckSticker
},{
	"id": "show_off",
	"name": "Show Off!",
	"cost": 8,
	"description": "Long word bonus gives 5% more of needed score.",
	"sticker": ShowOffSticker
},{
	"id": "palindrome",
	"name": "Palindrome",
	"cost": 10,
	"description": "All palindromes trigger 4 times.",
	"sticker": PalindromeSticker
},
]
var shop_sticker_items := []
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
	create_grid()
	create_teacher_order()
	pause_menu.visible = false
	shop_panel.visible = false
	gameplay_ui.visible = true

	resume_button.pressed.connect(_on_resume_pressed)
	next_grade_button.pressed.connect(_on_next_grade_pressed)
	shift_left_button.pressed.connect(_on_shift_left_pressed)
	shift_right_button.pressed.connect(_on_shift_right_pressed)
	hand_view_toggle_button.pressed.connect(toggle_hand_view_mode)
	lock_button.pressed.connect(toggle_preview_lock)
	clear_button.pressed.connect(clear_unlocked_preview_cards)
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	if debug_sticker_sandbox:
		setup_debug_sticker_sandbox()

		restart_button.text = "Debug: Open Shop"
	
	preview_offset = get_active_window_start()
	play_button.pressed.connect(play_selected_cards)
	discard_button.pressed.connect(discard_selected_cards)
	linear_hand_container.custom_minimum_size = Vector2(760, 120)
	circle_hand_container.custom_minimum_size = Vector2(540, 540)



	start_grade()
	await get_tree().process_frame
	update_hand_ui()

	if debug_sticker_sandbox and debug_auto_play_hands:
		call_deferred("debug_play_all_hands")


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
		update_teacher_viewer()
func get_teacher_modifier_text(teacher) -> String:
	if teacher["stickers"].is_empty():
		return "No modifier"

	return teacher["description"]
func _on_quit_pressed():
	get_tree().quit()
func update_teacher_viewer():
	clear_container(teacher_list)

	if teacher_order.is_empty():
		return

	for i in range(get_current_school()["grades"]):
		var teacher = teacher_order[i % teacher_order.size()]
		var grade_number = i + 1

		var label = Label.new()

		var prefix = "Grade " + str(grade_number) + ": "

		if i == grade_index:
			prefix = "▶ " + prefix

		label.text = prefix + teacher["name"] + " - " + get_teacher_modifier_text(teacher)

		teacher_list.add_child(label)
func _on_resume_pressed():
	is_paused = false
	pause_menu.visible = false
	
func _on_restart_pressed():
	if debug_sticker_sandbox:
		is_paused = false
		pause_menu.visible = false
		open_shop()
		return

	get_tree().reload_current_scene()

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

func create_teacher_order():
	teacher_order.clear()

	for teacher in teacher_pool:
		teacher_order.append(teacher)

	teacher_order.shuffle()
	
func get_target_score():
	var school = get_current_school()
	var target = school["base_target"] + grade_index * school["target_growth"]

	for sticker in get_active_stickers():
		if sticker.has_method("modify_target_score"):
			target = sticker.modify_target_score(target)

	if debug_sticker_sandbox:
		target += debug_impossible_target_score

	return target


func get_grade_reward():
	var school = get_current_school()
	return school["reward"] + grade_index


func update_stage_ui():
	var teacher_text := ""

	if current_teacher != null:
		teacher_text = " | Teacher: " + current_teacher["name"]

	stage_label.text = get_current_school()["name"] + " - Grade " + str(get_current_grade_number()) + teacher_text
	money_label.text = "$" + str(money)
	target_label.text = "Target: " + str(get_target_score())
	hands_label.text = "Hands: " + str(hands_left) + " | Discards: " + str(discards_left)
	score_label.text = "Score: " + str(total_score)


func check_grade_result():
	if total_score >= get_target_score():
		complete_grade()
		return

	if hands_left <= 0:
		if can_hall_pass_grade():
			complete_grade()
		else:
			fail_grade()

func can_hall_pass_grade() -> bool:
	for sticker in owned_stickers:
		if sticker.has_method("can_pass_grade"):
			if sticker.can_pass_grade(total_score, get_target_score()):
				return true
	return false

func complete_grade():
	clear_teacher_modifiers()
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
	#apply_teacher_modifiers()

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
	discards_left = DISCARDS_PER_GRADE
	total_score = 0
	hands_left = HANDS_PER_GRADE
	current_row = 0
	current_col = 0

	selected_cards.clear()
	locked_cards.clear()
	preview_offset = get_active_window_start()

	if debug_sticker_sandbox:
		reset_debug_sticker_sandbox_for_grade()

	create_grid()
	apply_teacher_for_current_grade()

	draw_to_hand()
	update_grid_ui()
	update_hand_ui()
	update_stage_ui()
	
func apply_teacher_for_current_grade():
	clear_teacher_modifiers()

	if teacher_order.is_empty():
		create_teacher_order()

	var teacher_index = grade_index % teacher_order.size()
	current_teacher = teacher_order[teacher_index]

	for sticker_class in current_teacher["stickers"]:
		var sticker = sticker_class.new()
		sticker.game = self
		teacher_stickers.append(sticker)


	print("Teacher: ", current_teacher["name"])
func reset_grade_stickers():
	for sticker in owned_stickers:
		if sticker.resets_each_grade:
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

	shop_sticker_items = get_available_shop_stickers(3)
	shop_consumable_items = get_random_items(consumable_pool, 4)

	for item in shop_sticker_items:
		var button = make_shop_button(item)
		button.pressed.connect(_on_sticker_item_pressed.bind(item, button))
		perma_shop.add_child(button)

	for item in shop_consumable_items:
		var button = make_shop_button(item)
		button.pressed.connect(_on_consumable_item_pressed.bind(item, button))
		consume_shop.add_child(button)
		
func _on_sticker_item_pressed(item, button):
	if money < item["cost"]:
		await animate_cant_afford(button)
		return

	if has_owned_sticker_id(item["id"]):
		button.disabled = true
		return

	money -= item["cost"]

	var sticker = item["sticker"].new()
	sticker.game = self
	owned_stickers.append(sticker)
	update_owned_permanent_ui()

	update_stage_ui()

	await animate_shop_purchase(button)

	button.disabled = true
	button.text = item["name"] + " - BOUGHT"

	print("Bought sticker: ", item["name"])
func get_available_shop_stickers(count: int) -> Array:
	var available := []

	for item in sticker_pool:
		if !has_owned_sticker_id(item["id"]):
			available.append(item)

	available.shuffle()

	var result := []

	for i in range(min(count, available.size())):
		result.append(available[i])

	return result
	
func has_owned_sticker_id(id: String) -> bool:
	for sticker in owned_stickers:
		if sticker.sticker_id == id:
			return true

	return false
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

	for sticker in owned_stickers:
		var label = Label.new()
		label.text = sticker.sticker_name
		label.tooltip_text = sticker.description
		permanent_item_bar.add_child(label)


func _on_next_grade_pressed():
	if game_phase != GamePhase.SHOP:
		return

	advance_grade()


# ============================================================
# Deck / Hand
# ============================================================

# ============================================================
# Letter Distribution
# ============================================================
func toggle_hand_view_mode():
	if hand_view_mode == HandViewMode.LINEAR:
		hand_view_mode = HandViewMode.CIRCLE
		circle_hand_container.custom_minimum_size = Vector2(540, 540)
		hand_view_toggle_button.text = "View: Circle"
	else:
		hand_view_mode = HandViewMode.LINEAR
		hand_view_toggle_button.text = "View: Linear"
		circle_hand_container.custom_minimum_size = Vector2.ZERO

	update_hand_ui()
func get_current_letter_weights() -> Dictionary:
	var weights = base_letter_weights.duplicate()
	var board_counts := {}

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var letter_state = grid[y][x]

			if letter_state.is_blank():
				continue

			var letter = letter_state.letter

			if is_vowel(letter):
				continue

			board_counts[letter] = board_counts.get(letter, 0) + 1

	for letter in board_counts.keys():
		if !weights.has(letter):
			continue

		var base_weight = base_letter_weights[letter]
		var echo_bonus = base_weight * board_echo_strength * board_counts[letter]
		var max_bonus = base_weight * MAX_BOARD_ECHO_MULTIPLIER

		weights[letter] += min(echo_bonus, max_bonus)

	return weights
func discard_selected_cards():
	if is_paused:
		return

	if game_phase != GamePhase.PLAYING:
		return

	if discards_left <= 0:
		return

	if selected_cards.is_empty():
		return

	var remaining_selected := []

	for card in selected_cards:
		if locked_cards.has(card):
			remaining_selected.append(card)
		else:
			hand.erase(card)

	selected_cards = remaining_selected

	if !has_locked_cards():
		preview_offset = get_active_window_start()

	discards_left -= 1

	draw_to_hand()
	update_hand_ui()
	update_stage_ui()
	
	
func is_vowel(letter: String) -> bool:
	return letter in ["A", "E", "I", "O", "U"]
func draw_random_letter(hand_letter_counts := {}) -> String:
	if debug_sticker_sandbox:
		return draw_debug_letter()

	var weights = get_current_letter_weights()

	for letter in hand_letter_counts.keys():
		if !weights.has(letter):
			continue

		var count = hand_letter_counts[letter]

		if count >= MAX_SAME_LETTER_IN_HAND:
			weights[letter] = 0
		else:
			var penalty = 1.0 - HAND_DUPLICATE_PENALTY * count
			penalty = max(penalty, MIN_DRAW_WEIGHT_MULTIPLIER)
			weights[letter] *= penalty

	var total_weight := 0.0

	for value in weights.values():
		total_weight += float(value)

	if total_weight <= 0:
		return "E"

	var roll = randf() * total_weight
	var running := 0.0

	for letter in weights.keys():
		running += float(weights[letter])

		if roll <= running:
			return letter

	return "E"

func draw_to_hand():
	var hand_letter_counts := {}

	for card in hand:
		var letter = card["letter"]
		hand_letter_counts[letter] = hand_letter_counts.get(letter, 0) + 1

	while hand.size() < HAND_SIZE:
		var letter = draw_random_letter(hand_letter_counts)

		var card = {
			"id": randi(),
			"letter": letter
		}

		hand.append(card)
		hand_letter_counts[letter] = hand_letter_counts.get(letter, 0) + 1

	update_hand_ui()

func toggle_select(card):
	if is_paused:
		return

	if selected_cards.has(card):
		selected_cards.erase(card)
	else:
		if selected_cards.size() < MAX_SELECTED_CARDS:
			selected_cards.append(card)

	if !has_locked_cards():
		auto_center_preview()
	update_hand_ui()


func _on_card_pressed(card):
	toggle_select(card)


func _on_selected_card_pressed(card):
	if is_paused:
		return

	if locked_cards.has(card):
		return

	selected_cards.erase(card)

	if !has_locked_cards():
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

func has_locked_cards() -> bool:
	return !locked_cards.is_empty()


func is_card_locked(card) -> bool:
	return locked_cards.has(card)

func toggle_preview_lock():
	if selected_cards.is_empty():
		return

	if has_locked_cards():
		locked_cards.clear()
		lock_button.text = "🔒"
	else:
		for card in selected_cards:
			if !locked_cards.has(card):
				locked_cards.append(card)

		lock_button.text = "🔓"

	update_hand_ui()
func clear_unlocked_preview_cards():
	var remaining := []

	for card in selected_cards:
		if locked_cards.has(card):
			remaining.append(card)

	selected_cards = remaining

	if !has_locked_cards():
		preview_offset = get_active_window_start()

	update_hand_ui()
# ============================================================
# Play Hand
# ============================================================

func play_selected_cards():
	if is_paused:
		return

	if game_phase != GamePhase.PLAYING:
		return

	if selected_cards.is_empty():
		if debug_sticker_sandbox and debug_auto_select_next_row:
			debug_select_next_row_cards()
		else:
			return

	if hands_left <= 0:
		return

	if !can_play_selected_cards():
		print("Invalid long word")
		return

	reset_letter_hand_histories()

	var long_word_requirement := GRID_PLACE_SIZE + 1

	if has_sticker_id("pencil_sharpener"):
		long_word_requirement -= 1

	if selected_cards.size() >= long_word_requirement:
		await score_long_word_bonus()

	var cards_to_place = get_cards_to_place()
	var played_count = cards_to_place.size()

	for card in cards_to_place:
		place_card_on_grid(card)

	for i in range(GRID_PLACE_SIZE - played_count):
		place_blank_on_grid()

	for card in selected_cards:
		hand.erase(card)


	selected_cards.clear()
	locked_cards.clear()
	lock_button.text = "🔒"
	preview_offset = get_active_window_start()

	hands_left -= 1

	draw_to_hand()
	update_grid_ui()
	update_stage_ui()

	await score_grid()
	
	print_debug_trigger_summary()
	reset_letters_after_hand()
	reset_hand_stickers()
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
func has_sticker_id(id: String) -> bool:
	for sticker in get_active_stickers():
		if sticker.sticker_id == id:
			return true

	return false

func score_long_word_bonus():
	var word = get_selected_word()
	var length = word.length()

	if !dictionary.has(word.to_lower()):
		return

	var bonus = get_long_word_bonus(length)

	if has_sticker_id("show_off"):
		bonus += int(get_target_score() * 0.05)

	await show_long_word_score(word, bonus)

	total_score += bonus
	score_label.text = "Score: " + str(total_score)
func get_long_word_bonus(length):
	var target = get_target_score()


	match length:
		5:
			return int(target * 0.05)
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

	for sticker in get_active_stickers():
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
	for sticker in get_active_stickers():
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

			var word = combo_to_string(combo).to_lower()
			var pattern_id = direction + str(length)

			if word.contains("@"):
				var expanded_words = get_vowel_expanded_words(word)

				for expanded_word in expanded_words:
					if !is_valid_combo(expanded_word):
						continue

					score += await trigger_combo_as_word(combo, pattern_id, expanded_word, true)

				continue

			if is_valid_combo(word):
				score += await trigger_combo(combo, pattern_id, true, word)

	return score
func trigger_combo_as_word(combo, pattern_id, word: String, animate := true) -> int:
	var original_letters := []

	for i in range(combo.size()):
		var pos = combo[i]
		var y = pos[0]
		var x = pos[1]
		var letter_state = grid[y][x]

		original_letters.append(letter_state.letter)
		letter_state.letter = word.substr(i, 1).to_upper()

	update_grid_ui()

	var score = await trigger_combo(combo, pattern_id, animate, word)

	for i in range(combo.size()):
		var pos = combo[i]
		var y = pos[0]
		var x = pos[1]
		grid[y][x].letter = original_letters[i]

	update_grid_ui()

	return score
func trigger_combo(combo, pattern_id, animate := true, trigger_word := "", allow_after_triggers := true) -> int:
	var word = trigger_word

	if word == "":
		word = combo_to_string(combo)

	var combo_score = score_combo(combo, pattern_id, word)

	print(word, " scored ", combo_score)

	if animate:
		await animate_combo(combo)
		await show_combo_score(combo, combo_score)
	else:
		total_score += combo_score
		score_label.text = "Score: " + str(total_score)

	if allow_after_triggers:
		for sticker in get_active_stickers():
			if sticker.has_method("after_combo_triggered"):
				await sticker.after_combo_triggered(combo, pattern_id, word, combo_score)

	return combo_score
func debug_log_combo_trigger(combo, pattern_id, data, final_score):
	if !debug_sticker_sandbox:
		return

	if !debug_log_trigger_order:
		return

	debug_trigger_event_index += 1

	print("\n=== TRIGGER EVENT ", debug_trigger_event_index, " ===")
	print(
		"word=", data["word"],
		" pattern=", pattern_id,
		" score=", final_score,
		" effective_length=", data["effective_length"],
		" final_multiplier=", data["final_multiplier"],
		" flat_bonus=", data["flat_bonus"]
	)

	for entry in data["letter_scores"]:
		var letter_state = entry["letter"]

		print(
			"  ",
			letter_state.letter,
			" mult_before=", letter_state.mult,
			" growth=", letter_state.growth,
			" base_mult=", entry["base_mult"],
			" bonus_mult=", entry["bonus_mult"],
			" entry_multiplier=", entry["multiplier"],
			" triggers_before=", letter_state.patterns_this_hand.size()
		)
func get_vowel_expanded_words(word: String) -> Array:
	var results := [word]

	while true:
		var expanded := false
		var next_results := []

		for candidate in results:
			var index = candidate.find("@")

			if index == -1:
				next_results.append(candidate)
				continue

			expanded = true

			for vowel in ["a", "e", "i", "o", "u"]:
				var new_word = candidate
				new_word[index] = vowel
				next_results.append(new_word)

		results = next_results

		if !expanded:
			break

	return results
	
func score_combo(combo, pattern_id, trigger_word := ""):
	var data = build_score_data(combo, pattern_id)

	if trigger_word != "":
		data["word"] = trigger_word

	for sticker in get_active_stickers():
		data = sticker.modify_score_data(data)

	var final_score = calculate_score_from_data(data)

	debug_log_combo_trigger(combo, pattern_id, data, final_score)


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
	dictionary.clear()

	if debug_sticker_sandbox:
		for word in debug_dictionary_words:
			dictionary[word.to_lower()] = true

		print("=== DEBUG DICTIONARY LOADED ===")
		print(dictionary.keys())
		return

	var file = FileAccess.open("res://enable1.txt", FileAccess.READ)

	if file == null:
		push_error("Could not load dictionary at res://enable1.txt")
		return

	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_lower()

		if word != "":
			dictionary[word] = true
func print_debug_trigger_summary():
	if !debug_sticker_sandbox:
		return

	var letter_data := {}

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var letter_state = grid[y][x]

			if letter_state.is_blank():
				continue

			var letter = letter_state.letter

			letter_data[letter] = {
				"trigger_count": letter_state.patterns_this_hand.size(),
				"final_mult": letter_state.mult,
				"patterns": letter_state.patterns_this_hand.duplicate()
			}

	print("=== DEBUG TRIGGER SUMMARY ===")

	var letters = letter_data.keys()
	letters.sort()

	var frequency_buckets := {}

	for letter in letters:
		var info = letter_data[letter]
		var trigger_count = info["trigger_count"]

		print(
			letter,
			": triggers=", trigger_count,
			" final_mult=", info["final_mult"],
			" patterns=", info["patterns"]
		)

		frequency_buckets[trigger_count] = frequency_buckets.get(trigger_count, 0) + 1

	for trigger_count in frequency_buckets.keys():
		debug_trigger_frequency_totals[trigger_count] = (
			debug_trigger_frequency_totals.get(trigger_count, 0)
			+ frequency_buckets[trigger_count]
		)

	print("\n=== TRIGGER FREQUENCY DISTRIBUTION ===")

	var bucket_keys = frequency_buckets.keys()
	bucket_keys.sort()
	bucket_keys.reverse()

	for trigger_count in bucket_keys:
		print(
			frequency_buckets[trigger_count],
			" letters triggered ",
			trigger_count,
			" times"
		)



	
func print_debug_final_trigger_summary():
	if !debug_sticker_sandbox:
		return

	print("\n=== FINAL 5-HAND TRIGGER FREQUENCY SUMMARY ===")

	for trigger_count in [12,11,10,9,8,7,6, 5, 4,3,2,1,0]:
		print(
			debug_trigger_frequency_totals.get(trigger_count, 0),
			" total letter-results triggered ",
			trigger_count,
			" times"
		)
func get_active_stickers() -> Array:
	return owned_stickers + teacher_stickers

func apply_teacher_modifiers(teacher):
	teacher_stickers.clear()

	for sticker in teacher.get_stickers():
		teacher_stickers.append(sticker)
		
func clear_teacher_modifiers():
	for sticker in teacher_stickers:
		sticker.reset()

	teacher_stickers.clear()


# ============================================================
# Debug Sticker Sandbox
# ============================================================

func setup_debug_sticker_sandbox():
	print("DEBUG STICKER SANDBOX ENABLED")
	randomize()

	if debug_add_test_stickers:
		add_debug_test_stickers()

	update_owned_permanent_ui()

func reset_debug_sticker_sandbox_for_grade():
	debug_letter_draw_index = 0
	debug_played_rows = 0
	debug_trigger_frequency_totals.clear()
	debug_trigger_event_index = 0

func add_debug_test_stickers():
	owned_stickers.clear()

	setup_debug_stickers()
func setup_debug_stickers():
	if !debug_sticker_sandbox:
		return

	for sticker_class in debug_test_stickers:
		var sticker = sticker_class.new()
		sticker.game = self
		owned_stickers.append(sticker)

	print("=== DEBUG STICKER SANDBOX ENABLED ===")
func draw_debug_letter() -> String:
	if debug_draw_order.is_empty():
		return "E"

	var letter = debug_draw_order[debug_letter_draw_index % debug_draw_order.size()]
	debug_letter_draw_index += 1
	return letter

func debug_play_all_hands():
	while debug_sticker_sandbox and game_phase == GamePhase.PLAYING and hands_left > 0 and debug_played_rows < GRID_SIZE:
		await get_tree().create_timer(0.15).timeout
		await play_selected_cards()

	print_debug_final_trigger_summary()

func debug_select_next_row_cards():
	if debug_played_rows >= GRID_SIZE:
		return

	var row_start = debug_played_rows * GRID_PLACE_SIZE
	var target_letters := []

	for i in range(GRID_PLACE_SIZE):
		var index = row_start + i

		if index >= debug_draw_order.size():
			return

		target_letters.append(debug_draw_order[index])

	selected_cards.clear()

	for target_letter in target_letters:
		var card = find_first_unselected_card_with_letter(target_letter)

		if card != null:
			selected_cards.append(card)

	if selected_cards.size() == GRID_PLACE_SIZE:
		debug_played_rows += 1
		auto_center_preview()
		update_hand_ui()
	else:
		push_warning("Debug sandbox could not auto-select row " + str(debug_played_rows + 1) + ". Needed: " + str(target_letters))


func find_first_unselected_card_with_letter(letter: String):
	for card in hand:
		if selected_cards.has(card):
			continue

		if card["letter"] == letter:
			return card

	return null


func load_debug_dictionary():
	dictionary.clear()

	var debug_grid := [
		["A", "B", "C", "D", "E"],
		["F", "G", "H", "I", "J"],
		["K", "L", "M", "N", "O"],
		["P", "Q", "R", "S", "T"],
		["U", "V", "W", "X", "Y"]
	]

	add_debug_words_from_lines(debug_grid, "H")
	add_debug_words_from_lines(transpose_debug_grid(debug_grid), "V")
	add_debug_words_from_lines(get_debug_diagonal_letter_lines(debug_grid), "D")

	# Long-word checks still use the real dictionary path, so include a few
	# deterministic long test words too.
	dictionary["abcdef"] = true
	dictionary["abcdefg"] = true
	dictionary["abcdefghi"] = true

	print("Loaded debug dictionary words: ", dictionary.size())


func add_debug_words_from_lines(lines: Array, _direction: String):
	for line in lines:
		for length in range(3, min(GRID_SIZE, line.size()) + 1):
			for start in range(0, line.size() - length + 1):
				var word := ""

				for i in range(start, start + length):
					word += line[i]

				dictionary[word.to_lower()] = true


func transpose_debug_grid(source_grid: Array) -> Array:
	var result := []

	for x in range(GRID_SIZE):
		var line := []

		for y in range(GRID_SIZE):
			line.append(source_grid[y][x])

		result.append(line)

	return result


func get_debug_diagonal_letter_lines(source_grid: Array) -> Array:
	var lines := []

	for start_x in range(GRID_SIZE):
		lines.append(make_debug_letter_line(source_grid, 0, start_x, 1, 1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_debug_letter_line(source_grid, start_y, 0, 1, 1))

	for start_x in range(GRID_SIZE):
		lines.append(make_debug_letter_line(source_grid, 0, start_x, 1, -1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_debug_letter_line(source_grid, start_y, GRID_SIZE - 1, 1, -1))

	return lines


func make_debug_letter_line(source_grid: Array, start_y: int, start_x: int, dy: int, dx: int) -> Array:
	var line := []
	var y := start_y
	var x := start_x

	while y >= 0 and y < GRID_SIZE and x >= 0 and x < GRID_SIZE:
		line.append(source_grid[y][x])
		y += dy
		x += dx

	return line


func reset_hand_stickers():
	for sticker in get_active_stickers():
		if sticker.resets_each_hand:
			sticker.reset()
func build_debug_dictionary():
	pass

# ============================================================
# UI Rendering
# ============================================================

func update_hand_ui():
	clear_container(linear_hand_container)
	clear_container(circle_hand_container)
	clear_container(selected_container)

	var use_circle = hand_view_mode == HandViewMode.CIRCLE

	linear_hand_container.visible = !use_circle
	circle_hand_container.visible = use_circle

	var active_hand_container: Control

	if use_circle:
		active_hand_container = circle_hand_container
	else:
		active_hand_container = linear_hand_container

	var visible_cards := []

	for card in hand:
		visible_cards.append(card)

	for i in range(visible_cards.size()):
		var card = visible_cards[i]

		var card_ui = CARD_SCENE.instantiate()
		card_ui.setup(card, false)
		card_ui.pressed.connect(_on_card_pressed.bind(card))
		if selected_cards.has(card):
			card_ui.modulate = Color(1, 1, 1, 0.15)
		else:
			card_ui.modulate = Color(1, 1, 1, 1)

		active_hand_container.add_child(card_ui)

		if use_circle:
			position_card_in_circle(card_ui, active_hand_container, i, visible_cards.size())
		else:
			position_card_linear(card_ui, active_hand_container, i, visible_cards.size())

	update_selected_preview_ui()

func position_card_in_circle(card_ui: Control, container: Control, index: int, total: int):
	var radius: float = 250.0
	var center: Vector2 = container.size / 2.0

	if total <= 1:
		card_ui.position = center - card_ui.size / 2.0
		card_ui.rotation = 0.0
		return

	var angle: float = -PI / 2.0 + TAU * float(index) / float(total)

	var x: float = cos(angle) * radius
	var y: float = sin(angle) * radius

	card_ui.position = center + Vector2(x, y) - card_ui.size / 2.0
	card_ui.rotation = 0.0
func position_card_linear(card_ui: Control, container: Control, index: int, total: int):
	var spacing: float = 76.0
	var total_width: float = spacing * float(total - 1)
	var start_x: float = container.size.x / 2.0 - total_width / 2.0
	var y: float = container.size.y / 2.0 - card_ui.size.y / 2.0

	card_ui.position = Vector2(start_x + float(index) * spacing, y)
	card_ui.rotation = 0.0
func update_selected_preview_ui():
	clear_container(selected_container)

	var active_start = get_active_window_start()

	for i in range(PREVIEW_SLOT_COUNT):
		var slot = create_preview_slot(i, active_start)
		selected_container.add_child(slot)


func create_preview_slot(slot_index, active_start):
	var slot = PanelContainer.new()
	slot.custom_minimum_size = Vector2(72, 128)
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

	style.bg_color = Color(1, 1, 1, 0.05)
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
		style.bg_color = Color(1, 1, 0.85, 0.13)
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
	if locked_cards.has(card):
		card_ui.modulate = Color(1.0, 0.9, 0.45, 1.0)
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
	tween.tween_property(label, "position:y", -12, anim_time(0.08))
	tween.tween_property(label, "rotation_degrees", -8, anim_time(0.04))
	tween.tween_property(label, "rotation_degrees", 8, anim_time(0.04))
	tween.tween_property(label, "rotation_degrees", -5, anim_time(0.04))
	tween.tween_property(label, "rotation_degrees", 0, anim_time(0.04))
	tween.tween_property(label, "position:y", 0, anim_time(0.12))

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
	tween.tween_property(floating_label, "scale", Vector2(1.3, 1.3), anim_time(0.08))
	tween.tween_property(floating_label, "scale", Vector2(1.0, 1.0), anim_time(0.08))
	tween.tween_property(floating_label, "global_position", end_pos, anim_time(0.35))
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, anim_time(0.25))
	tween.parallel().tween_property(floating_label, "scale", Vector2(0.4, 0.4), anim_time(0.25))

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
	tween.tween_property(label, "modulate:a", 1.0, anim_time(0.12))
	tween.parallel().tween_property(label, "scale", Vector2(1.2, 1.2), anim_time(0.18))
	tween.tween_property(label, "scale", Vector2(1.0, 1.0), anim_time(0.08))
	tween.tween_interval(anim_time(0.35))
	tween.tween_property(label, "global_position", score_label.global_position + score_label.size / 2, anim_time(0.35))
	tween.parallel().tween_property(label, "modulate:a", 0.0, anim_time(0.25))
	tween.parallel().tween_property(label, "scale", Vector2(0.3, 0.3), anim_time(0.25))

	await tween.finished

	label.queue_free()
	animate_score_label_bump()


func animate_score_label_bump():
	var bump = create_tween()
	bump.tween_property(score_label, "scale", Vector2(1.2, 1.2), anim_time(0.08))
	bump.tween_property(score_label, "scale", Vector2(1.0, 1.0), anim_time(0.08))


func animate_shop_purchase(button):
	var original_scale = button.scale
	var original_modulate = button.modulate

	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 1.15, anim_time(0.08))
	tween.tween_property(button, "scale", original_scale, anim_time(0.08))
	tween.parallel().tween_property(button, "modulate:a", 0.45, anim_time(0.15))

	await tween.finished

	button.modulate = original_modulate


func animate_cant_afford(button):
	var original_pos = button.position

	var tween = create_tween()
	tween.tween_property(button, "position:x", original_pos.x - 8, anim_time(0.04))
	tween.tween_property(button, "position:x", original_pos.x + 8, anim_time(0.04))
	tween.tween_property(button, "position:x", original_pos.x - 5, anim_time(0.04))
	tween.tween_property(button, "position:x", original_pos.x + 5, anim_time(0.04))
	tween.tween_property(button, "position:x", original_pos.x, anim_time(0.04))

	await tween.finished
func anim_time(seconds: float) -> float:
	if debug_sticker_sandbox:
		return seconds / debug_animation_speed

	return seconds

# ============================================================
# Save / Load
# ============================================================

func save_game():
	var data = {

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
