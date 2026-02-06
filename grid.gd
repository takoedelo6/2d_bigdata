extends Node2D

const SAVE_PATH = "user://session_save.cfg"

# --- ДАННЫЕ МИРА ---
var balance_usd = 1000.0
var npc_balance_usd = 500.0 
var houses = [] 
var is_selected = false

# Позиция второго персонажа (NPC)
var npc_position = Vector2(400, 300)

# --- ССЫЛКИ ---
@onready var character = $"../Graph" 

# --- НАВИГАЦИЯ ---
var map_offset = Vector2.ZERO
var zoom_level = 1.0
var min_zoom = 0.05
var max_zoom = 8.0

func _ready():
	load_session()

# Функция: Игрок дает деньги NPC
func give_money_to_npc():
	if balance_usd >= 100.0:
		balance_usd -= 100.0
		npc_balance_usd += 100.0
		print("Вы дали $100. Ваш баланс: $", balance_usd)
	else:
		print("У вас нет $100!")

# Функция: NPC дает деньги игроку
func take_money_from_npc():
	if npc_balance_usd >= 100.0:
		npc_balance_usd -= 100.0
		balance_usd += 100.0
		print("NPC дал вам $100. Ваш баланс: $", balance_usd)
	else:
		print("У NPC закончились деньги!")

func save_session():
	var config = ConfigFile.new()
	config.set_value("session", "character_pos", character.global_position)
	config.set_value("session", "map_offset", map_offset)
	config.set_value("session", "zoom_level", float(zoom_level)) 
	config.set_value("session", "houses", houses)
	config.set_value("session", "balance", balance_usd)
	config.set_value("session", "npc_balance", npc_balance_usd)
	config.save(SAVE_PATH)

func load_session():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		character.global_position = config.get_value("session", "character_pos", Vector2.ZERO)
		map_offset = config.get_value("session", "map_offset", Vector2.ZERO)
		zoom_level = config.get_value("session", "zoom_level", 1.0)
		houses = config.get_value("session", "houses", [])
		balance_usd = config.get_value("session", "balance", 1000.0)
		npc_balance_usd = config.get_value("session", "npc_balance", 500.0)

func _process(_delta):
	queue_redraw()

func _draw():
	var view_size = get_viewport_rect().size
	
	# 1. СЕТКА
	var grid_step = 100.0 * zoom_level
	if grid_step > 2.0:
		var start_x = fmod(map_offset.x, grid_step)
		var start_y = fmod(map_offset.y, grid_step)
		for x in range(int(start_x), int(view_size.x), int(grid_step)):
			draw_line(Vector2(x, 0), Vector2(x, view_size.y), Color(0.15, 0.15, 0.15))
		for y in range(int(start_y), int(view_size.y), int(grid_step)):
			draw_line(Vector2(0, y), Vector2(view_size.x, y), Color(0.15, 0.15, 0.15))
	
	# 2. ДОМА
	var house_size = 50.0 * zoom_level
	for h_pos in houses:
		var draw_pos = h_pos * zoom_level + map_offset
		var rect = Rect2(draw_pos - Vector2(house_size/2, house_size/2), Vector2(house_size, house_size))
		draw_rect(rect, Color("5d4037")) 
		draw_rect(rect, Color.BLACK, false, 1.0)

	# 3. ВТОРОЙ ПЕРСОНАЖ (NPC)
	var npc_draw_pos = npc_position * zoom_level + map_offset
	draw_circle(npc_draw_pos, 20.0 * zoom_level, Color("ff4500")) 
	draw_string(ThemeDB.fallback_font, npc_draw_pos + Vector2(-30, -35)*zoom_level, "NPC Balance: $" + str(int(npc_balance_usd)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * zoom_level)

	# 4. ИГРОК
	var char_draw_pos = character.global_position * zoom_level + map_offset
	var radius = 20.0 * zoom_level
	if is_selected:
		draw_circle(char_draw_pos, radius + 5.0, Color(1, 1, 1, 0.3)) 
	draw_circle(char_draw_pos, radius, Color("32cd32"))

	# 5. ИНТЕРФЕЙС
	draw_rect(Rect2(Vector2(10, 10), Vector2(260, 115)), Color(0, 0, 0, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(20, 35), "Your Balance: $" + str(int(balance_usd)), HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(ThemeDB.fallback_font, Vector2(20, 55), "[E] Build | [X] Remove", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(ThemeDB.fallback_font, Vector2(20, 75), "[T] Give $100 to NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.8, 1))
	draw_string(ThemeDB.fallback_font, Vector2(20, 90), "[Y] Take $100 from NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.8, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(20, 105), "[F5] Save Progress", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			if balance_usd >= 100.0:
				houses.append(character.global_position)
				balance_usd -= 100.0
		
		if event.keycode == KEY_X:
			var mouse_pos = get_local_mouse_position()
			var house_size = 50.0 * zoom_level
			for i in range(houses.size() - 1, -1, -1):
				var h_pos = houses[i]
				var draw_pos = h_pos * zoom_level + map_offset
				var rect = Rect2(draw_pos - Vector2(house_size/2, house_size/2), Vector2(house_size, house_size))
				if rect.has_point(mouse_pos):
					houses.remove_at(i)
					balance_usd += 100.0
					break
					
		if event.keycode == KEY_F5:
			save_session()

	if event is InputEventMouseButton:
		# Зум в точку курсора
		if event.button_index == MOUSE_BUTTON_WHEEL_UP or event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			var mouse_pos = get_viewport().get_mouse_position()
			var before_zoom_pos = (mouse_pos - map_offset) / zoom_level
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_level = clamp(zoom_level * 1.1, min_zoom, max_zoom)
			else:
				zoom_level = clamp(zoom_level * 0.9, min_zoom, max_zoom)
			map_offset = mouse_pos - before_zoom_pos * zoom_level

	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			map_offset += event.relative
