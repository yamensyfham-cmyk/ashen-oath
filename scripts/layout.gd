extends RefCounted
class_name Layout

const MOVE_END_X: float = 512.0
const MOVE_Y0: float = 252.0

const BTN_ATTACK: Vector2 = Vector2(1040.0, 575.0)
const BTN_ATTACK_R: float = 72.0
const BTN_GUARD: Vector2 = Vector2(1150.0, 645.0)
const BTN_GUARD_R: float = 58.0
const BTN_SKILL_A: Vector2 = Vector2(925.0, 470.0)
const BTN_SKILL_A_R: float = 50.0
const BTN_SKILL_B: Vector2 = Vector2(1150.0, 470.0)
const BTN_SKILL_B_R: float = 50.0
const BTN_ULT: Vector2 = Vector2(1195.0, 250.0)
const BTN_ULT_R: float = 56.0
const BTN_PAUSE: Vector2 = Vector2(1235.0, 40.0)
const BTN_PAUSE_R: float = 26.0

const RETRY_RECT: Rect2 = Rect2(380.0, 430.0, 220.0, 72.0)
const HOME_RECT: Rect2 = Rect2(680.0, 430.0, 220.0, 72.0)

static func dist(a: Vector2, b: Vector2) -> float:
	return a.distance_to(b)
