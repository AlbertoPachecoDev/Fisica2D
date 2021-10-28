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
	
	@todo:
	 - Mobile version?
"""

extends Node2D

signal reset()
signal damp(count)

const BallImage = [
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

const MxDampCnt = 45  # timer-activated damping cycles

onready var shots = 0  # issue-7
onready var balls = { }
onready var ball0 = null
onready var count_damp = 0
onready var drop_id = null # issue-1 drop-ball effect
onready var drops = 0   # issue-8 dropped balls counter 

onready var ball = preload("res://ball.tscn")

func _ready():
	Global.set_main(get_node(".")) # issue-13
	for id in range(Global.tot_balls): # issue-7
		var b = ball.instance()
		if id == 0:
			ball0 = b
			b.mass += 2
			ball0.connect("hit", self, "_cue_hit")
		else:
			balls[id] = b
		b.id = id
		b.name = "ball" + str(id)
		b.set_position(POS[id])
		b.get_node("sprite").set_texture(BallImage[id])
		add_child(b)
	set_process_input(false)
	reset()

func set_pause(mode): # issue-13
	print("set_pause=", mode)
	get_tree().paused = mode

func toggle_pause(): # issue-13
	var pause = not get_tree().paused
	print("toggle_pause=", pause)
	if pause:
		Global.set_score(0, "(Paused)") # display status
	else:
		Global.set_score(0, " ") # clear info
	set_pause(pause)

func reset():
	$inc_damp.stop()
	count_damp = 0
	if shots > 0:
		Global.set_score(0, "Shots: "+str(shots)) # issue-13
	else:
		Global.set_score() # issue-13 refresh score
	shots += 1
	emit_signal("reset")

func _cue_hit(_body):
	$start_damp.start()

func drop_hole(id): # issue-1 drop-ball effect
	drops += 1 # issue-8
	drop_id = id
	if id == 0:
		ball0.drop() # bug
	else:
		balls[id].drop()
	$hole.play()

func ball_out(id): # issue-3 remove outsider-ball
	if balls.has(id):
		var b = balls[id]
		if is_instance_valid(b):
			if b.is_queued_for_deletion():
				return
			b.queue_free()
			balls.erase(id)
			drops += 1
			Global.set_score(-100)			
	
func _on_friction_timeout():
	count_damp = 1
	emit_signal("damp", count_damp)
	$inc_damp.start()
	print("damping...")

func _on_inc_damp_timeout():
	count_damp += 1
	if count_damp < MxDampCnt:
		emit_signal("damp", count_damp)
		for k in balls:
			var b = balls[k]
			if is_instance_valid(b):
				if b.linear_velocity.length() > 2:
					return
		if ball0.linear_velocity.length() > 2:
			return
		print("Balls stopped!! ", count_damp)
		reset()
	else:
		print("Damp finished!!")
		$inc_damp.stop()
		reset()

func _on_hole_finished(): # issue-1 drop-ball effect
	if drop_id == 0: # ball-0?
		$end.play() # issue-10 game over!
	else:
		if balls.has(drop_id):
			var b = balls[drop_id]
			if is_instance_valid(b):
				if b.is_queued_for_deletion():
					return
				b.queue_free()
				balls.erase(drop_id)
				var punish = 100 if shots > 10 else ((shots-1) * 10)
				if drops==1 and Global.first_ball==drop_id: # issue-8 first-drop is winning-ball?
					Global.set_score(700 - punish, "Wonderful!")
					#$info.text = "Wonderful!"
				elif not balls.empty() and balls.keys().min() > drop_id: # issue-9 smaller ball
					Global.set_score(200 + 50 * drop_id - punish, "Great!") 
					#$info.text = "Great!"
				else: # issue-9
					Global.set_score(120 - punish, "Fine!")
					# $info.text = "Fine!"
				if balls.empty(): # issue-10 end: wins!
					Global.level += 1
					$end.play()

func _on_end_finished():
	#Global.cont.visible = true # issue-6 continue-button
	Global.show_buttons(true, false) # issue-13 show continue-button only
