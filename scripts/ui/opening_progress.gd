extends RefCounted
## This preference survives New Game; gameplay inventory stays session-only.
var storage_path: String
var completed := false

func _init(path: String = "user://opening_progress.cfg") -> void:
	storage_path = path
	var config := ConfigFile.new()
	if config.load(storage_path) == OK:
		var value: Variant = config.get_value("opening", "completed", false)
		completed = value is bool and value

func mark_completed() -> void:
	completed = true
	var config := ConfigFile.new()
	config.set_value("opening", "completed", true)
	var error := config.save(storage_path)
	if error != OK:
		push_warning("Could not save opening progress (%s): %s" % [error_string(error), storage_path])
