extends RigidBody2D

func _ready():
	gravity_scale = 0.0

func width():
	return $sprite.texture.get_width()

func impulse(amount):
	apply_central_impulse(amount)
	#set_axis_velocity(amount)
