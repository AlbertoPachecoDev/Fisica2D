extends Node2D

onready var ball = preload("res://ball.tscn")

var balls = []

func _ready():
	# warning-ignore:return_value_discarded
	Global.connect("drop", self, "remove")
	# warning-ignore:return_value_discarded
	Global.connect("damp", self, "not_moving")
	for i in range(10):
		var b = ball.instance()
		if i==0:
			Global.ball0 = b
			b.mass += 2
		b.id = i
		b.name = "ball" + str(i)
		b.set_position(Global.POS[i])
		b.get_node("sprite").set_texture(Global.Balls[i])
		add_child(b)
		balls.append(b)
		
func remove(id):
	balls[id].queue_free()
	balls.remove(id)

func not_moving(count):
	for b in balls:
		if is_instance_valid(b):
			if b.linear_velocity.length() > 2:
				return
	print("Balls stopped!! ", count)
	Global.reset()	
