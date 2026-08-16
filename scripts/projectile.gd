extends RefCounted
class_name Projectile

var x: float
var y: float
var vx: float
var vy: float
var r: float
var damage: float
var posture: float
var owner_is_player: bool
var color: Color
var life: int = 600
var reflected: bool = false
var pin: bool = false
var spin: float = 0.0

func _init(px: float, py: float, pvx: float, pvy: float, pr: float, pdmg: float, ppos: float, pplayer: bool, pcolor: Color):
	x = px
	y = py
	vx = pvx
	vy = pvy
	r = pr
	damage = pdmg
	posture = ppos
	owner_is_player = pplayer
	color = pcolor

func step(world):
	x += vx
	y += vy
	life -= 1
	spin += 0.3

func reflect(world):
	vx = -vx
	owner_is_player = true
	reflected = true
	color = CombatConfig.HUNTER
