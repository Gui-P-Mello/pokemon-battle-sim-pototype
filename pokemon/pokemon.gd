class_name Pokemon
extends CharacterBody2D

@export_category("Stats")
@export var health: int = 100
@export var max_stamina: float = 100
@export var stamina: float = max_stamina
@export var stamina_regen_rate: float = 10
@export var max_stance: float = 100
@export var stance: float = max_stance
@export var stance_regen_rate: float = 10
@export var power: int = 20
@export var trust: float
@export var rage: float
@export var walk_speed: float = 5000
@export var run_speed: float = 10000
@export var melee_range: float = 50
@export var dodge_distance: float = 100

@export_category("Trainer")
enum trainer_command {APPROACH, RUN_IN, ATTACK, SHOOT, RUN_OUT, DISTANCE, DODGE, STOP, NONE, STUNNED, FAINT}
@export var is_trainer_cpu: bool = true
var last_trainer_command: trainer_command = trainer_command.NONE

@export_category("Oponent")
@export var oponent: Pokemon
@onready var oponent_position: Vector2 = oponent.position

@export_category("Match")
@export var player_number: int

@onready var nav_agent:= $NavigationAgent2D as NavigationAgent2D
@onready var melee_area: Area2D = $MeleeArea
@onready var melee_collision_shape: CollisionShape2D = $MeleeArea/CollisionShape2D
@onready var test = get_tree().get_root().get_node("Test")
@onready var projectile = preload("res://effects/projectile.tscn")
@onready var normal_texture: Texture = preload("res://ui/resources/0006/Normal.png")
@onready var angry_texture: Texture = preload("res://ui/resources/0006/Angry.png")
@onready var angry_attack: Texture = preload("res://ui/resources/0006/0005/Angry.png")
@onready var pain_texture: Texture = preload("res://ui/resources/0006/Pain.png")
@onready var faint_texture: Texture = preload("res://ui/resources/0006/Dizzy.png")
@onready var stunned_texture: Texture = preload("res://ui/resources/0006/Stunned.png")
@onready var determined_texture: Texture = preload("res://ui/resources/0006/Determined.png")
@onready var surprised_texture: Texture = preload("res://ui/resources/0006/Surprised.png")
@onready var dodge_texture: Texture = preload("res://ui/resources/0006/0005/Determined.png")
@onready var attack_portrait_timer = $AttackPortraitTimer
@onready var pain_portrait_timer = $PainPortraitTimer
@onready var stun_timer = $StunTimer
@onready var priority_texture: Texture = normal_texture
@onready var melee_cd = $MeleeCD
@onready var shoot_projectile_cd = $ProjectileCD

var stop: bool = true
var faint: bool = false
var is_dodging: bool = false
var oponent_distance: float
var target_position: Vector2
var has_dodge_target: bool =  false
var can_set_dodge_target: bool = true
var direction: Vector2
var is_stunned: bool = false
var can_melee: bool = true
var can_shoot_projectile: bool = true

@onready var sprite = $Sprite2D
@export var front_texture: Texture2D
@export var right_texture: Texture2D
@export var back_texture: Texture2D
@export var left_texture: Texture2D
@export var ui: Portrait
var melee_effect:PackedScene


func _ready():
	melee_effect = preload("res://effects/melee_effect.tscn")
	pass

func _process(delta):	
	pass

func _physics_process(delta):
	
	var next_path_position = nav_agent.get_next_path_position()
	direction = global_position.direction_to(next_path_position)
	update_sprite(direction)
	
	oponent_position = oponent.global_position
	make_path()
	oponent_distance = self.position.distance_to(oponent.global_position)
	
	#health_check()
	stance_check()
	regenerate_stamina(delta)
	regen_stance(delta)
	
	if !is_trainer_cpu:		
		
		set_last_trainer_command()
		if last_trainer_command == trainer_command.APPROACH && !is_stunned && !faint:
			approach(delta)
		if last_trainer_command == trainer_command.STOP && !is_stunned && !faint:
			last_trainer_command = trainer_command.NONE
			velocity = Vector2.ZERO
			ui.change_texture(player_number, priority_texture)
		if last_trainer_command == trainer_command.ATTACK && !is_stunned && !faint:
			attack(delta)
		if last_trainer_command == trainer_command.SHOOT && !is_stunned && !faint:
			shoot_projectile()
		if last_trainer_command == trainer_command.RUN_IN && !is_stunned && !faint:
			
			run_in(delta)
		if last_trainer_command == trainer_command.DISTANCE && !is_stunned && !faint:
			priority_texture = normal_texture
			distance(delta)
		if last_trainer_command == trainer_command.DODGE && !is_stunned && !faint: 
			dodge(delta)
		if last_trainer_command == trainer_command.STUNNED && !faint:
			
			#await get_tree().create_timer(2.0).timeout
			#stance = max_stance
			#is_stunned = false
			#last_trainer_command = trainer_command.NONE
			pass
		if last_trainer_command == trainer_command.FAINT:
			ui.change_texture(player_number, faint_texture)
	
func make_path():
	await get_tree().physics_frame
	if target_position:
		nav_agent.target_position = target_position
	
func approach(delta:float):
	var stamina_cost = stamina_regen_rate * delta
	if oponent_distance >= melee_range:
		ui.change_texture(player_number, determined_texture)
		target_position = oponent_position
		move(walk_speed, delta)
		spend_stamina(stamina_cost)
	else:
		ui.change_texture(player_number, normal_texture)
		velocity =  Vector2.ZERO
		last_trainer_command = trainer_command.NONE

func run_in(delta: float):
	var stamina_cost = 20 * delta
	if oponent_distance >= melee_range && stamina_cost < stamina:
		target_position = oponent_position
		ui.change_texture(player_number, surprised_texture)
		spend_stamina(stamina_cost)
		move(run_speed, delta)
	else:
		ui.change_texture(player_number, priority_texture)
		velocity =  Vector2.ZERO
		last_trainer_command = trainer_command.STOP

func attack(delta: float):
	var stamina_cost = 10
	var stance_damage = 30
	if stamina_cost > stamina: 
		print("Not enough stamina!")
		last_trainer_command = trainer_command.NONE
		return
			
	if oponent_distance > melee_range && !is_trainer_cpu:
		run_in(delta)
	elif can_melee:
		var bodies = melee_area.get_overlapping_bodies()
		for body in bodies:
			if body is Pokemon && body != self:
				var target: Pokemon = body
				var melee_effect_instance = melee_effect.instantiate()
				
				if sprite.texture == right_texture || sprite.texture == left_texture:
					melee_effect_instance.position = position + (target.global_position - global_position).normalized()	*50	+ Vector2(0, -20)
				else:
					melee_effect_instance.position = position + (target.global_position - global_position).normalized()	*50			
				ui.change_texture(player_number, angry_attack)
				attack_portrait_timer.start()
				get_parent().add_child(melee_effect_instance)
				spend_stamina(stamina_cost)
				deal_damage(target)
				target.damage_stance(stance_damage)
				can_melee = false
				melee_cd.start()
		last_trainer_command = trainer_command.NONE
		velocity = Vector2.ZERO
		
func shoot_projectile():
	var stamina_cost = 10
	if stamina_cost > stamina: 
		print("Not enough stamina!")
		last_trainer_command = trainer_command.NONE
		return
	elif can_shoot_projectile:
		ui.change_texture(player_number, angry_attack)
		attack_portrait_timer.start()
		spend_stamina(stamina_cost)
		can_shoot_projectile = false
		shoot_projectile_cd.start()
			
		var instance:Node2D = projectile.instantiate()
		instance.dir = global_position.direction_to(oponent.position)
		var oponent_direction: Vector2 = global_position.direction_to(oponent.position).normalized()
		var instance_offset: Vector2 = oponent_direction * 50
		instance.caster = self
		instance.position = position + instance_offset
		get_parent().add_child(instance)
		last_trainer_command = trainer_command.NONE

func distance(delta: float):
	ui.change_texture(player_number, determined_texture)
	var stamina_cost = stamina_regen_rate * delta
	var dir = (oponent_position - position).normalized() * -1
	velocity = dir * walk_speed * delta
	spend_stamina(stamina_cost)
	move_and_slide()

func run_out():
	pass
	
func dodge(delta: float):
	var stamina_cost = 20
	if !is_dodging:
		if stamina_cost > stamina: 
			print("Not enough stamina!")
			last_trainer_command = trainer_command.NONE
			return
		ui.change_texture(player_number, dodge_texture)
		spend_stamina(stamina_cost)
		
	var dir = (oponent_position - global_position).normalized()
	var left_dir = Vector2(dir.y, -dir.x) * dodge_distance
	var right_dir = Vector2(-dir.y, dir.x) * dodge_distance
	
	var dodge_dir = Vector2.ZERO

	if !has_dodge_target:
		# Escolhe uma direção de desvio aleatória entre esquerda e direita
		if randi() % 2 == 0:
			dodge_dir = left_dir
			print("Esquivando para a esquerda")
		else:
			dodge_dir = right_dir
			print("Esquivando para a direita")

		target_position = position + dodge_dir
		has_dodge_target = true
		can_set_dodge_target = false

	# Move-se diretamente para o `target_position` em alta velocidade (sem usar NavigationAgent)
	if global_position.distance_to(target_position) > 10:  # Verifica se ainda não chegou no destino
		var move_direction = global_position.direction_to(target_position)
		velocity = move_direction * run_speed * 3 * delta
		move_and_slide()
		is_dodging = true
	else:
		ui.change_texture(player_number, priority_texture)
		print("Chegou ao destino de esquiva")
		is_dodging = false
		has_dodge_target = false
		can_set_dodge_target = true
		last_trainer_command = trainer_command.NONE

	# Modulação de cor para indicar a esquiva
	modulate = Color.BLUE
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUINT)
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func behaviour():
	
	pass

func set_last_trainer_command():
	if Input.is_action_just_pressed("Approach"):
		last_trainer_command = trainer_command.APPROACH
	if Input.is_action_just_pressed("Stop"):
		last_trainer_command = trainer_command.STOP			
	if Input.is_action_just_pressed("Attack"):
		last_trainer_command = trainer_command.ATTACK
	if Input.is_action_just_pressed("Run_In"):
		last_trainer_command = trainer_command.RUN_IN
	if Input.is_action_just_pressed("Distance"):
		last_trainer_command = trainer_command.DISTANCE
	if Input.is_action_just_pressed("Dodge"):
		last_trainer_command = trainer_command.DODGE
	if Input.is_action_just_pressed("Shoot"):
		last_trainer_command = trainer_command.SHOOT
	
func deal_damage(oponent:Pokemon):	
	if oponent:
		print("Your pokémon is hitting its oponent!")
		oponent.take_damage(power)

func take_damage(amount: int):
	if health > 0 && !faint:
		health -= amount
		
		if health > 0:
			ui.change_texture(player_number, pain_texture)
			pain_portrait_timer.start()
	else:
		faint = true
		ui.change_texture(player_number, faint_texture)
			
		modulate = Color.RED
		var tween = create_tween()
		tween.set_ease(Tween.EASE_IN)
		tween.set_trans(Tween.TRANS_QUINT)
		tween.tween_property(self, "modulate", Color.WHITE, 0.3)
		
		print("CPU Trainer pokémon got hit! Its HP has dropped to: ", health)
	
func spend_stamina(amount: float):
	stamina -= amount
	#print("Pokémon has spent ", amount, " stamina" )
	#print("Pokémon current stamina", stamina)

func regenerate_stamina(delta: float):
	if !faint:
		var stamina_regen_amount = stamina_regen_rate * delta
		
		if stamina < max_stamina:
			stamina = min(stamina + stamina_regen_amount, max_stamina)
			#print("Current stamina: ", stamina)
			
func damage_stance(amount: float):
	if stance > 0 && !faint && !is_stunned:
		stance -= amount
	#print("Pokémon current stance", stance)
	
func regen_stance(delta: float):
	if !faint:
		var stance_regen_amount = stance_regen_rate * delta
		
		if stance < max_stance:
			stance = min(stance + stance_regen_amount, max_stance)
			#print("Pokémon current stance", stance)

func stance_check():
	if stance <= 0 && health > 0 && !is_stunned && !faint:
		is_stunned = true
		ui.change_texture(player_number, stunned_texture)
		stun_timer.start()
		last_trainer_command = trainer_command.STUNNED

func move(speed: float, delta: float):
	if nav_agent.is_navigation_finished(): return
	var current_agent_position = global_position
	var next_path_position = nav_agent.get_next_path_position()
	
	velocity = current_agent_position.direction_to(next_path_position) * speed * delta
	move_and_slide()
	
func update_sprite(direction: Vector2):
	if abs(direction.x) > abs(direction.y): # Movendo mais no eixo X (esquerda ou direita)
		if direction.x > 0:
			sprite.texture = right_texture  # Direita
		else:
			sprite.texture = left_texture   # Esquerda
	else: # Movendo mais no eixo Y (frente ou costas)
		if direction.y > 0:
			sprite.texture = front_texture   # Para trás
		else:
			sprite.texture =  back_texture # Para frente

func update_portrait():
	pass

func _on_attack_portrait_timer_timeout():
	if !faint:
		ui.change_texture(player_number,normal_texture)
		print("Player ", player_number, "texture has changed to normal")
		attack_portrait_timer.stop()

func _on_pain_portrait_timer_timeout():
	if !faint:
		ui.change_texture(player_number, normal_texture)
		print("Player ", player_number, "texture has changed to normal")
		pain_portrait_timer.stop()
	if is_stunned:
		ui.change_texture(player_number, stunned_texture)

func _on_stun_timer_timeout():
	if !faint:
		stance = max_stance
		is_stunned = false
		last_trainer_command = trainer_command.NONE
		ui.change_texture(player_number, normal_texture)
		stun_timer.stop()

func _on_melee_cd_timeout():
	can_melee = true
	melee_cd.stop()

func _on_projectile_cd_timeout():
	can_shoot_projectile = true
	shoot_projectile_cd.stop()
