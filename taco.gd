extends RigidBody2D

const MaxVel = 5500

func _ready():
	gravity_scale = 0.0

#func width():
#	return $sprite.texture.get_width()

func impulse(amount):
	apply_central_impulse(amount.clamped(MaxVel))
