extends Node

const HAND_SIZE := 10
const MAX_PLAY := 5
const GRID_SIZE := 5
const HANDS_PER_GRADE := 5
const CARD_SCENE := preload("res://Card.tscn")
@onready var permanent_item_bar = $RootUI/PermanentItemBar
var owned_permanents = []
var shop_permanent_items = []
var shop_consumable_items = []

var score_upgrades = {
	"H3": 0, "H4": 0, "H5": 0,
	"V3": 0, "V4": 0, "V5": 0,
	"D3": 0, "D4": 0, "D5": 0
}

var permanent_pool = [
	{"name": "Gold Star", "cost": 6, "description": "Placeholder permanent item."},
	{"name": "Pencil Case", "cost": 7, "description": "Placeholder permanent item."},
	{"name": "Eraser", "cost": 8, "description": "Placeholder permanent item."},
	{"name": "Hall Pass", "cost": 9, "description": "Placeholder permanent item."},
	{"name": "Detention Slip", "cost": 10, "description": "Placeholder permanent item."}
]

var consumable_pool = [
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
@onready var perma_shop = $RootUI/ShopPanel/PermaShop
@onready var consume_shop = $RootUI/ShopPanel/ConsumeShop

enum GamePhase {
	PLAYING,
	SHOP,
	GAME_OVER,
	WIN
}

var game_phase := GamePhase.PLAYING

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
var letter_mults := []

var current_row := 0
var current_col := 0

var dictionary := {}

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

@onready var top_bar = $RootUI/TopBar
@onready var gameplay_ui = $RootUI/GameplayUI
@onready var shop_panel = $RootUI/ShopPanel

@onready var stage_label = $RootUI/TopBar/StageLabel
@onready var money_label = $RootUI/TopBar/MoneyLabel
@onready var target_label = $RootUI/TopBar/TargetLabel
@onready var hands_label = $RootUI/TopBar/HandsLabel

@onready var score_label = $RootUI/GameplayUI/ScoreLabel
@onready var grid_container = $RootUI/GameplayUI/GridContainer
@onready var selected_container = $RootUI/GameplayUI/SelectedContainer
@onready var hand_container = $RootUI/GameplayUI/HandContainer

@onready var next_grade_button = $RootUI/ShopPanel/NextGradeButton

func _ready():
	load_dictionary()
	create_starting_deck()
	create_grid()

	shop_panel.visible = false
	gameplay_ui.visible = true

	next_grade_button.pressed.connect(_on_next_grade_pressed)

	draw_to_hand()
	update_grid_ui()
	update_stage_ui()


# ------------------------------------------------------------
# Stage / economy
# ------------------------------------------------------------

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

	var result = []

	for i in range(min(count, copy.size())):
		result.append(copy[i])

	return result
func _on_permanent_item_pressed(item, button):
	if money < item["cost"]:
		print("Not enough money")
		return

	money -= item["cost"]
	owned_permanents.append(item)
	update_owned_permanent_ui()

	button.disabled = true
	button.text = item["name"] + " - BOUGHT"

	update_stage_ui()
	print("Bought permanent: ", item["name"])
func update_owned_permanent_ui():
	for child in permanent_item_bar.get_children():
		child.queue_free()

	for item in owned_permanents:
		var label = Label.new()
		label.text = item["name"]
		label.tooltip_text = item["description"]
		permanent_item_bar.add_child(label)
func _on_consumable_item_pressed(item, button):
	if money < item["cost"]:
		print("Not enough money")
		return

	money -= item["cost"]

	var id = item["id"]
	score_upgrades[id] += 1

	button.disabled = true
	button.text = item["name"] + " - BOUGHT"

	update_stage_ui()
	print("Bought consumable: ", item["name"])
func make_shop_button(item):
	var button = Button.new()
	button.text = item["name"] + " - $" + str(item["cost"])
	button.tooltip_text = item["description"]
	button.custom_minimum_size = Vector2(140, 60)

	return button	
		
func _on_next_grade_pressed():
	if game_phase != GamePhase.SHOP:
		return

	advance_grade()


func advance_grade():
	grade_index += 1

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

	create_grid()
	update_grid_ui()
	update_hand_ui()
	update_stage_ui()

func win_run():
	game_phase = GamePhase.WIN
	gameplay_ui.visible = false
	shop_panel.visible = false
	print("YOU GRADUATED")


# ------------------------------------------------------------
# Deck / hand
# ------------------------------------------------------------

func create_starting_deck():
	deck.clear()

	var letters = [
		"A","A","A","A",
		"E","E","E","E",
		"R","R","R",
		"T","T","T",
		"O","O","O",
		"N","N",
		"S","S",
		"L","L",
		"D","D",
		"G","M","P","B","C","F"
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
	if selected_cards.has(card):
		selected_cards.erase(card)
	else:
		if selected_cards.size() < MAX_PLAY:
			selected_cards.append(card)

	update_hand_ui()


func _on_card_pressed(card):
	toggle_select(card)


func _on_selected_card_pressed(card):
	selected_cards.erase(card)
	update_hand_ui()


# ------------------------------------------------------------
# Play hand
# ------------------------------------------------------------

func play_selected_cards():
	if game_phase != GamePhase.PLAYING:
		return

	if selected_cards.is_empty():
		return

	if hands_left <= 0:
		return

	var played_count = selected_cards.size()

	for card in selected_cards:
		place_card_on_grid(card)
		hand.erase(card)
		discard.append(card)

	for i in range(MAX_PLAY - played_count):
		place_blank_on_grid()

	selected_cards.clear()
	hands_left -= 1

	draw_to_hand()
	update_grid_ui()
	update_stage_ui()

	await score_grid()

	check_grade_result()
	update_stage_ui()


func place_card_on_grid(card):
	if current_row >= GRID_SIZE:
		print("GRID FULL")
		return

	grid[current_row][current_col] = card["letter"]
	advance_grid_cursor()


func place_blank_on_grid():
	if current_row >= GRID_SIZE:
		print("GRID FULL")
		return

	grid[current_row][current_col] = "_"
	advance_grid_cursor()


func advance_grid_cursor():
	current_col += 1

	if current_col >= GRID_SIZE:
		current_col = 0
		current_row += 1


# ------------------------------------------------------------
# Grid
# ------------------------------------------------------------

func create_grid():
	grid.clear()
	letter_mults.clear()

	for y in range(GRID_SIZE):
		var row = []
		var mult_row = []

		for x in range(GRID_SIZE):
			row.append("_")
			mult_row.append(0)

		grid.append(row)
		letter_mults.append(mult_row)


func get_horizontal_lines():
	var lines = []

	for y in range(GRID_SIZE):
		var line = []

		for x in range(GRID_SIZE):
			line.append([y, x])

		lines.append(line)

	return lines


func get_vertical_lines():
	var lines = []

	for x in range(GRID_SIZE):
		var line = []

		for y in range(GRID_SIZE):
			line.append([y, x])

		lines.append(line)

	return lines


func get_diagonal_lines():
	var lines = []

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
	var line = []
	var y = start_y
	var x = start_x

	while y >= 0 and y < GRID_SIZE and x >= 0 and x < GRID_SIZE:
		line.append([y, x])
		y += dy
		x += dx

	return line


# ------------------------------------------------------------
# Scoring
# ------------------------------------------------------------

func score_grid():
	var grade_score = 0

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
	var score = 0

	for line in lines:
		if line.size() < length:
			continue

		for start in range(0, line.size() - length + 1):
			var combo = line.slice(start, start + length)

			if combo_has_blank(combo):
				continue

			var word = combo_to_string(combo)

			if is_valid_combo(word):
				var combo_score = score_combo(combo, direction, length)
				score += combo_score

				print(word, " scored ", combo_score)

				await animate_combo(combo)
				await show_combo_score(combo, combo_score)

	return score


func combo_has_blank(combo):
	for pos in combo:
		var y = pos[0]
		var x = pos[1]

		if grid[y][x] == "_":
			return true

	return false


func combo_to_string(combo):
	var s = ""

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		s += grid[y][x]

	return s


func score_combo(combo, direction, length):
	var mult_sum = 1

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		mult_sum += letter_mults[y][x]

	var upgrade_id = direction + str(length)
	var effective_length = combo.size() + score_upgrades[upgrade_id]

	var points = mult_sum * effective_length

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		letter_mults[y][x] += 1

	return points

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


# ------------------------------------------------------------
# UI
# ------------------------------------------------------------

func update_hand_ui():
	for child in hand_container.get_children():
		child.queue_free()

	for child in selected_container.get_children():
		child.queue_free()

	for card in hand:
		if selected_cards.has(card):
			continue

		var card_ui = CARD_SCENE.instantiate()
		card_ui.setup(card, false)
		card_ui.pressed.connect(_on_card_pressed.bind(card))
		hand_container.add_child(card_ui)

	for card in selected_cards:
		var card_ui = CARD_SCENE.instantiate()
		card_ui.setup(card, true)
		card_ui.scale = Vector2(0.8, 0.8)
		card_ui.pressed.connect(_on_selected_card_pressed.bind(card))
		selected_container.add_child(card_ui)


func update_grid_ui():
	reset_grid_visuals()

	var i = 0

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell = grid_container.get_child(i)
			var label = cell.get_node("Label")
			label.text = grid[y][x]
			i += 1


func reset_grid_visuals():
	for cell in grid_container.get_children():
		var label = cell.get_node("Label")
		label.position = Vector2.ZERO
		label.rotation_degrees = 0


func animate_combo(combo):
	var tweens = []

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
	var start_pos = Vector2.ZERO

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		var index = y * GRID_SIZE + x
		var cell = grid_container.get_child(index)

		start_pos += cell.global_position + cell.size / 2

	start_pos /= combo.size()

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

	var bump = create_tween()
	bump.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	bump.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.08)


# ------------------------------------------------------------
# Save / load
# ------------------------------------------------------------

func save_game():
	var data = {
		"deck": deck,
		"discard": discard,
		"hand": hand,
		"selected_cards": selected_cards,
		"grid": grid,
		"letter_mults": letter_mults,
		"row": current_row,
		"col": current_col,
		"total_score": total_score,
		"money": money,
		"hands_left": hands_left,
		"school_index": school_index,
		"grade_index": grade_index,
		"game_phase": game_phase
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
	grid = json["grid"]
	letter_mults = json.get("letter_mults", letter_mults)

	current_row = json["row"]
	current_col = json["col"]

	total_score = json.get("total_score", 0)
	money = json.get("money", 0)
	hands_left = json.get("hands_left", HANDS_PER_GRADE)

	school_index = json.get("school_index", 0)
	grade_index = json.get("grade_index", 0)
	game_phase = json.get("game_phase", GamePhase.PLAYING)

	gameplay_ui.visible = game_phase == GamePhase.PLAYING
	shop_panel.visible = game_phase == GamePhase.SHOP

	update_hand_ui()
	update_grid_ui()
	update_stage_ui()
