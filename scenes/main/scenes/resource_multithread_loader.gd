extends Node

signal resource_loaded(res)
signal resource_stage_loaded(current_stage, total_stages)

var thread: Thread = null


func _ready() -> void:
	thread = Thread.new()


func load_scene(path):
	thread.start(self, "_thread_load", path)

var stages_amount
func _thread_load(path):
	var ril = ResourceLoader.load_interactive(path)
	stages_amount = float(ril.get_stage_count())
	var res = null

	while true:
		emit_signal("resource_stage_loaded", ril.get_stage(), stages_amount)
		var SIMULATED_DELAY_MS = 20
		OS.delay_msec(SIMULATED_DELAY_MS) # TODO: not sure if this is the correct way
		var err = ril.poll()
		if err == ERR_FILE_EOF:
			res = ril.get_resource()
			break
		elif err != OK:
			print("There was an error loading")
			break
	call_deferred("_thread_done", res)


func _thread_done(resource):
	assert(resource)
	# Always wait for threads to finish, this is required on Windows.
	thread.wait_to_finish()
	emit_signal("resource_stage_loaded", stages_amount, stages_amount)
	# Instantiate new scene.
	emit_signal("resource_loaded", resource)


func _exit_tree() -> void:
	if thread and thread.is_active():
		thread.wait_to_finish()