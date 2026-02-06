extends Node2D

const SAVE_PATH = "user://session_save.cfg"

# --- ДАННЫЕ МИРА ---
var balance_usd = 1000.0
var npc_balance_usd = 500.0 
var is_selected = false

# Позиция персонажа в координатах мира (без учёта зума и смещения камеры)
var character_world_pos: Vector2 = Vector2.ZERO

# --- РЕСУРСЫ ---
var house_scene = preload("res://home.tscn")

# Позиция второго персонажа (NPC)
var npc_position = Vector2(400, 300)

# --- ССЫЛКИ ---
@onready var character = $"../Graph"
@onready var player_sprite: Sprite2D = character.get_node_or_null("Player")
@onready var initial_home := get_node_or_null("../Home")
@onready var inventory_panel = get_node("../UI/InventoryPanel")

# --- НАВИГАЦИЯ ---
var map_offset = Vector2.ZERO
var zoom_level = 1.0
var min_zoom = 0.05
var max_zoom = 8.0

func _ready():
	# Стартовая позиция персонажа берётся из сцены,
	# а затем может быть переопределена сохранением.
	character_world_pos = character.position
	character.set_meta("world_pos", character_world_pos)
	character.add_to_group("world_objects")
	
	# Стартовый дом из сцены тоже считаем объектом мира
	if initial_home:
		initial_home.set_meta("world_pos", initial_home.position)
		initial_home.add_to_group("world_objects")
	
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

func move_character(delta_pos: Vector2) -> void:
	# Двигаем персонажа в координатах мира
	character_world_pos += delta_pos
	character.set_meta("world_pos", character_world_pos)

func get_distance_character_to_npc() -> float:
	# Расстояние в координатах мира
	return character_world_pos.distance_to(npc_position)

func save_session():
	var config = ConfigFile.new()
	config.set_value("session", "character_pos", character_world_pos)
	config.set_value("session", "map_offset", map_offset)
	config.set_value("session", "zoom_level", float(zoom_level)) 
	config.set_value("session", "balance", balance_usd)
	config.set_value("session", "npc_balance", npc_balance_usd)
	config.save(SAVE_PATH)

func load_session():
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		character_world_pos = config.get_value("session", "character_pos", character.position)
		character.set_meta("world_pos", character_world_pos)
		map_offset = config.get_value("session", "map_offset", Vector2.ZERO)
		zoom_level = config.get_value("session", "zoom_level", 1.0)
		balance_usd = config.get_value("session", "balance", 1000.0)
		npc_balance_usd = config.get_value("session", "npc_balance", 500.0)

func _process(_delta):
	queue_redraw()
	
	# Обновляем позицию и масштаб всех объектов мира (игрок и дома)
	for node in get_tree().get_nodes_in_group("world_objects"):
		if node.has_meta("world_pos"):
			var world_pos = node.get_meta("world_pos")
			node.position = world_pos * zoom_level + map_offset
			node.scale = Vector2(zoom_level, zoom_level)

	# Обновляем визуальное состояние выделения игрока
	_update_player_highlight()

func _update_player_highlight():
	if not player_sprite:
		return
	if is_selected:
		# Немного подсветим игрока (чуть светлее)
		player_sprite.self_modulate = Color(1, 1, 1)
	else:
		# Обычный вид
		player_sprite.self_modulate = Color(1, 1, 1)

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
	
	# 2. ВТОРОЙ ПЕРСОНАЖ (NPC)
	var npc_draw_pos = npc_position * zoom_level + map_offset
	draw_circle(npc_draw_pos, 20.0 * zoom_level, Color("ff4500")) 
	draw_string(ThemeDB.fallback_font, npc_draw_pos + Vector2(-30, -35)*zoom_level, "NPC Balance: $" + str(int(npc_balance_usd)), HORIZONTAL_ALIGNMENT_LEFT, -1, 14 * zoom_level)

	# 3. ИНТЕРФЕЙС (HUD) — сдвигаем в правый верхний угол, чтобы не мешал панели задач
	var hud_size = Vector2(260, 115)
	var hud_pos = Vector2(view_size.x - hud_size.x - 10, 10)
	
	draw_rect(Rect2(hud_pos, hud_size), Color(0, 0, 0, 0.8))
	draw_string(ThemeDB.fallback_font, hud_pos + Vector2(10, 25), "Your Balance: $" + str(int(balance_usd)), HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
	draw_string(ThemeDB.fallback_font, hud_pos + Vector2(10, 45), "[E] Build | [X] Remove", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(ThemeDB.fallback_font, hud_pos + Vector2(10, 65), "[T] Give $100 to NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.4, 0.8, 1))
	draw_string(ThemeDB.fallback_font, hud_pos + Vector2(10, 80), "[Y] Take $100 from NPC", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 0.8, 0.4))
	draw_string(ThemeDB.fallback_font, hud_pos + Vector2(10, 95), "[F5] Save Progress", HORIZONTAL_ALIGNMENT_LEFT, -1, 12)

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_E:
			if balance_usd >= 100.0:
				var house = house_scene.instantiate()
				house.set_meta("world_pos", character_world_pos)
				house.add_to_group("world_objects")
				add_child(house)
				balance_usd -= 100.0
		
		if event.keycode == KEY_F5:
			save_session()

	if event is InputEventMouseButton:
		# Клик по игроку — выделяем его и открываем/закрываем инвентарь
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_pos = event.position
			var click_radius = 40.0
			if mouse_pos.distance_to(character.position) <= click_radius:
				is_selected = !is_selected
				if is_selected:
					inventory_panel.open()
				else:
					inventory_panel.close()
			else:
				# Клик мимо игрока — снимаем выделение и закрываем инвентарь
				is_selected = false
				inventory_panel.close()

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
