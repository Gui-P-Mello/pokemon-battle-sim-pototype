extends AnimatedSprite2D
func _ready():
	frame_changed.connect(_on_frame_changed)

func _on_frame_changed():
	if frame == 5:
		queue_free()

