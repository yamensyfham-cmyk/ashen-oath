extends RefCounted
class_name Player

var id: int = 0
var x: float = 220.0
var vx: float = 0.0
var facing: int = 1

var max_health: float = 100.0
var health: float = 100.0
var max_guard: float = 100.0
var guard_meter: float = 100.0
var resolve: float = 0.0
var max_resolve: float = 100.0

var state: String = "idle"
var state_tick: int = 0
var attack_index: int = -1
var attack_phase: String = "none"
var swing_id: int = 0
var hit_set: Array = []
var buffered_attack: bool = false
var atk_held_ticks: int = 0

var guarding: bool = false
var guard_press_tick: int = -999
var invuln_until: int = -999
var hitstun: int = 0
var guard_break: int = 0

var dodge_charges: int = 2
var dodge_restore_tick: int = -999
var perfect_dodge_cd: int = 0

var skill_a_cd: int = 0
var skill_b_cd: int = 0
var ult_tick: int = 0
var measured_breath: int = 0
var alive: bool = true

const SPEED: float = 4.7
const DODGE_SPEED: float = 9.5
const DODGE_DUR: int = 16
const HEAVY_THRESHOLD: int = 23

func current_step():
	if attack_index == 4:
		return CombatConfig.ren_heavy()
	return CombatConfig.ren_string()[attack_index]

func hurtbox() -> Rect2:
	return Rect2(x - 26.0, CombatConfig.FLOOR_Y - 86.0, 52.0, 86.0)

func facing_towards(from_x: float) -> bool:
	return sign(from_x - x) == float(facing) or abs(from_x - x) < 12.0

func step(world):
	if not alive:
		return
	state_tick += 1

	if skill_a_cd > 0: skill_a_cd -= 1
	if skill_b_cd > 0: skill_b_cd -= 1
	if perfect_dodge_cd > 0: perfect_dodge_cd -= 1
	if dodge_restore_tick != -999 and world.tick >= dodge_restore_tick and dodge_charges < 2:
		dodge_charges += 1
		if dodge_charges < 2:
			dodge_restore_tick = world.tick + 108
		else:
			dodge_restore_tick = -999
	if not guarding and guard_meter < max_guard:
		guard_meter = min(max_guard, guard_meter + 0.62)

	if guard_break > 0:
		guard_break -= 1
		if guard_break == 0:
			state = "idle"
			guarding = false
		return
	if hitstun > 0:
		hitstun -= 1
		vx = 0.0
		if hitstun == 0:
			state = "idle"
		return
	if ult_tick > 0:
		ult_tick -= 1
		state = "ultimate"
		if ult_tick % 9 == 0:
			world.player_ult_hit(self)
		if ult_tick == 0:
			resolve = 0.0
			state = "idle"
			attack_index = -1
		return

	var inp = InputManager
	var evs = inp.consume()
	for ev in evs:
		match ev:
			"attack_down": try_attack(world)
			"attack_up": atk_held_ticks = 0
			"guard_down":
				guarding = true
				guard_press_tick = world.tick
				inp.guard_held = true
			"guard_up":
				guarding = false
				inp.guard_held = false
			"skill_a": use_skill_a(world)
			"skill_b": use_skill_b(world)
			"ult": start_ult(world)
			"dodge_left": start_dodge(world, -1)
			"dodge_right": start_dodge(world, 1)

	guarding = inp.guard_held and state in ["idle", "move"]

	match state:
		"idle", "move":
			handle_move(world, inp)
			if inp.attack_held:
				atk_held_ticks += 1
				if atk_held_ticks >= HEAVY_THRESHOLD and state == "idle":
					start_heavy(world)
			else:
				atk_held_ticks = 0
		"attack":
			step_attack(world)
		"dodge":
			vx = facing * DODGE_SPEED
			x += vx
			clamp_x(world)
			if state_tick >= DODGE_DUR:
				state = "idle"
				attack_index = -1
		"crosswind":
			vx = facing * 13.0
			x += vx
			clamp_x(world)
			if state_tick >= 12:
				state = "idle"
				attack_index = -1
		"guard":
			vx = 0.0
			if not guarding:
				state = "idle"
		"hitstun", "dead":
			vx = 0.0

func clamp_x(world):
	x = clamp(x, 40.0, CombatConfig.ARENA_W - 40.0)

func handle_move(world, inp):
	var mx = inp.move.x
	if abs(mx) > 0.15:
		facing = 1 if mx > 0 else -1
		vx = mx * SPEED
		x += vx
		clamp_x(world)
		state = "move"
	else:
		vx = 0.0
		state = "idle"

func try_attack(world):
	if state in ["idle", "move"]:
		start_attack(world, 0)
	elif state == "attack" and attack_phase == "recovery":
		var cur = current_step()
		if state_tick >= cur.recovery - cur.link:
			start_attack(world, min(attack_index + 1, 3))
	elif state == "attack" and attack_phase in ["startup", "active"]:
		buffered_attack = true

func start_attack(world, idx: int):
	attack_index = idx
	attack_phase = "startup"
	state_tick = 0
	state = "attack"
	swing_id += 1
	hit_set = []
	atk_held_ticks = 0
	if idx > 0 and idx < 4:
		measured_breath += 1

func start_heavy(world):
	attack_index = 4
	attack_phase = "startup"
	state_tick = 0
	state = "attack"
	swing_id += 1
	hit_set = []
	atk_held_ticks = 0

func step_attack(world):
	var cur = current_step()
	if attack_phase == "startup":
		if state_tick >= cur.startup:
			attack_phase = "active"
			state_tick = 0
	elif attack_phase == "active":
		if state_tick >= cur.active:
			attack_phase = "recovery"
			state_tick = 0
	elif attack_phase == "recovery":
		if buffered_attack and state_tick >= cur.recovery - cur.link:
			buffered_attack = false
			try_attack(world)
		if state_tick >= cur.recovery:
			state = "idle"
			attack_index = -1
			attack_phase = "none"

func active_hitbox() -> Rect2:
	if state == "attack" and attack_phase == "active":
		var cur = current_step()
		var x0 = x if facing > 0 else x - cur.reach
		return Rect2(x0, CombatConfig.FLOOR_Y - 150.0, cur.reach, 120.0)
	if state == "crosswind":
		var x0 = x if facing > 0 else x - 90.0
		return Rect2(x0, CombatConfig.FLOOR_Y - 150.0, 90.0, 120.0)
	return Rect2(0, 0, 0, 0)

func start_dodge(world, dir: int):
	if state == "dead":
		return
	if dodge_charges <= 0:
		return
	var perfect = world.imminent_attack(self)
	dodge_charges -= 1
	if dodge_charges < 2:
		dodge_restore_tick = world.tick + 108
	dodge_charges = max(0, dodge_charges)
	state = "dodge"
	state_tick = 0
	facing = dir
	invuln_until = world.tick + world.diff["iframe_end"]
	world.spawn_vfx({"type": "dodge", "x": x, "y": CombatConfig.FLOOR_Y - 60.0, "life": 12, "color": CombatConfig.HUNTER})
	if perfect and perfect_dodge_cd <= 0:
		perfect_dodge_cd = 72
		world.slow_enemies(33, 0.45)
		world.perfect_dodge_mark()
		world.spawn_vfx({"type": "parry", "x": x, "y": CombatConfig.FLOOR_Y - 70.0, "life": 16, "color": CombatConfig.PARRY})

func use_skill_a(world):
	if skill_a_cd > 0 or state in ["dead", "ultimate"]:
		return
	skill_a_cd = 540
	var px = x + facing * 34.0
	var p = Projectile.new(px, CombatConfig.FLOOR_Y - 86.0, facing * 11.0, 0.0, 15.0, 14.0, 18.0, true, CombatConfig.HUNTER)
	p.pin = true
	world.spawn_projectile(p)
	world.spawn_vfx({"type": "cast", "x": px, "y": CombatConfig.FLOOR_Y - 86.0, "life": 10, "color": CombatConfig.HUNTER})

func use_skill_b(world):
	if skill_b_cd > 0 or state in ["dead", "ultimate"]:
		return
	skill_b_cd = 600
	state = "crosswind"
	state_tick = 0
	if world.perfect_dodge_active:
		dodge_charges = min(2, dodge_charges + 1)
	world.spawn_vfx({"type": "dash", "x": x, "y": CombatConfig.FLOOR_Y - 70.0, "life": 14, "color": CombatConfig.HUNTER})

func start_ult(world):
	if resolve < max_resolve or state in ["dead", "ultimate"]:
		return
	state = "ultimate"
	ult_tick = 150
	invuln_until = world.tick + 150
	world.spawn_vfx({"type": "ult", "x": x, "y": CombatConfig.FLOOR_Y - 70.0, "life": 40, "color": CombatConfig.PARRY})

func take_hit(world, dmg: float, posture_dmg: float, from_x: float) -> String:
	if not alive:
		return "none"
	if world.tick < invuln_until:
		return "iframe"
	if guarding and facing_towards(from_x):
		var parry_active = (world.tick - guard_press_tick) <= world.diff["parry"]
		if parry_active:
			resolve = min(max_resolve, resolve + 18.0)
			world.do_hitstop(4)
			world.spawn_vfx({"type": "parry", "x": x + facing * 30.0, "y": CombatConfig.FLOOR_Y - 70.0, "life": 18, "color": CombatConfig.PARRY})
			world.shake(4.0)
			return "parry"
		else:
			var blocked = dmg * 0.3
			health -= blocked
			guard_meter -= posture_dmg
			world.do_hitstop(2)
			if guard_meter <= 0.0:
				guard_meter = 0.0
				guard_break = 66
				guarding = false
				state = "guard"
			return "block"
	else:
		health -= dmg
		world.do_hitstop(3)
		hitstun = 22
		state = "hitstun"
		world.shake(6.0)
		if health <= 0.0:
			die(world)
		return "hit"

func die(world):
	alive = false
	state = "dead"
	world.on_player_dead()

func draw(ci):
	if not alive:
		ci.draw_circle(Vector2(x, CombatConfig.FLOOR_Y + 6.0), 30.0, Color(0.0, 0.0, 0.0, 0.25))
		return
	var base_y = CombatConfig.FLOOR_Y
	ci.draw_circle(Vector2(x, base_y + 6.0), 30.0, Color(0.0, 0.0, 0.0, 0.25))
	var lean = 0.0
	if state == "attack":
		lean = facing * 6.0
	var bx = x + lean
	var body = CombatConfig.PAPER
	var accent = CombatConfig.HUNTER
	ci.draw_colored_polygon(poly_human(bx, base_y, facing, body, accent), body)
	ci.draw_circle(Vector2(bx + facing * 4.0, base_y - 150.0), 16.0, body)
	var wcol = Color(0.82, 0.82, 0.88)
	var wa = -0.5
	if state == "attack" and attack_phase == "active":
		wa = facing * 0.9
	elif state == "attack":
		wa = facing * 0.2
	elif state == "guard" or guarding:
		wa = facing * 1.4
	elif state == "dodge":
		wa = facing * 1.9
	var hx = bx + facing * 18.0
	var hy = base_y - 96.0
	var tx = hx + cos(wa) * 64.0 * facing
	var ty = hy - sin(wa) * 64.0
	ci.draw_line(Vector2(hx, hy), Vector2(tx, ty), wcol, 7.0)
	if state == "attack" and attack_phase == "active":
		var cur = current_step()
		ci.draw_arc(Vector2(x, base_y - 80.0), cur.reach * 0.8, -1.1, 1.1, 14, CombatConfig.HUNTER, 6.0)
	if state == "guard" or guarding:
		var gp = guard_meter / max_guard
		var gc = CombatConfig.GUARD if gp > 0.25 else CombatConfig.TELE
		ci.draw_arc(Vector2(bx, base_y - 80.0), 56.0, -1.2, 1.2, 16, gc, 5.0)
	if state == "ultimate":
		ci.draw_arc(Vector2(bx, base_y - 80.0), 64.0, -2.4, 2.4, 22, CombatConfig.PARRY, 4.0)

func poly_human(bx: float, base_y: float, fac: int, body: Color, accent: Color) -> PackedVector2Array:
	var pts = PackedVector2Array()
	pts.append(Vector2(bx - 16.0, base_y))
	pts.append(Vector2(bx - 12.0, base_y - 70.0))
	pts.append(Vector2(bx - 20.0, base_y - 110.0))
	pts.append(Vector2(bx + 20.0, base_y - 110.0))
	pts.append(Vector2(bx + 12.0, base_y - 70.0))
	pts.append(Vector2(bx + 16.0, base_y))
	return pts
