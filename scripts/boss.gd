extends RefCounted
class_name Boss

var id: int = 999
var x: float = 1500.0
var vx: float = 0.0
var facing: int = -1
var max_health: float = 1000.0
var health: float = 1000.0
var max_posture: float = 240.0
var posture: float = 240.0
var def: float = 30.0
var state: String = "idle"
var state_tick: int = 0
var move_timer: int = 80
var cur: Dictionary = {}
var phase: int = 1
var staggered: bool = false
var stagger_tick: int = 0
var posture_dmg_tick: int = -999
var hit_flash: int = 0
var alive: bool = true
var swing_id: int = 0
var hit_player: bool = false

func clamp_x(world):
	x = clamp(x, 200.0, CombatConfig.ARENA_W - 200.0)

func step(world):
	if not alive:
		return
	state_tick += 1
	if hit_flash > 0:
		hit_flash -= 1
	if not staggered and posture < max_posture and (world.tick - posture_dmg_tick) > 150:
		posture = min(max_posture, posture + 0.8)
	if health < max_health * 0.5:
		phase = 2
	if staggered:
		stagger_tick -= 1
		vx = 0.0
		if stagger_tick <= 0:
			staggered = false
			posture = max_posture * 0.5
			state = "idle"
			move_timer = 40
		return
	match state:
		"idle":
			var dx = world.player.x - x
			facing = 1 if dx >= 0 else -1
			if abs(dx) > 280:
				vx = sign(dx) * 3.0
				x += vx
				clamp_x(world)
			else:
				vx = 0.0
				move_timer -= 1
				if move_timer <= 0:
					choose_move(world)
		"windup":
			vx = 0.0
			if state_tick >= cur["windup"]:
				state = "active"
				state_tick = 0
				on_active_start(world)
				hit_player = false
		"active":
			vx = 0.0
			if state_tick >= cur["active"]:
				state = "recovery"
				state_tick = 0
		"recovery":
			vx = 0.0
			if state_tick >= cur["recovery"]:
				state = "idle"
				move_timer = 55 if phase == 1 else 32

func choose_move(world):
	var dx = world.player.x - x
	var r = randf()
	if abs(dx) > 360:
		if r < 0.5:
			set_move("sweep")
		else:
			set_move("volley")
	else:
		set_move("spin")

func set_move(name: String):
	var f = 1.0 if phase == 1 else 0.75
	cur = {"name": name}
	match name:
		"sweep":
			cur["windup"] = int(float(CombatConfig.t(700)) * f)
			cur["active"] = 10
			cur["recovery"] = 50
		"volley":
			cur["windup"] = int(float(CombatConfig.t(820)) * f)
			cur["active"] = 10
			cur["recovery"] = 50
		"spin":
			cur["windup"] = int(float(CombatConfig.t(600)) * f)
			cur["active"] = 14
			cur["recovery"] = 60
	state = "windup"
	state_tick = 0
	swing_id += 1

func on_active_start(world):
	if cur["name"] == "sweep":
		var p = Projectile.new(x + facing * 40.0, CombatConfig.FLOOR_Y - 84.0, facing * 9.0 * world.diff["proj"], 0.0, 20.0, 16.0, 12.0, false, CombatConfig.TELE)
		world.spawn_projectile(p)
	elif cur["name"] == "volley":
		for i in range(-1, 2):
			var ang = deg_to_rad(20.0 * float(i))
			var pvx = facing * 8.0 * world.diff["proj"] * cos(ang)
			var pvy = -sin(ang) * 6.0
			var p = Projectile.new(x + facing * 30.0, CombatConfig.FLOOR_Y - 100.0, pvx, pvy, 16.0, 13.0, 10.0, false, CombatConfig.TELE)
			world.spawn_projectile(p)

func active_hitbox() -> Rect2:
	if state == "active" and cur.get("name", "") == "spin":
		var reach = 160.0
		var x0 = x if facing > 0 else x - reach
		return Rect2(x0, CombatConfig.FLOOR_Y - 160.0, reach, 130.0)
	return Rect2(0, 0, 0, 0)

func swing_damage() -> float:
	var d = 18.0
	if phase == 2:
		d *= 1.15
	return d

func take_hit(world, dmg: float, posture_dmg: float):
	health -= dmg
	posture -= posture_dmg
	posture_dmg_tick = world.tick
	hit_flash = 6
	if posture <= 0.0 and not staggered:
		staggered = true
		stagger_tick = 180
		state = "idle"
	if health <= 0.0:
		alive = false

func draw(ci):
	var base_y = CombatConfig.FLOOR_Y
	var col = CombatConfig.BOSS
	if hit_flash > 0:
		col = Color(1.0, 1.0, 1.0)
	ci.draw_circle(Vector2(x, base_y + 10.0), 46.0, Color(0.0, 0.0, 0.0, 0.25))
	var bx = x
	ci.draw_colored_polygon(poly(bx, base_y, facing, col), col)
	ci.draw_circle(Vector2(bx, base_y - 200.0), 26.0, col)
	var wcol = Color(0.85, 0.7, 0.7)
	var wa = facing * 0.5
	if state == "active" and cur.get("name", "") == "spin":
		wa = facing * 1.3
	ci.draw_line(Vector2(bx + facing * 24.0, base_y - 150.0), Vector2(bx + facing * 24.0 + cos(wa) * 110.0 * facing, base_y - 150.0 - sin(wa) * 110.0), wcol, 9.0)
	if state == "windup":
		var a = float(state_tick) / float(max(1, cur.get("windup", 1)))
		ci.draw_arc(Vector2(bx, base_y - 110.0), 90.0, -1.2 - a, 1.2 + a, 22, CombatConfig.TELE, 6.0)
		ci.draw_arc(Vector2(bx, base_y - 110.0), 70.0, -1.0, 1.0, 16, CombatConfig.PARRY, 4.0)
	if staggered:
		ci.draw_arc(Vector2(bx, base_y - 110.0), 96.0, -2.4, 2.4, 26, CombatConfig.PARRY, 5.0)

func poly(bx: float, base_y: float, fac: int, col: Color) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.append(Vector2(bx - 30.0, base_y))
	pts.append(Vector2(bx - 22.0, base_y - 120.0))
	pts.append(Vector2(bx - 30.0, base_y - 190.0))
	pts.append(Vector2(bx + 30.0, base_y - 190.0))
	pts.append(Vector2(bx + 22.0, base_y - 120.0))
	pts.append(Vector2(bx + 30.0, base_y))
	return pts
