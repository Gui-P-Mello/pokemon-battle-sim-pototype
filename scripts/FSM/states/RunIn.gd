extends State
class_name RunIn

func physics_update(delta: float):
	pokemon.run_in(delta)
	if pokemon.oponent_distance <= pokemon.melee_range:
		transitioned.emit(self, "Attack")
