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
	Vector2(300,300), # 0 - 1
	Vector2(600,300), # 1 - 1
	Vector2(650,250), # 2 - 1
	Vector2(650,350), # 3 - 1
	Vector2(650,300), # 4 - 1 (5) issue-12
	Vector2(700,300), # 5 - 2 (6) issue-12
	Vector2(700,200), # 6 - 3
	Vector2(700,400), # 7 - 3 (8) issue-12
	Vector2(700,250), # 8 - 4
	Vector2(700,350), # 9 - 4
]

const BALLS_LEVEL = [5, 6, 8] # issue-12

const MxDampCnt = 45  # timer-activated damping cycles

onready var shots = 0  # issue-7
onready var balls = { }
onready var ball0 = null
onready var count_damp = 0
onready var drop_id = null # issue-1 drop-ball effect
onready var first_ball = 0 # issue-8 winning ball
onready var drops = 0		 # issue-8 dropped balls counter 

onready var ball = preload("res://ball.tscn")
onready var cont = get_node("buttons/continue") # issue-5
onready var quit = get_node("buttons/quit")     # issue-6

func _ready():
	quit.visible = false # issue-5
	cont.visible = false # issue-6
	$buttons.z_index = 1
	pause_mode = Node.PAUSE_MODE_PROCESS # issue-4 avoids pausing input
	var tot = POS.size() if Global.level>3 else BALLS_LEVEL[Global.level-1] # issue-12
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	first_ball = rng.randi_range(1, tot-1) # issue-8
	$info.text = "Try first ball #" + str(first_ball)
	for id in range(tot): # issue-7: only 5-balls if level=0
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
	reset()

func _input(_event):
	if Input.is_action_pressed("ui_cancel"): # issue-5 quit game
		cont.visible = true
		quit.visible = true
		get_tree().paused = true # BUG
	elif Input.is_action_pressed("ui_accept"): # issue-4 pause mode
		var pause = not get_tree().paused
		if pause:
			$info.text = "(Paused)"
		else:
			$info.text = ""
		$start_damp.paused = pause
		$inc_damp.paused = pause
		get_tree().paused = pause

func reset():
	$inc_damp.stop()
	count_damp = 0
	if shots > 0:
		$info.text = "Shots: "+str(shots)
	shots += 1
	set_score()
	emit_signal("reset")

func _cue_hit(_body):
	$start_damp.start()

func set_score(num=0):
	Global.score += num
	$score.text = "Level: "+str(Global.level)+"  Score: "+str(Global.score)

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
			set_score(-100)
	if id == 0: # ball-0?
		$end.play() # issue-11 game over!

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

func _on_end_finished():
	cont.visible = true # issue-6 continue-button

func _on_hole_finished(): # issue-1 drop-ball effect
	if drop_id == 0: # ball-0?
		$end.play()  # issue-10 game over!
	else:
		if balls.has(drop_id):
			var b = balls[drop_id]
			if is_instance_valid(b):
				if b.is_queued_for_deletion():
					return
				b.queue_free()
				balls.erase(drop_id)
				var punish = 100 if shots > 10 else ((shots-1) * 10)
				if drops==1 and first_ball==drop_id: # issue-8 first-drop is winning-ball?
					set_score(700 - punish)
					$info.text = "Wonderful!"
				elif not balls.empty() and balls.keys().min() > drop_id: # issue-9 smaller ball
					set_score(200 + 50 * drop_id - punish) 
					$info.text = "Great!"
				else: # issue-9
					set_score(120 - punish)
					$info.text = "Fine!"
				if balls.empty(): # issue-10 end: wins!
					Global.level += 1
					$end.play()

func _on_continue_pressed(): # issue-6-10 restart game
	get_tree().paused = false # issue-5 bug
	# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _on_exit_pressed(): #issue-5
	get_tree().quit()
