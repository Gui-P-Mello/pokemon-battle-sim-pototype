extends CharacterBody2D

@export var speed = 24000
var dir: Vector2
var caster: Pokemon
@onready var collision: Area2D = $Area2D

func _ready():
	collision.area_entered.connect(queue_free)
	collision.area_entered.connect(collision_test)

func _process(delta):		
	velocity = speed * dir * delta
	move_and_slide()
	var bodies = collision.get_overlapping_bodies()
	for body in bodies:
		if body is Pokemon and body != caster:
			var hit_pokemon: Pokemon = body
			hit_pokemon.take_damage(10)
			hit_pokemon.damage_stance(30)
		queue_free()
	
func collision_test():
	print("colidiu")
#func _on_body_entered(body):
	#if body is Pokemon:
		## Ação de colidir com o oponente, mas não fazer a física influenciar
		#queue_free()  # Destroi o projétil após a colisão

#extends StaticBody2D
#
#@export var speed = 100
#
#var dir: Vector2
#var spawnPos: Vector2
#var spawnRot: Vector2
#
#func _ready():
	#
	#pass
#
#func _process(delta):
	#global_position = global_position * speed * dir * delta
