extends Node

const SAVE_PATH = "user://save.json"
var data: Dictionary = {}

func _ready():
	load_save()

func load_save():
	if FileAccess.file_exists(SAVE_PATH):
		var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if f:
			var txt = f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(txt)
			if parsed is Dictionary:
				data = parsed
	if data.is_empty():
		data = {"best_time": -1.0, "best_rank": "", "clears": 0, "settings": {}}

func save():
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		f.close()

func record_clear(time_sec: float, rank: String):
	if data.get("best_time", -1.0) < 0 or time_sec < float(data["best_time"]):
		data["best_time"] = time_sec
	data["best_rank"] = rank
	data["clears"] = int(data.get("clears", 0)) + 1
	save()
