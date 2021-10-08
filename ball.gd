extends RigidBody2D

const BlurMx = Vector2(0.035, 0.0)
const BlurDec = BlurMx.x / 250.0
const BlurStop = 50 * BlurDec

var id = 0

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
	if 	$sprite.use_parent_material:
		if mag > 100.0:
			$sprite.use_parent_material = false
			shader.set_shader_param("dir", BlurMx)

func reset():
	angular_damp = -0.2
	linear_damp = -0.5
	sleeping = false # activate physics
	$sprite.use_parent_material = true

# https://godotengine.org/qa/50866/detect-if-rigidbody-touching-colliding-with-another-object
func _on_ball_body_entered(body):
	if body.name.substr(0,4) == "ball":
		var mag = self.linear_velocity.length()
		mag = clamp(mag, 10, 500)
		$sound.volume_db = range_lerp(mag, 500, 10, 1, -50)
		$sound.play()

func update_damp(count):
	if linear_velocity.length() <= 2.0 or count >= Global.MxDampCnt:
		if not sleeping:
			sleeping = true # stop physics
			$sprite.use_parent_material = true
	linear_damp  += 0.07
	angular_damp += 0.05
	if not $sprite.use_parent_material:
		var v = shader.get_shader_param("dir")
		if v.x > BlurStop:
			v.x -= BlurDec
			shader.set_shader_param("dir", v)	
