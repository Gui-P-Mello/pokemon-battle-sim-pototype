extends State
class_name Approach

func physics_update(delta: float):
	if pokemon.health > 50:
		pokemon.approach(delta)
		if pokemon.oponent_distance <= 350:
			transitioned.emit(self, "RunIn")
