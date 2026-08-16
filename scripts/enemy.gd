extends RefCounted
class_name Enemy

var id: int = 0
var type: String = "husk"
var x: float = 800.0
var vx: float = 0.0
var facing: int = -1
var max_health: float = 60.0
var health: float = 60.0
var max_posture: float = 60.0
var posture: float = 60.0
var def: float = 20.0
var state: String = "idle"
var state_tick: int = 0
var spec: Dictionary = {}
var combo_total: int = 1
var combo_index: int = 0
var staggered: bool = false
var stagger_tick: int = 0
var posture_dmg_tick: int = -999
var hit_flash: int = 0
var attack_cd: int = 40
var alive: bool = true
var pinned: int = 0
var hit_player: bool = false

func _init(p_spec: Dictionary, p_x: float, p_id: int):
	spec = p_spec
	type = p_spec["type"]
	max_health = p_spec["hp"]
	health = p_spec["hp"]
	max_posture = p_spec["posture"]
	posture = p_spec["posture"]
	def = p_spec["def"]
	combo_total = p_spec["combo"]
	x = p_x
	id = p_id

func clamp_x(world):
	x = clamp(x, 40.0, CombatConfig.ARENA_W - 40.0)

func step(world):
	if not alive:
		return
	state_tick += 1
	if hit_flash > 0:
		hit_flash -= 1
	if pinned > 0:
		pinned -= 1
		vx = 0.0
		return
	if not staggered and posture < max_posture and (world.tick - posture_dmg_tick) > 150:
		posture = min(max_posture, posture + 0.5)
	if staggered:
		stagger_tick -= 1
		vx = 0.0
		if stagger_tick <= 0:
			staggered = false
			posture = max_posture * 0.5
			state = "idle"
			attack_cd = 30
		return
	match state:
		"idle":
			var dx = world.player.x - x
			facing = 1 if dx >= 0 else -1
			if abs(dx) > spec["range"]:
				vx = sign(dx) * spec["speed"]
				x += vx
				clamp_x(world)
			else:
				vx = 0.0
				attack_cd -= 1
				if attack_cd <= 0 and abs(dx) <= spec["range"] + 14.0:
					state = "windup"
					state_tick = 0
					combo_index = 0
		"windup":
			vx = 0.0
			if state_tick >= spec["windup"]:
				state = "active"
				state_tick = 0
				hit_player = false
		"active":
			vx = 0.0
			if state_tick >= spec["active"]:
				state = "recovery"
				state_tick = 0
		"recovery":
			vx = 0.0
			if state_tick >= spec["recovery"]:
				combo_index += 1
				if combo_index < combo_total:
					state = "windup"
					state_tick = 0
				else:
					state = "idle"
					attack_cd = spec["cooldown"]

func active_hitbox() -> Rect2:
	if state == "active":
		var reach = spec["reach"]
		var x0 = x if facing > 0 else x - reach
		return Rect2(x0, CombatConfig.FLOOR_Y - 150.0, reach, 120.0)
	return Rect2(0, 0, 0, 0)

func swing_damage() -> float:
	var d = spec["damage"]
	if type == "raker" and combo_index == 2:
		d *= 1.15
	return d

func take_hit(world, dmg: float, posture_dmg: float):
	health -= dmg
	posture -= posture_dmg
	posture_dmg_tick = world.tick
	hit_flash = 6
	if posture <= 0.0 and not staggered:
		staggered = true
		stagger_tick = 96 if type != "elite" else 132
		state = "idle"
	if health <= 0.0:
		alive = false

func draw(ci):
	var base_y = CombatConfig.FLOOR_Y
	var col = CombatConfig.WRAITH if type == "husk" else Color(0.55, 0.62, 0.7)
	if hit_flash > 0:
		col = Color(1.0, 1.0, 1.0)
	ci.draw_circle(Vector2(x, base_y + 6.0), 30.0, Color(0.0, 0.0, 0.0, 0.25))
	var bx = x
	ci.draw_colored_polygon(poly(bx, base_y, facing, col), col)
	ci.draw_circle(Vector2(bx + facing * 4.0, base_y - 150.0), 15.0, col)
	var wcol = Color(0.7, 0.72, 0.78)
	var wa = facing * 0.4
	if state == "active":
		wa = facing * 1.1
	var hx = bx + facing * 18.0
	var hy = base_y - 92.0
	ci.draw_line(Vector2(hx, hy), Vector2(hx + cos(wa) * 58.0 * facing, hy - sin(wa) * 58.0), wcol, 6.0)
	if state == "windup":
		var a = float(state_tick) / float(spec["windup"])
		ci.draw_arc(Vector2(bx, base_y - 80.0), 52.0, -1.0 - a, 1.0 + a, 16, CombatConfig.TELE, 4.0)
	if staggered:
		ci.draw_arc(Vector2(bx, base_y - 80.0), 50.0, -2.0, 2.0, 18, CombatConfig.PARRY, 4.0)
	draw_bars(ci, base_y)

func draw_bars(ci, base_y):
	var w = 64.0
	var hp = clamp(health / max_health, 0.0, 1.0)
	ci.draw_rect(Rect2(x - w/2.0, base_y - 178.0, w, 7.0), Color(0.1, 0.1, 0.12))
	ci.draw_rect(Rect2(x - w/2.0, base_y - 178.0, w * hp, 7.0), Color(0.78, 0.3, 0.3))
	var pp = clamp(posture / max_posture, 0.0, 1.0)
	ci.draw_rect(Rect2(x - w/2.0, base_y - 168.0, w, 4.0), Color(0.12, 0.12, 0.14))
	ci.draw_rect(Rect2(x - w/2.0, base_y - 168.0, w * pp, 4.0), CombatConfig.PARRY)

func poly(bx: float, base_y: float, fac: int, col: Color) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.append(Vector2(bx - 18.0, base_y))
	pts.append(Vector2(bx - 14.0, base_y - 66.0))
	pts.append(Vector2(bx - 18.0, base_y - 104.0))
	pts.append(Vector2(bx + 18.0, base_y - 104.0))
	pts.append(Vector2(bx + 14.0, base_y - 66.0))
	pts.append(Vector2(bx + 18.0, base_y))
	return pts
