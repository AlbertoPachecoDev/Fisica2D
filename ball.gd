extends RigidBody2D

var id = 0

func _ready():
	gravity_scale = 0.0
	reset()
	# warning-ignore:return_value_discarded
	Global.connect("reset", self, "reset")
	# warning-ignore:return_value_discarded
	Global.connect("damp", self, "update_damp")

func reset():
	angular_damp = -0.2
	linear_damp = -0.5
	sleeping = false

func impulse(amount):
	self.apply_central_impulse(amount)
	self.angular_velocity = amount.length() / 10

# https://godotengine.org/qa/50866/detect-if-rigidbody-touching-colliding-with-another-object
func _on_ball_body_entered(body):
	if body.name.substr(0,4) == "ball":
		var mag = self.linear_velocity.abs().length()
		mag = clamp(mag, 10, 500)
		var db = range_lerp(mag, 500, 10, 1, -40)
		$sound.volume_db = db
		$sound.play()

func update_damp(count):
	if linear_velocity.length() <= 3.0 or count >= Global.MxDampCnt:
		sleeping = true
		#print("stopped "+str(id))
	linear_damp  += 0.2
	angular_damp += 0.1
