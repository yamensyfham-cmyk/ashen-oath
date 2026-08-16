extends Node2D

func _ready():
	randomize()
	var game = Game.new()
	game.name = "Game"
	add_child(game)
	var hud = preload("res://scripts/hud.gd").new()
	hud.name = "HUD"
	hud.game = game
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hud)
	var touch = preload("res://scripts/touch_ui.gd").new()
	touch.name = "Touch"
	touch.game = game
	touch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(touch)

func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var touch = get_node_or_null("Touch")
		if touch != null:
			touch.handle_event(event)
