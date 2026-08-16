extends Node
class_name CombatConfig

const VW = 1280.0
const VH = 720.0
const FLOOR_Y = 560.0
const ARENA_W = 1920.0

const INK = Color(0.055, 0.055, 0.075)
const PAPER = Color(0.91, 0.886, 0.831)
const HUNTER = Color(0.91, 0.631, 0.294)
const WRAITH = Color(0.435, 0.525, 0.659)
const BOSS = Color(0.776, 0.294, 0.294)
const TELE = Color(1.0, 0.353, 0.302)
const PARRY = Color(1.0, 0.839, 0.42)
const GUARD = Color(0.353, 0.663, 0.902)
const DIM = Color(0.25, 0.25, 0.3)

class AttackStep:
	var startup: int
	var active: int
	var recovery: int
	var damage: float
	var posture: float
	var link: int
	var reach: float
	func _init(s: int, a: int, r: int, d: float, p: float, l: int, rc: float):
		startup = s
		active = a
		recovery = r
		damage = d
		posture = p
		link = l
		reach = rc

func t(ms: int) -> int:
	return roundi(float(ms) * 60.0 / 1000.0)

func ren_string() -> Array:
	return [
		AttackStep.new(t(90), t(80), t(150), 9.0, 10.0, t(120), 130.0),
		AttackStep.new(t(110), t(90), t(170), 10.0, 12.0, t(130), 130.0),
		AttackStep.new(t(150), t(100), t(210), 12.0, 15.0, t(150), 140.0),
		AttackStep.new(t(230), t(120), t(330), 18.0, 40.0, 0, 150.0)
	]

func ren_heavy() -> AttackStep:
	return AttackStep.new(t(200), t(140), t(360), 26.0, 32.0, 0, 160.0)

func difficulty(name: String) -> Dictionary:
	match name:
		"story":
			return {"parry": t(150), "iframe_start": 4, "iframe_end": 17, "proj": 0.85, "edmg": 0.85, "revives": 2, "label": "Story"}
		"veteran":
			return {"parry": t(100), "iframe_start": 6, "iframe_end": 12, "proj": 1.15, "edmg": 1.15, "revives": 0, "label": "Veteran"}
		_:
			return {"parry": t(120), "iframe_start": 5, "iframe_end": 13, "proj": 1.0, "edmg": 1.0, "revives": 0, "label": "Standard"}

func defense_reduction(def: float) -> float:
	return 100.0 / (100.0 + def)

func variance() -> float:
	return randf_range(0.97, 1.03)

func compute_damage(base: float, atk_scalar: float, skill_scalar: float, crit_scalar: float, def: float, diff_scalar: float) -> float:
	return base * atk_scalar * skill_scalar * crit_scalar * defense_reduction(def) * diff_scalar * variance()

func lerp_col(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, t)
