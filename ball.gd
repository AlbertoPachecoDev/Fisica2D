extends RigidBody2D

var id = 0

func _ready():
	gravity_scale = 0.0

func impulse(amount):
	self.apply_central_impulse(amount)
	self.angular_velocity = amount.length() / 10

# https://godotengine.org/qa/50866/detect-if-rigidbody-touching-colliding-with-another-object
func _on_ball_body_entered(body):
	if body.name.substr(0,4) == "ball":
		var mag = self.linear_velocity.abs().length()
		mag = clamp(mag, 10, 500)
		var db = range_lerp(mag, 500, 10, 1, -40)
		#print(mag,"  ",db)
		$sound.volume_db = db
		$sound.play()

