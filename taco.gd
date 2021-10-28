"""
KinematicBody2D is for implementing bodies that are controlled via code.
They detect collisions with other bodies, but are not affected by physics engine, like gravity or friction.
You have to write code to create their behavior, giving more precise control over how they move and react.
They can be affected by gravity and other forces, but you must calculate the movement in code. 
The physics engine will not move a KinematicBody2D.
For moving them, do not set its position directly.
Note: For dragging them set on the Pickable property. 
You must use the move_and_collide() or move_and_slide() methods. 
These methods move the body along a given vector and instantly stop if a collision is detected with another body.
After a KinematicBody2D has collided, any collision response must be coded manually.
Warning: You should only do Kinematic body movement in _physics_process(). The two movement methods serve different purposes.

- move_and_collide:
	Its Vector2 parameter indicates the body relative movement.
	Typically, this is your velocity vector multiplied by the frame timestep (delta).
	If the engine detects a collision anywhere along this vector, the body will immediately stop moving. 
	If this happens, the method will return a KinematicCollision2D object containing data about the collision and the colliding object. 
	Using this data, you can calculate your collision response.

- move_and_slide:
	Collision response where you want one body to slide along the other.
	It is especially useful in platformers or top-down games.
	Tip: It automatically calculates frame-based movement using delta. 
	Do not multiply your velocity vector by delta before passing it to move_and_slide().

https://godotengine.org/qa/70388/dragging-kinematic-bodies
https://docs.godotengine.org/en/stable/tutorials/physics/using_kinematic_body_2d.html
https://docs.godotengine.org/en/stable/tutorials/math/vector_math.html

@todo: impulse f(topped-magnitude) then reduce 0.1 each frame

"""

extends KinematicBody2D 

const MaxVel = 30
enum BallState { READY, DRAG, SHOT, HIT, MOVING, OFF }

onready var drag_start = Vector2(200,300)
onready var    impulse = Vector2.ZERO
onready var      state = BallState.OFF # object state
onready var     offset = Vector2(-width()/2, 0)

export onready var speed = 10 # Player movement speed

func _ready():
	set_pickable(true) # draggable
	set_process(true)
	$sprite.set_offset(offset) # move pivot to cue extreme
	# warning-ignore:return_value_discarded
	get_parent().connect("reset", self, "_reset")

func change_state(st): # transiciones estado
	state = st
	match state:
		BallState.READY, BallState.DRAG:
			collisions(false)
			set_visible(true)
		BallState.SHOT:
			collisions(true)
			set_visible(true)
		BallState.HIT:
			pass
		BallState.MOVING, BallState.OFF:
			collisions(false)
			set_visible(false)
		_:
			print("State Error: ", st)

func _reset():
	if is_instance_valid(get_parent().ball0):
		var b0 = get_parent().ball0
		if not b0.is_connected("hit", self, "_on_contact_detected"):
			b0.connect("hit", self, "_on_contact_detected")
	else:
		print("Game over: ball 0 dropped")
	set_position(drag_start)
	change_state(BallState.READY)

func _on_contact_detected(_body):
	change_state(BallState.HIT)
	$del_cue.start()

func _process(_delta):
	if state == BallState.MOVING: return
	if state == BallState.OFF: return
	var position = get_viewport().get_mouse_position()
	if Input.is_action_pressed("click"): # dragging?
		if state == BallState.DRAG: # moving
			set_rotation(drag_start.angle_to_point(position))
			set_position(position)
		else: # start
			drag_start = position
			set_position(position)
			change_state(BallState.DRAG)
	elif state == BallState.DRAG: # end
			impulse = (position - drag_start) * speed
			change_state(BallState.SHOT)

func _physics_process(delta):
	if state == BallState.SHOT:
		var movement = impulse * delta * -1 # reversed
		movement = movement.clamped(MaxVel)
		# warning-ignore:return_value_discarded
		move_and_collide(movement) # movement

# https://godotengine.org/qa/57186/disable-collisionshape2d-%24collisionshape2d-disabled-godot
func collisions(flag):
	$collision.set_deferred("disabled", not flag) 

func width():
	return $sprite.texture.get_width()

func _on_del_cue_timeout():
	change_state(BallState.MOVING)
