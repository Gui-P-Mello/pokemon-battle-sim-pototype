extends State
class_name Shoot

func enter():
	print('Vai atirar!')
	
func physics_update(delta: float):
	pokemon.shoot_projectile()
	if pokemon.health > 50:
		if pokemon.oponent_distance > 500:
			transitioned.emit(self, "Approach")
