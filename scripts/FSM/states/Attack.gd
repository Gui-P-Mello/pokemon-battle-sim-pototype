extends State
class_name Attack

func physics_update(delta: float):
	pokemon.attack(delta)
	if pokemon.health <= 50:
		transitioned.emit(self, "Dodge")
	transitioned.emit(self, "Idle")
		
