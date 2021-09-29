"""

RigidBody2D provides simulated physics bodies.
You don’t control a RigidBody2D directly.
You apply forces to it (gravity, impulses, etc.) and 
Godot physics engine calculates the resulting movement, 
including collisions, bouncing, rotating, etc.
You can modify RigidBody2D behavior via properties (Mass, Friction, Bounce, etc.)
A typical RigidBody2D scene has Sprite and CollisionShape2D children nodes.
By default a RigidBody2D falls downward. You can increase Gravity Scale or turn off (zero).  
add_force(): adds a continuous force to a rigid body. ej. steadily pushing rocket-thrust for going faster. 
Note that this adds to any already existing forces. The force continues to be applied until removed.
apply_impulse(): adds an instantaneous “kick” to the body. Imagine hitting a baseball with a bat.
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
	Vector2(300,300), Vector2(640,300), 
	Vector2(700,300), Vector2(700,240), 
	Vector2(700,340), Vector2(760,180),
	Vector2(760,240), Vector2(760,300),
	Vector2(760,360), Vector2(760,420)
]
const MxDampCnt = 14
var screenH
var screenW
var level = 1
var score = 0
var mouse_start = null
var ball0 = null
var dragging = false
var drag_start = Vector2()
var wtaco
var pos1
var pos2
var dir
var count_damp = 0
onready var cue = preload("res://taco.tscn")
var taco = null


func _ready():
	var scr = get_viewport_rect().size
	screenW = scr.x
	screenH = scr.y
	randomize()
	z_index = 1
	reset()

func reset():
	count_damp = 0
	taco = cue.instance()
	wtaco = taco.width() #$taco2.texture.get_width()
	taco.set_position(Vector2(100,300))
	taco.visible = false
	$taco2.visible = true
	add_child(taco)
	dragging = false
	emit_signal("reset")

func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if ball0 == null: return
	if count_damp != 0: return # freeze cue is balls are rolling
	if taco == null: return
	if dragging: # dragging
		var x0 = drag_start.x
		pos2 = Vector2(x0 - wtaco - (event.position.x - x0) / 4, ball0.position.y)
		$taco2.set_position(pos2)
	if event.is_action_pressed("click") and not dragging: # start
		dragging = true
		drag_start = event.position
		pos1 = Vector2(drag_start.x-wtaco, ball0.position.y)
		taco.set_position(pos1)
		$taco2.set_position(pos1)
		$taco2.visible = true
	if event.is_action_released("click") and dragging: # end
		dragging = false
		var drag_end = event.position
		dir = drag_end - drag_start
		#  $taco.impulse(dir*4)
		var tween = get_node("taco2/tween")
		tween.interpolate_property($taco2,'position',pos2,pos1,0.25,Tween.TRANS_LINEAR,Tween.EASE_OUT)
		tween.start()

func drop_hole(ball):
	if ball.name[0]== "b" and ball.id!=0:
		score += 100
		$label.text = "Score: " + str(score)
	$hole.play()

func _on_tween_tween_all_completed():
	$taco2.visible = false
	taco.visible = true
	#ball0.impulse(dir * 4)
	taco.impulse(dir * 6)
	$del_cue.start()

func _on_del_cue_timeout():
	$start_damp.start()
	taco.queue_free()

func _on_friction_timeout():
	count_damp = 1
	emit_signal("damp", count_damp)
	$inc_damp.start()

func _on_inc_damp_timeout():
	count_damp += 1
	if count_damp < MxDampCnt:
		emit_signal("damp", count_damp)
	else:
		$inc_damp.stop()
		reset()
