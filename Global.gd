"""
	RigidBody2D provides simulated physics bodies.
	You don’t control a RigidBody2D directly.
	You apply forces to it (gravity, impulses, etc.) and 
	Godot physics engine calculates the resulting movement, 
	including collisions, bouncing, rotating, etc.
	You can modify RigidBody2D behavior via properties (Mass, Friction, Bounce, etc.)
	A typical RigidBody2D scene has Sprite and CollisionShape2D children nodes.
	By default a RigidBody2D falls downward. You can increase Gravity Scale or turn off (zero).  
	- add_force(): adds a continuous force to a rigid body. ej. steadily pushing rocket-thrust for going faster. 
	  Note that this adds to any already existing forces. The force continues to be applied until removed.
	- apply_impulse(): adds an instantaneous “kick” to the body. Imagine hitting a baseball with a bat.
	  By default, the physics settings provide some damping, which reduces a body’s velocity and spin.

	https://kidscancode.org/godot_recipes/physics/godot3_kyn_rigidbody1
	https://opengameart.org
"""

extends Node2D

signal reset()
signal damp(count)

const Balls = [
	 preload("res://images/0.png"),
	 preload("res://images/1.png"),
	 preload("res://images/2.png"),
	 preload("res://images/3.png"),
	 preload("res://images/4.png"),
	 preload("res://images/5.png"),
	 preload("res://images/6.png"),
	 preload("res://images/7.png"),
	 preload("res://images/8.png"),
	 preload("res://images/9.png"),
]
const POS = [
	Vector2(300,300), Vector2(600,300), 
	Vector2(660,300), Vector2(660,240), 
	Vector2(660,360), Vector2(720,180),
	Vector2(720,240), Vector2(720,300),
	Vector2(720,360), Vector2(720,420)
]

const MxDampCnt = 36  # timer-activated damping cycles
var screenH
var screenW

var level = 1
var score = 0

var balls = []
var ball0 = null
var count_damp = 0

onready var ball = preload("res://ball.tscn")

func _ready():
	var scr = get_viewport_rect().size
	screenW = scr.x
	screenH = scr.y
	randomize()
	#z_index = 1
	for i in range(10):
		var b = ball.instance()
		if i==0:
			ball0 = b
			b.mass += 2
			ball0.connect("hit", self, "_cue_hit")
		b.id = i
		b.name = "ball" + str(i)
		b.set_position(POS[i])
		b.get_node("sprite").set_texture(Balls[i])
		add_child(b)
		balls.append(b)
	reset()

func reset():
	# Engine.time_scale = 0.1
	$inc_damp.stop()
	count_damp = 0
	emit_signal("reset")

func _cue_hit(_body):
	$start_damp.start()

func _input(_event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()

func drop_hole(id):
	if id == 0:
		print("Game over")
		# warning-ignore:return_value_discarded
		get_tree().reload_current_scene()
	else:
		score += 100
		$label.text = "Score: " + str(score)
		if is_instance_valid(balls[id]):
			balls[id].queue_free()
			balls.remove(id)
	$hole.play()

func _on_friction_timeout():
	count_damp = 1
	emit_signal("damp", count_damp)
	$inc_damp.start()

func _on_inc_damp_timeout():
	count_damp += 1
	if count_damp < MxDampCnt:
		emit_signal("damp", count_damp)
		for b in balls:
			if is_instance_valid(b):
				if b.linear_velocity.length() > 2:
					return
		print("Balls stopped!! ", count_damp)
		reset()
	else:
		print("Damp finished!!")
		$inc_damp.stop()
		reset()
