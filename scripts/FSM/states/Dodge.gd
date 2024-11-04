extends State
class_name Dodge

func physics_update(delta:float):
	pokemon.dodge(delta)
	if pokemon.health <= 40:
		transitioned.emit(self, "Shoot")
