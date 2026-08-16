extends Node
class_name InputManager

var move: Vector2 = Vector2.ZERO
var guard_held: bool = false
var attack_held: bool = false
var events: Array = []

func push(ev: String) -> void:
	events.append(ev)

func consume() -> Array:
	var e = events
	events = []
	return e

func take_pause() -> bool:
	var found = false
	for i in range(events.size() - 1, -1, -1):
		if events[i] == "pause":
			events.remove_at(i)
			found = true
	return found

func clear_all() -> void:
	events = []
	move = Vector2.ZERO
	guard_held = false
	attack_held = false
