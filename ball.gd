extends RigidBody2D

signal hit(body)

const BlurMx = Vector2(0.03, 0.0)
const BlurDec = BlurMx.x / 250.0
const BlurStop = 50 * BlurDec

var id = 0

onready var shader = $sprite.material

func _ready():
	gravity_scale = 0.0 # remove gravity force!
	_reset()
	# warning-ignore:return_value_discarded
	get_parent().connect("reset", self, "_reset")
	# warning-ignore:return_value_discarded
	get_parent().connect("damp", self, "update_damp")
	$sprite.use_parent_material = true
	$drop_fx.interpolate_property(self, 'modulate:a',
		null, 0, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)

func _integrate_forces(state):
	var mag = state.linear_velocity.length()
	if 	$sprite.use_parent_material:
		if mag > 100.0:
			$sprite.use_parent_material = false
			shader.set_shader_param("dir", BlurMx)

func _reset():
	angular_damp = -0.3
	linear_damp  = -0.4
	sleeping = false # activate physics
	$sprite.use_parent_material = true

# https://godotengine.org/qa/50866/detect-if-rigidbody-touching-colliding-with-another-object
func _on_ball_body_entered(body):
	if body.name.substr(0,4) == "ball":
		var mag = self.linear_velocity.length()
		mag = clamp(mag, 10, 500)
		$sound.volume_db = range_lerp(mag, 500, 10, 1, -50)
		$sound.play()
	elif body.name == "taco":
		# print("hit:", body.impulse) 
		emit_signal("hit", body)

func update_damp(count):
	if linear_velocity.length() < 3 or count >= get_parent().MxDampCnt:
		if not sleeping:
			sleeping = true # stop physics
			$sprite.use_parent_material = true
	#linear_damp  += 0.04
	#angular_damp += 0.03
	linear_damp  = lerp(linear_damp,  1.8, 0.03)
	angular_damp = lerp(angular_damp, 0.1, 0.02)
	if not $sprite.use_parent_material:
		var v = shader.get_shader_param("dir")
		if v.x > BlurStop:
			v.x -= BlurDec
			shader.set_shader_param("dir", v)	

func drop(): # issue-1 drop-hole effect 
	$drop_fx.start()
	yield(get_tree().create_timer(0.1), "timeout") # delay
	sleeping = true # stop movement

func _on_VisibilityNotifier2D_screen_exited(): # issue-2: out-of-screen
	$fail.play()

func _on_fail_finished(): # issue-3: delayed removing outsider-ball
	get_parent().ball_out(id)
