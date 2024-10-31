extends State
class_name Idle

var can_shoot: bool = false
@onready var timer: Timer = $Timer

func enter():
	if pokemon:
		print("ENTROU")
	timer.start()
	pass
	

func update(delta: float):
	if can_shoot && pokemon.is_trainer_cpu:
		pokemon.shoot_projectile()
		timer.start()
		can_shoot = false
	pass


func _on_timer_timeout():
	can_shoot = true
	timer.stop()
	pass # Replace with function body.
