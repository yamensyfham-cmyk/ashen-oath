extends Control

var game: Game
var pointers: Dictionary = {}

func _process(_delta):
	queue_redraw()

func handle_event(ev):
	if game == null:
		return
	if game.state == "win" or game.state == "lose":
		if ev is InputEventScreenTouch and ev.pressed:
			handle_result_tap(ev.position)
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			on_down(ev.index, ev.position)
		else:
			on_up(ev.index, ev.position)
	elif ev is InputEventScreenDrag:
		on_drag(ev.index, ev.position)

func on_down(index, pos: Vector2):
	if Layout.dist(pos, Layout.BTN_PAUSE) <= Layout.BTN_PAUSE_R:
		InputManager.push("pause")
		return
	var ctrl = "none"
	if pos.x <= Layout.MOVE_END_X and pos.y >= Layout.MOVE_Y0:
		ctrl = "move"
		pointers[index] = {"ctrl": "move", "ox": pos.x, "oy": pos.y}
		InputManager.move = Vector2.ZERO
	elif Layout.dist(pos, Layout.BTN_ATTACK) <= Layout.BTN_ATTACK_R:
		ctrl = "attack"
		InputManager.push("attack_down")
		InputManager.attack_held = true
	elif Layout.dist(pos, Layout.BTN_GUARD) <= Layout.BTN_GUARD_R:
		ctrl = "guard"
		InputManager.push("guard_down")
	elif Layout.dist(pos, Layout.BTN_SKILL_A) <= Layout.BTN_SKILL_A_R:
		ctrl = "skill_a"
		InputManager.push("skill_a")
	elif Layout.dist(pos, Layout.BTN_SKILL_B) <= Layout.BTN_SKILL_B_R:
		ctrl = "skill_b"
		InputManager.push("skill_b")
	elif Layout.dist(pos, Layout.BTN_ULT) <= Layout.BTN_ULT_R and game.player.resolve >= game.player.max_resolve:
		ctrl = "ult"
		InputManager.push("ult")
	elif pos.x > Layout.MOVE_END_X:
		ctrl = "dodge"
		pointers[index] = {"ctrl": "dodge", "sx": pos.x, "sy": pos.y, "dodged": false}
	if ctrl != "none" and not pointers.has(index):
		pointers[index] = {"ctrl": ctrl}

func on_drag(index, pos: Vector2):
	if not pointers.has(index):
		return
	var p = pointers[index]
	match p["ctrl"]:
		"move":
			var dx = pos.x - p["ox"]
			var mx = clamp(dx / 90.0, -1.0, 1.0)
			InputManager.move = Vector2(mx, 0.0)
		"dodge":
			var dx = pos.x - p["sx"]
			if not p["dodged"] and abs(dx) > 60.0:
				p["dodged"] = true
				if dx > 0.0:
					InputManager.push("dodge_right")
				else:
					InputManager.push("dodge_left")

func on_up(index, pos: Vector2):
	if not pointers.has(index):
		return
	var p = pointers[index]
	match p["ctrl"]:
		"move":
			InputManager.move = Vector2.ZERO
		"attack":
			InputManager.attack_held = false
			InputManager.push("attack_up")
		"guard":
			InputManager.push("guard_up")
	pointers.erase(index)

func handle_result_tap(pos: Vector2):
	if Layout.RETRY_RECT.has_point(pos) or Layout.HOME_RECT.has_point(pos):
		get_tree().reload_current_scene()

func _draw():
	draw_move()
	draw_button(Layout.BTN_ATTACK, Layout.BTN_ATTACK_R, "ATK", CombatConfig.HUNTER, InputManager.attack_held)
	draw_button(Layout.BTN_GUARD, Layout.BTN_GUARD_R, "GRD", CombatConfig.GUARD, InputManager.guard_held)
	draw_button(Layout.BTN_SKILL_A, Layout.BTN_SKILL_A_R, "A", CombatConfig.HUNTER, false)
	draw_button(Layout.BTN_SKILL_B, Layout.BTN_SKILL_B_R, "B", CombatConfig.HUNTER, false)
	var ult_ready = game != null and game.player.resolve >= game.player.max_resolve
	draw_button(Layout.BTN_ULT, Layout.BTN_ULT_R, "ULT", CombatConfig.PARRY, ult_ready, not ult_ready)
	draw_circle(Layout.BTN_PAUSE, Layout.BTN_PAUSE_R, Color(0.15, 0.15, 0.2, 0.7))
	var f = ThemeDB.fallback_font
	draw_string(f, Vector2(Layout.BTN_PAUSE.x - 6.0, Layout.BTN_PAUSE.y + 7.0), "II", 0, -1, 18, Color(0.9, 0.9, 0.95))
	draw_string(f, Vector2(520.0, 700.0), "SWIPE TO DASH", 0, -1, 16, Color(0.7, 0.7, 0.75, 0.5))

func draw_move():
	var base = Vector2(150.0, 620.0)
	draw_circle(base, 70.0, Color(0.15, 0.15, 0.2, 0.4))
	var knob = base + InputManager.move * 60.0
	draw_circle(knob, 42.0, Color(0.9, 0.9, 0.95, 0.5))

func draw_button(center: Vector2, r: float, label: String, col: Color, active: bool, dim: bool = false):
	var a = 0.35 if not active else 0.6
	if dim:
		a = 0.18
	draw_circle(center, r, Color(col.r, col.g, col.b, a))
	draw_arc(center, r, 0.0, TAU, 40, Color(col.r, col.g, col.b, 0.9), 3.0)
	var f = ThemeDB.fallback_font
	draw_string(f, Vector2(center.x - 16.0, center.y + 8.0), label, 0, -1, 22, Color(0.95, 0.95, 0.98, 0.95))
