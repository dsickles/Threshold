extends Node

# HubManager.gd
# Manages the visual state of the House based on GameState.

func _ready():
	# Connect to GameState signals
	# GameState.connect("minigame_completed", _on_minigame_completed)
	pass

func update_house_visuals():
	var flags = GameState.state.narrative_flags
	
	# Example Logic (Placeholder)
	# if flags.miscarriage_occurred:
	# 	_set_prop_visibility("Crib", false)
	# 	_set_prop_visibility("PackedBoxes", true)
	pass

func _on_minigame_completed(minigame_name, result):
	update_house_visuals()
