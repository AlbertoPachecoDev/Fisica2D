extends Node2D

onready var ball = preload("res://ball.tscn")

func _ready():
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
