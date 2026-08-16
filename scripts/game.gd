extends Node2D
class_name Game

var player: Player
var enemies: Array = []
var boss = null
var projectiles: Array = []
var vfx: Array = []
var camera_x: float = 0.0
var shake_mag: float = 0.0
var shake_x: float = 0.0
var shake_y: float = 0.0
var hitstop: int = 0
var tick: int = 0
var diff_name: String = "Standard"
var diff: Dictionary = {}
var state: String = "play"
var elapsed: float = 0.0
var waves: Array = []
var wave_index: int = -1
var wave_cooldown: int = 60
var boss_spawned: bool = false
var revives_left: int = 0
var slow_tick: int = 0
var slow_factor: float = 1.0
var perfect_dodge_tick: int = -999
var perfect_dodge_active: bool = false
var paused: bool = false
var next_id: int = 1
var arabic: bool = false

func _ready():
	randomize()
	arabic = OS.get_locale_language() == "ar"
	diff = CombatConfig.difficulty(diff_name)
	revives_left = int(diff["revives"])
	player = Player.new()
	player.id = 0
	waves = [
		[{"spec": husk_spec(), "x": 820.0}, {"spec": husk_spec(), "x": 1160.0}],
		[{"spec": husk_spec(), "x": 800.0}, {"spec": raker_spec(), "x": 1220.0}]
	]

func husk_spec() -> Dictionary:
	return {"type": "husk", "hp": 55.0, "posture": 55.0, "def": 20.0, "combo": 1, "speed": 1.7, "range": 120.0, "windup": 42, "active": 10, "recovery": 40, "damage": 14.0, "posture": 55.0, "reach": 120.0, "cooldown": 70}

func raker_spec() -> Dictionary:
	return {"type": "raker", "hp": 42.0, "posture": 42.0, "def": 15.0, "combo": 3, "speed": 3.0, "range": 120.0, "windup": 22, "active": 8, "recovery": 16, "damage": 8.0, "posture": 42.0, "reach": 120.0, "cooldown": 46}

func make_enemy(spec: Dictionary, x: float):
	var e = Enemy.new(spec, x, next_id)
	next_id += 1
	enemies.append(e)

func make_boss():
	boss = Boss.new()
	boss.x = 1480.0

func _physics_process(delta):
	if InputManager.take_pause():
		paused = !paused
	if paused:
		queue_redraw()
		return
	if state == "win" or state == "lose":
		update_vfx()
		queue_redraw()
		return
	if hitstop > 0:
		hitstop -= 1
		queue_redraw()
		return
	tick += 1
	elapsed += delta
	if slow_tick > 0:
		slow_tick -= 1
	if slow_tick <= 0:
		slow_factor = 1.0
	perfect_dodge_active = (tick - perfect_dodge_tick) <= 40
	player.step(self)
	var slow_skip = (slow_tick > 0 and (tick & 1) == 1)
	if not slow_skip:
		for e in enemies:
			e.step(self)
		if boss != null:
			boss.step(self)
	for p in projectiles:
		p.step(self)
	collisions()
	finisher_check()
	camera_follow()
	wave_management()
	update_vfx()
	enemies = enemies.filter(func(e): return e.alive)
	queue_redraw()

func rects_overlap(a: Rect2, b: Rect2) -> bool:
	return a.position.x < b.position.x + b.size.x and a.position.x + a.size.x > b.position.x and a.position.y < b.position.y + b.size.y and a.position.y + a.size.y > b.position.y

func collisions():
	var hb = player.active_hitbox()
	if hb.size.x > 0.0:
		var base = 16.0 if player.state == "crosswind" else player.current_step().damage
		var crit = randf() < 0.2
		var crit_s = 1.6 if crit else 1.0
		var pdmg = 18.0 if player.state == "crosswind" else player.current_step().posture
		if player.measured_breath % 3 == 0 and player.attack_index > 0:
			pdmg *= 1.4
		for e in enemies:
			if e.alive and not (e.id in player.hit_set) and rects_overlap(hb, e.hurtbox()):
				var final = CombatConfig.compute_damage(base, 1.0, 1.0, crit_s, e.def, 1.0)
				e.take_hit(self, final, pdmg)
				player.hit_set.append(e.id)
				player.resolve = min(player.max_resolve, player.resolve + final * 0.12)
				do_hitstop(5 if crit else 3)
				spawn_vfx({"type": "spark", "x": e.x, "y": CombatConfig.FLOOR_Y - 80.0, "life": 10, "color": CombatConfig.HUNTER})
		if boss != null and boss.alive and not (boss.id in player.hit_set) and rects_overlap(hb, boss_hurtbox()):
			var final = CombatConfig.compute_damage(base, 1.0, 1.0, crit_s, boss.def, 1.0)
			boss.take_hit(self, final, pdmg)
			player.hit_set.append(boss.id)
			player.resolve = min(player.max_resolve, player.resolve + final * 0.12)
			do_hitstop(5 if crit else 3)
			spawn_vfx({"type": "spark", "x": boss.x, "y": CombatConfig.FLOOR_Y - 110.0, "life": 10, "color": CombatConfig.HUNTER})
	for e in enemies:
		if e.alive and e.state == "active" and not e.hit_player:
			var ehb = e.active_hitbox()
			if ehb.size.x > 0.0 and rects_overlap(ehb, player.hurtbox()):
				var dmg = e.swing_damage() * diff["edmg"]
				var res = player.take_hit(self, dmg, e.spec["posture"] * 0.35, e.x)
				if res != "iframe":
					e.hit_player = true
	if boss != null and boss.alive and boss.state == "active" and not boss.hit_player:
		var bhb = boss.active_hitbox()
		if bhb.size.x > 0.0 and rects_overlap(bhb, player.hurtbox()):
			var dmg = boss.swing_damage() * diff["edmg"]
			var res = player.take_hit(self, dmg, 14.0, boss.x)
			if res != "iframe":
				boss.hit_player = true
	for i in range(projectiles.size() - 1, -1, -1):
		var p = projectiles[i]
		var pr = Rect2(p.x - p.r, p.y - p.r, p.r * 2.0, p.r * 2.0)
		if p.owner_is_player:
			var consumed = false
			for e in enemies:
				if e.alive and abs(e.x - p.x) < p.r + 34.0 and abs(CombatConfig.FLOOR_Y - 90.0 - p.y) < 120.0:
					if p.pin:
						e.pinned = max(e.pinned, 120)
						e.take_hit(self, p.damage, p.posture * 0.4)
					else:
						e.take_hit(self, p.damage, p.posture)
					consumed = true
					break
			if not consumed and boss != null and boss.alive and abs(boss.x - p.x) < p.r + 54.0:
				boss.take_hit(self, p.damage, p.posture)
				consumed = true
			if consumed:
				projectiles.remove_at(i)
		else:
			if rects_overlap(pr, player.hurtbox()):
				var can_reflect = false
				if player.state == "attack" and player.attack_phase == "active" and rects_overlap(player.active_hitbox(), pr):
					can_reflect = true
				elif player.guarding and (tick - player.guard_press_tick) <= diff["parry"] and player.facing_towards(p.x):
					can_reflect = true
				if can_reflect:
					p.reflect(self)
				else:
					var res = player.take_hit(self, p.damage * diff["edmg"], p.posture, p.x)
					if res != "iframe":
						projectiles.remove_at(i)
			elif p.x < -120.0 or p.x > CombatConfig.ARENA_W + 120.0 or p.life <= 0:
				projectiles.remove_at(i)

func finisher_check():
	if player.state in ["idle", "move"]:
		for e in enemies:
			if e.alive and e.staggered and abs(e.x - player.x) < 145.0 and InputManager.attack_held:
				e.health = 0.0
				e.alive = false
				player.invuln_until = tick + 24
				player.resolve = min(player.max_resolve, player.resolve + 10.0)
				do_hitstop(6)
				spawn_vfx({"type": "parry", "x": e.x, "y": CombatConfig.FLOOR_Y - 80.0, "life": 18, "color": CombatConfig.PARRY})
				spawn_vfx({"type": "spark", "x": e.x, "y": CombatConfig.FLOOR_Y - 80.0, "life": 12, "color": CombatConfig.HUNTER})
				break

func boss_hurtbox() -> Rect2:
	if boss == null:
		return Rect2(0, 0, 0, 0)
	return Rect2(boss.x - 36.0, CombatConfig.FLOOR_Y - 200.0, 72.0, 200.0)

func camera_follow():
	var target = clamp(player.x - CombatConfig.VW * 0.42 + float(player.facing) * 60.0, 0.0, CombatConfig.ARENA_W - CombatConfig.VW)
	camera_x = camera_x + (target - camera_x) * 0.12

func wave_management():
	if enemies.is_empty():
		if not boss_spawned:
			if wave_index < waves.size() - 1:
				wave_cooldown -= 1
				if wave_cooldown <= 0:
					spawn_next_wave()
					wave_cooldown = 90
			else:
				make_boss()
				boss_spawned = true
		elif boss != null and not boss.alive:
			state = "win"
			SaveManager.record_clear(elapsed, rank())

func spawn_next_wave():
	wave_index += 1
	if wave_index < waves.size():
		for spec in waves[wave_index]:
			make_enemy(spec["spec"], spec["x"])
	wave_cooldown = 90

func rank() -> String:
	if elapsed < 55.0 and revives_left == int(diff["revives"]):
		return "S"
	if elapsed < 90.0:
		return "A"
	if elapsed < 140.0:
		return "B"
	return "C"

func update_vfx():
	for i in range(vfx.size() - 1, -1, -1):
		vfx[i]["life"] -= 1
		if vfx[i]["life"] <= 0:
			vfx.remove_at(i)

func spawn_vfx(d: Dictionary):
	d["maxlife"] = d["life"]
	vfx.append(d)

func do_hitstop(t: int):
	hitstop = max(hitstop, t)

func shake(mag: float):
	shake_mag = max(shake_mag, mag)

func slow_enemies(duration: int, factor: float):
	slow_tick = duration
	slow_factor = factor

func perfect_dodge_mark():
	perfect_dodge_tick = tick

func imminent_attack(p) -> bool:
	for e in enemies:
		if e.alive and e.state == "windup" and (e.spec["windup"] - e.state_tick) <= 8 and abs(e.x - p.x) < 380.0:
			return true
	if boss != null and boss.alive and boss.state == "windup" and (int(boss.cur.get("windup", 1)) - boss.state_tick) <= 8:
		return true
	return false

func player_ult_hit(p):
	var target = null
	var best = 999999.0
	for e in enemies:
		if e.alive:
			var d = abs(e.x - p.x)
			if d < best and (e.x - p.x) * float(p.facing) > -40.0:
				best = d
				target = e
	if boss != null and boss.alive and abs(boss.x - p.x) < 620.0 and (boss.x - p.x) * float(p.facing) > -40.0:
		target = boss
	if target != null:
		target.take_hit(self, 26.0, 20.0)
		spawn_vfx({"type": "spark", "x": target.x, "y": CombatConfig.FLOOR_Y - 90.0, "life": 10, "color": CombatConfig.PARRY})
		p.resolve = min(p.max_resolve, p.resolve + 2.0)

func on_player_dead():
	if revives_left > 0:
		revives_left -= 1
		player.alive = true
		player.health = player.max_health
		player.guard_meter = player.max_guard
		player.state = "idle"
		player.attack_index = -1
		player.x = 220.0
		player.invuln_until = tick + 60
		for e in enemies:
			e.staggered = false
			e.posture = e.max_posture
		if boss != null:
			boss.staggered = false
			boss.posture = boss.max_posture
	else:
		state = "lose"

func toggle_pause():
	if state == "play":
		paused = !paused

func _draw():
	draw_background()
	var ox = -camera_x + shake_x
	var oy = shake_y
	draw_set_transform(Vector2(ox, oy), 0.0, Vector2(1.0, 1.0))
	for e in enemies:
		if e.alive:
			e.draw(self)
	if boss != null and boss.alive:
		boss.draw(self)
	for p in projectiles:
		draw_projectile(p)
	for v in vfx:
		draw_vfx(v)
	player.draw(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 1.0))
	shake_mag *= 0.85
	if shake_mag < 0.2:
		shake_mag = 0.0
	shake_x = rand_range(-shake_mag, shake_mag)
	shake_y = rand_range(-shake_mag * 0.6, shake_mag * 0.6)

func draw_background():
	var top = Color(0.07, 0.07, 0.13)
	var hor = Color(0.34, 0.22, 0.27)
	var bands = 26
	for i in range(bands):
		var t = float(i) / float(bands)
		var c = top.lerp(hor, t)
		draw_rect(Rect2(0.0, float(i) * CombatConfig.FLOOR_Y / float(bands), CombatConfig.VW, CombatConfig.FLOOR_Y / float(bands) + 1.0), c)
	var px = -camera_x * 0.3
	for m in range(-1, 6):
		var mx = float(m) * 360.0 + fmod(px, 360.0)
		var pts = PackedVector2Array()
		pts.append(Vector2(mx, CombatConfig.FLOOR_Y))
		pts.append(Vector2(mx + 120.0, CombatConfig.FLOOR_Y - 150.0))
		pts.append(Vector2(mx + 240.0, CombatConfig.FLOOR_Y))
		draw_colored_polygon(pts, Color(0.12, 0.12, 0.18))
	draw_rect(Rect2(0.0, CombatConfig.FLOOR_Y, CombatConfig.VW, CombatConfig.VH - CombatConfig.FLOOR_Y), Color(0.10, 0.09, 0.12))
	draw_line(Vector2(0.0, CombatConfig.FLOOR_Y), Vector2(CombatConfig.VW, CombatConfig.FLOOR_Y), Color(0.3, 0.25, 0.22), 2.0)

func draw_projectile(p):
	var c = p.color
	draw_circle(Vector2(p.x, p.y), p.r, c)
	draw_circle(Vector2(p.x, p.y), p.r * 0.5, Color(1.0, 1.0, 1.0, 0.6))
	if abs(p.vx) > 0.1:
		draw_line(Vector2(p.x - sign(p.vx) * p.r * 2.0, p.y), Vector2(p.x, p.y), Color(c.r, c.g, c.b, 0.35), p.r * 0.8)

func draw_vfx(v):
	var life = float(v["life"])
	var ml = float(v["maxlife"])
	var t = 1.0 - life / ml
	var col = v["color"]
	match v["type"]:
		"parry":
			draw_arc(Vector2(v["x"], v["y"]), 20.0 + t * 60.0, 0.0, TAU, 24, Color(col.r, col.g, col.b, 1.0 - t), 4.0)
		"spark":
			draw_arc(Vector2(v["x"], v["y"]), 10.0 + t * 30.0, 0.0, TAU, 18, Color(col.r, col.g, col.b, 1.0 - t), 3.0)
		"dodge", "dash":
			draw_line(Vector2(v["x"] - 40.0, v["y"] + t * 30.0), Vector2(v["x"] + 40.0, v["y"] + t * 30.0), Color(col.r, col.g, col.b, 0.6 * (1.0 - t)), 6.0)
		"cast":
			draw_circle(Vector2(v["x"], v["y"]), 8.0 + t * 22.0, Color(col.r, col.g, col.b, 0.7 * (1.0 - t)))
		"ult":
			draw_arc(Vector2(v["x"], v["y"]), 30.0 + t * 120.0, 0.0, TAU, 32, Color(col.r, col.g, col.b, 0.8 * (1.0 - t)), 6.0)
