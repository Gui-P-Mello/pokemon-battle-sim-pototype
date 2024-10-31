extends Node

@export var initial_state: State

@export var pokemon: Pokemon

var current_state: State
var states: Dictionary = {}

func _ready():
	for child in get_children():
		if child is State:
			child.pokemon = pokemon
			states[child.name.to_lower()] = child
			child.transitioned.connect(on_state_transition)
	if initial_state:
		initial_state.pokemon = pokemon
		initial_state.enter()
		current_state = initial_state
			
func _process(delta):
	if current_state:
		current_state.update(delta)
	
func _physics_process(delta):
	if current_state:
		current_state.physics_update(delta)
		
func on_state_transition(state: State, new_state_name: String):
	if !state: return
	
	var new_state: State = states.get(new_state_name.to_lower())
	if !new_state: return
	
	if current_state:
		current_state.exit()
	
	new_state.enter()
	current_state = new_state
