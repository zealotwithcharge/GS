extends Node
const HANDS_PER_GRADE = 5

enum GamePhase {
	PLAYING,
	SHOP,
	GAME_OVER,
	WIN
}

var game_phase = GamePhase.PLAYING

var money = 0
var hands_left = HANDS_PER_GRADE

var school_index = 0
var grade_index = 0
@onready var stage_label = get_node("GameplayUI/StageLabel")
@onready var money_label = get_node("GameplayUI/MoneyLabel")
@onready var target_label = get_node("GameplayUI/TargetLabel")
@onready var hands_label = get_node("GameplayUI/HandsLabel")
@onready var shop_panel = get_node("GameplayUI/ShopPanel")
@onready var next_grade_button = get_node("GameplayUI/ShopPanel/NextGradeButton")

var schools = [
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



func get_current_target_score():
	var school = get_current_school()
	return school["base_target"] + grade_index * 100


func get_current_reward():
	var school = get_current_school()
	return school["reward"] + grade_index
func check_grade_complete():
	if total_score >= get_current_target_score():
		complete_grade()
const HAND_SIZE = 10
const MAX_PLAY = 5
const GRID_SIZE = 5
var total_score = 0
@onready var score_label = get_node("GameplayUI/ScoreLabel")
var deck = []
var discard = []
var letter_mults = [] # same shape as grid
var hand = []
var selected_cards = []
var current_grade_modifier = null
var grid = []

var current_row = 0
var current_col = 0

func _ready():
	load_dictionary()
	create_starting_deck()
	create_grid()
	draw_to_hand()
	update_stage_ui()
	shop_panel.visible = false
	next_grade_button.pressed.connect(_on_next_grade_pressed)
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
	print(letters)
	var uid = 0

	for l in letters:
		var card = {
			"id": uid,
			"letter": l
		}

		deck.append(card)
		uid += 1

	deck.shuffle()

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
		
func score_grid():
	var total_score = 0

	var horizontal_lines = get_horizontal_lines()
	var vertical_lines = get_vertical_lines()
	var diagonal_lines = get_diagonal_lines()

	for length in range(3, GRID_SIZE + 1):
		total_score += await score_lines_by_length(horizontal_lines, length)

	for length in range(3, GRID_SIZE + 1):
		total_score += await score_lines_by_length(vertical_lines, length)

	for length in range(3, GRID_SIZE + 1):
		total_score += await score_lines_by_length(diagonal_lines, length)

	print("Score: ", total_score)
	return total_score
func get_all_scoring_lines():
	var lines = []

	# horizontals
	for y in range(GRID_SIZE):
		var line = []
		for x in range(GRID_SIZE):
			line.append([y, x])
		lines.append(line)

	# verticals
	for x in range(GRID_SIZE):
		var line = []
		for y in range(GRID_SIZE):
			line.append([y, x])
		lines.append(line)

	# diagonals down-right
	for start_x in range(GRID_SIZE):
		lines.append(make_line(0, start_x, 1, 1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_line(start_y, 0, 1, 1))

	# diagonals down-left
	for start_x in range(GRID_SIZE):
		lines.append(make_line(0, start_x, 1, -1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_line(start_y, GRID_SIZE - 1, 1, -1))

	return lines

func score_lines_by_length(lines, length):
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
				var combo_score = score_combo(combo)
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
func score_line(line):
	var score = 0

	for length in range(3, line.size() + 1):
		for start in range(0, line.size() - length + 1):
			var combo = line.slice(start, start + length)
			var word = combo_to_string(combo)

			if is_valid_combo(word):
				var combo_score = score_combo(combo)
				score += combo_score

				print(word, " scored ", combo_score)

				await animate_combo(combo)
				await show_combo_score(combo, combo_score)

	return score
func show_combo_score(combo, combo_score):
	var grid_container = get_node("GameplayUI/GridContainer")

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

	get_tree().current_scene.add_child(floating_label)

	var tween = create_tween()

	# pop up slightly first
	tween.tween_property(floating_label, "scale", Vector2(1.3, 1.3), 0.08)
	tween.tween_property(floating_label, "scale", Vector2(1.0, 1.0), 0.08)

	# fly to score label
	tween.tween_property(floating_label, "global_position", end_pos, 0.35)

	# disappear into score label
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 0.25)
	tween.parallel().tween_property(floating_label, "scale", Vector2(0.4, 0.4), 0.25)

	await tween.finished

	floating_label.queue_free()

	total_score += combo_score
	score_label.text = "Score: " + str(total_score)

	# little bump on total score
	var bump = create_tween()
	bump.tween_property(score_label, "scale", Vector2(1.2, 1.2), 0.08)
	bump.tween_property(score_label, "scale", Vector2(1.0, 1.0), 0.08)
func combo_to_string(combo):
	var s = ""

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		s += grid[y][x]

	return s		
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
			return

		hand.append(card)

	update_hand_ui()

func toggle_select(card):
	print("heo")
	
	if selected_cards.has(card):
		selected_cards.erase(card)

	else:
		if selected_cards.size() < MAX_PLAY:
			selected_cards.append(card)


	update_hand_ui()

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

func _on_next_grade_pressed():
	if game_phase != GamePhase.SHOP:
		return

	shop_panel.visible = false
	advance_grade()
func fail_grade():
	game_phase = GamePhase.GAME_OVER
	print("FAILED GRADE")
	# later: show game over UI
	

func open_shop():
	shop_panel.visible = true
	update_stage_ui()
	print("SHOP OPEN")
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

	total_score = 0
	hands_left = HANDS_PER_GRADE

	current_row = 0
	current_col = 0
	selected_cards.clear()

	create_grid()
	update_grid_ui()
	update_hand_ui()
	update_stage_ui()

	print("Starting ", get_current_school()["name"], " Grade ", get_current_grade_number())
func start_next_grade():
	total_score = 0
	score_label.text = "Score: 0"

	create_grid()
	current_row = 0
	current_col = 0

	update_grid_ui()
	update_stage_ui()

	print("Now entering ", get_current_school()["name"], " Grade ", get_current_grade_number())
func win_run():
	game_phase = GamePhase.WIN
	print("YOU GRADUATED")
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

	# diagonals down-right
	for start_x in range(GRID_SIZE):
		lines.append(make_line(0, start_x, 1, 1))

	for start_y in range(1, GRID_SIZE):
		lines.append(make_line(start_y, 0, 1, 1))

	# diagonals down-left
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

func place_card_on_grid(card):
	
	if current_row >= GRID_SIZE:
		print("GRID FULL")
		return

	grid[current_row][current_col] = card["letter"]

	current_col += 1

	if current_col >= GRID_SIZE:
		current_col = 0
		current_row += 1
		
func place_blank_on_grid():
	if current_row >= GRID_SIZE:
		print("GRID FULL")
		return

	grid[current_row][current_col] = "_"

	current_col += 1

	if current_col >= GRID_SIZE:
		current_col = 0
		current_row += 1
		
func update_hand_ui():
	var hand_container = get_node("GameplayUI/HandContainer")
	var selected_container = get_node("GameplayUI/SelectedContainer")

	for child in hand_container.get_children():
		child.queue_free()

	for child in selected_container.get_children():
		child.queue_free()

	# HAND
	for card in hand:
		if selected_cards.has(card):
			continue

		var scene = preload("res://Card.tscn")
		var card_ui = scene.instantiate()

		card_ui.setup(card, false)

		card_ui.pressed.connect(_on_card_pressed.bind(card))

		hand_container.add_child(card_ui)

	# PREVIEW ROW
	for card in selected_cards:
		var scene = preload("res://Card.tscn")
		var card_ui = scene.instantiate()

		card_ui.setup(card, true)

		# slightly smaller
		card_ui.scale = Vector2(0.8, 0.8)

		# clicking removes from queue
		card_ui.pressed.connect(_on_selected_card_pressed.bind(card))

		selected_container.add_child(card_ui)
func _on_selected_card_pressed(card):
	selected_cards.erase(card)
	update_hand_ui()
func update_grid_ui():
	reset_grid_visuals()

	var grid_container = get_node("GameplayUI/GridContainer")
	var i = 0

	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell = grid_container.get_child(i)
			var label = cell.get_node("Label")
			label.text = grid[y][x]
			i += 1

var dictionary = {}

func load_dictionary():
	var file = FileAccess.open("res://enable1.txt", FileAccess.READ)

	while not file.eof_reached():
		var word = file.get_line().strip_edges().to_lower()

		if word != "":
			dictionary[word] = true		
func is_valid_combo(word: String) -> bool:
	word = word.to_lower()

	# reject empty cells / blanks
	if word.contains("_"):
		return false

	if word.contains(" "):
		return false

	if word.length() < 3:
		return false

	if word.length() != 3 and word.strip_edges() == "":
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
func score_combo(combo):
	var mult_sum = 1

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		mult_sum += letter_mults[y][x]

	var points = mult_sum * combo.size()

	for pos in combo:
		var y = pos[0]
		var x = pos[1]
		letter_mults[y][x] += 1

	return points
func animate_combo(combo):
	var grid_container = get_node("GameplayUI/GridContainer")
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
func _on_card_pressed(card):
	toggle_select(card)
func reset_grid_visuals():
	var grid_container = get_node("GameplayUI/GridContainer")

	for cell in grid_container.get_children():
		var label = cell.get_node("Label")
		label.position = Vector2.ZERO
		label.rotation_degrees = 0
func save_game():
	var data = {
		"deck": deck,
		"discard": discard,
		"hand": hand,
		"grid": grid,
		"row": current_row,
		"col": current_col
	}

	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

func load_game():
	if !FileAccess.file_exists("user://save.json"):
		return

	var file = FileAccess.open("user://save.json", FileAccess.READ)

	var json = JSON.parse_string(file.get_as_text())

	deck = json["deck"]
	discard = json["discard"]
	hand = json["hand"]
	grid = json["grid"]
	current_row = json["row"]
	current_col = json["col"]

	update_hand_ui()
	update_grid_ui()
