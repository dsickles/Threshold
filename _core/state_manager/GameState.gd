extends Node

# GameState.gd
# Tracks the global narrative state and progression.

signal act_changed(new_act)
signal minigame_completed(minigame_name, result_data)

var state = {
	"current_act": 1,
	"minigames_completed": [],
	"narrative_flags": {
		"ivf_started": false,
		"miscarriage_occurred": false,
		"baby_born": false,
		"pregnant": false
	},
	"house_state": {
		"nursery_painted": false,
		"boxes_packed": false
	},
	"anxiety_level": 0.0 # 0.0 to 1.0
}

func _ready():
	print("GameState Initialized")

func complete_minigame(minigame_name: String, result_data: Dictionary):
	if not state.minigames_completed.has(minigame_name):
		state.minigames_completed.append(minigame_name)
	
	emit_signal("minigame_completed", minigame_name, result_data)
	_update_narrative_flags(minigame_name, result_data)
	_check_act_progression()

func _update_narrative_flags(minigame_name: String, result_data: Dictionary):
	match minigame_name:
		"The Partner":
			state.narrative_flags.pregnant = true
		"The Protector":
			state.narrative_flags.pregnant = false
			state.narrative_flags.miscarriage_occurred = true
		"The Novice":
			state.narrative_flags.ivf_started = true
			state.narrative_flags.pregnant = true # Successful IVF

func _check_act_progression():
	# Logic to advance acts based on completed minigames
	pass
