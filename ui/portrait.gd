class_name Portrait
extends CanvasLayer

@onready var p1_portrait_texture: TextureRect = $Player1PortraitTexture
@onready var p2_portrait_texture: TextureRect = $Player2PortraitTexture
@export var player_number: int

func _ready():
	var angry_texture: Texture = preload("res://ui/resources/0006/Angry.png")
	var angry_attack: Texture = preload("res://ui/resources/0006/0005/Angry.png")
	var pain_texture: Texture = preload("res://ui/resources/0006/Pain.png")
	#if player_number == 1:
		#change_texture(1 ,angry_attack)
		#change_texture(2, pain_texture)


func change_texture(player_number:int, new_texture: Texture):
	if player_number == 1:
		p1_portrait_texture.texture = new_texture
	elif player_number == 2:
		p2_portrait_texture.texture = new_texture
