extends Control

var game: Game

func _process(_delta):
	queue_redraw()

func _draw():
	if game == null:
		return
	var p = game.player
	draw_health(p)
	draw_resolve(p)
	draw_skills(p)
	draw_dodge(p)
	if game.boss != null and game.boss.alive:
		draw_boss(game.boss)
	if game.elapsed < 9.0 and game.state == "play":
		draw_tutorial()
	if game.state == "win" or game.state == "lose":
		draw_result()
	if game.paused:
		draw_rect(Rect2(0.0, 0.0, CombatConfig.VW, CombatConfig.VH), Color(0.0, 0.0, 0.0, 0.5))
		var f = ThemeDB.fallback_font
		draw_string(f, Vector2(560.0, 360.0), "PAUSED", 0, -1, 40, Color(0.9, 0.9, 0.95))

func draw_health(p):
	draw_rect(Rect2(24.0, 24.0, 96.0, 96.0), Color(0.1, 0.1, 0.14))
	draw_rect(Rect2(24.0, 24.0, 96.0, 96.0), Color(0.0, 0.0, 0.0, 0.0), false, 2.0)
	var f = ThemeDB.fallback_font
	draw_string(f, Vector2(34.0, 70.0), "REN", 0, -1, 22, CombatConfig.HUNTER)
	var hw = 360.0
	draw_rect(Rect2(130.0, 34.0, hw, 22.0), Color(0.08, 0.08, 0.1))
	draw_rect(Rect2(130.0, 34.0, hw * clamp(p.health / p.max_health, 0.0, 1.0), 22.0), Color(0.86, 0.32, 0.32))
	draw_rect(Rect2(130.0, 62.0, hw, 12.0), Color(0.1, 0.12, 0.16))
	draw_rect(Rect2(130.0, 62.0, hw * clamp(p.guard_meter / p.max_guard, 0.0, 1.0), 12.0), CombatConfig.GUARD)

func draw_resolve(p):
	var ready = p.resolve >= p.max_resolve
	var col = CombatConfig.PARRY if ready else CombatConfig.DIM
	draw_arc(Layout.BTN_ULT, Layout.BTN_ULT_R + 10.0, -PI/2.0, -PI/2.0 + TAU * (p.resolve / p.max_resolve), 36, col, 6.0)

func draw_skills(p):
	cd_ring(Layout.BTN_SKILL_A, Layout.BTN_SKILL_A_R, p.skill_a_cd, 540.0, CombatConfig.HUNTER)
	cd_ring(Layout.BTN_SKILL_B, Layout.BTN_SKILL_B_R, p.skill_b_cd, 600.0, CombatConfig.HUNTER)

func cd_ring(center: Vector2, r: float, cd: float, maxcd: float, col: Color):
	var frac = 1.0 - clamp(cd / maxcd, 0.0, 1.0)
	draw_arc(center, r + 6.0, -PI/2.0, -PI/2.0 + TAU * frac, 30, col, 4.0)

func draw_dodge(p):
	for i in range(2):
		var filled = i < p.dodge_charges
		var c = CombatConfig.HUNTER if filled else Color(0.25, 0.25, 0.3)
		draw_circle(Vector2(60.0 + float(i) * 34.0, 690.0), 12.0, c)

func draw_boss(b):
	var f = ThemeDB.fallback_font
	var cx = 640.0
	draw_string(f, Vector2(cx - 150.0, 22.0), "THE MILL BRIDE", 0, -1, 22, CombatConfig.BOSS)
	var bw = 460.0
	var bx = cx - bw / 2.0
	draw_rect(Rect2(bx, 34.0, bw, 16.0), Color(0.1, 0.08, 0.1))
	draw_rect(Rect2(bx, 34.0, bw * clamp(b.health / b.max_health, 0.0, 1.0), 16.0), CombatConfig.BOSS)
	draw_rect(Rect2(bx, 54.0, bw, 8.0), Color(0.12, 0.12, 0.14))
	draw_rect(Rect2(bx, 54.0, bw * clamp(b.posture / b.max_posture, 0.0, 1.0), 8.0), CombatConfig.PARRY)

func draw_tutorial():
	var f = ThemeDB.fallback_font
	var lines = ["Drag left side to move", "Tap ATK to strike", "Hold GRD, tap on cue to parry", "Swipe right to dash", "Break posture, then strike to finish"]
	for i in range(lines.size()):
		draw_string(f, Vector2(360.0, 250.0 + float(i) * 30.0), lines[i], 0, -1, 20, Color(0.9, 0.9, 0.95, 0.9))

func draw_result():
	draw_rect(Rect2(0.0, 0.0, CombatConfig.VW, CombatConfig.VH), Color(0.0, 0.0, 0.0, 0.66))
	var f = ThemeDB.fallback_font
	var win = game.state == "win"
	var title = "HOLLOW CLOSED" if win else "OATH BROKEN"
	var col = CombatConfig.PARRY if win else CombatConfig.TELE
	draw_string(f, Vector2(440.0, 300.0), title, 0, -1, 40, col)
	draw_string(f, Vector2(470.0, 350.0), "Time %.1fs   Rank %s" % [game.elapsed, game.rank()], 0, -1, 24, Color(0.9, 0.9, 0.95))
	draw_rect(Layout.RETRY_RECT, Color(0.15, 0.15, 0.2))
	draw_rect(Layout.HOME_RECT, Color(0.15, 0.15, 0.2))
	draw_string(f, Vector2(Layout.RETRY_RECT.position.x + 70.0, Layout.RETRY_RECT.position.y + 46.0), "RETRY", 0, -1, 26, CombatConfig.HUNTER)
	draw_string(f, Vector2(Layout.HOME_RECT.position.x + 78.0, Layout.HOME_RECT.position.y + 46.0), "HOME", 0, -1, 26, CombatConfig.HUNTER)
