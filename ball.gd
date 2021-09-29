extends RigidBody2D

const BlurMx = 0.08
const BlurDec = BlurMx / 28.0

var id = 0

#onready var no_effect = NodePath("sprite:use_parent_material") #$sprite.use_parent_material
onready var shader = $sprite.material

func _ready():
	gravity_scale = 0.0
	reset()
	# warning-ignore:return_value_discarded
	Global.connect("reset", self, "reset")
	# warning-ignore:return_value_discarded
	Global.connect("damp", self, "update_damp")
	$sprite.use_parent_material = true


func _integrate_forces(state):
	var mag = state.linear_velocity.length()
	if mag > 100.0:
		if 	$sprite.use_parent_material:
			$sprite.use_parent_material = false
			shader.set_shader_param("quality", 3)
			shader.set_shader_param("x", BlurMx)

func reset():
	angular_damp = -0.2
	linear_damp = -0.5
	sleeping = false # activate physics
	$sprite.use_parent_material = true

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
		sleeping = true # stop physics
		$sprite.use_parent_material = true
		#print("stopped "+str(id))
	linear_damp  += 0.2
	angular_damp += 0.1
	var x = shader.get_shader_param("x")
	if x > BlurDec:
		x -= BlurDec
		shader.set_shader_param("x", x)	
