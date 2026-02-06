extends CharacterBody2D

var speed = 450.0
@onready var grid = $"../Grid"

func _physics_process(delta):
	var direction = Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): direction.y -= 1
	if Input.is_physical_key_pressed(KEY_S): direction.y += 1
	if Input.is_physical_key_pressed(KEY_A): direction.x -= 1
	if Input.is_physical_key_pressed(KEY_D): direction.x += 1
	
	if direction != Vector2.ZERO:
		grid.move_character(direction.normalized() * speed * delta)

func _input(event):
	if event is InputEventKey and event.pressed:
		var distance = grid.get_distance_character_to_npc()
		# Если мы стоим рядом (ближе 120 пикселей в координатах карты)
		if distance < 120.0:
			if event.keycode == KEY_T:
				grid.give_money_to_npc()
			if event.keycode == KEY_Y:
				grid.take_money_from_npc()
