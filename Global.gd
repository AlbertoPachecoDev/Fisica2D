extends Node2D

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
	Vector2(100,300), Vector2(440,300), 
	Vector2(500,300), Vector2(500,240), 
	Vector2(500,340), Vector2(560,180),
	Vector2(560,240), Vector2(560,300),
	Vector2(560,360), Vector2(560,420)
]
var screenH
var screenW
var level = 1
var score = 0
var mouse_start = null
var count_mv = 0
var ball0 = null
var dragging = false
var drag_start = Vector2()

func _ready():
	var scr = get_viewport_rect().size
	screenW = scr.x
	screenH = scr.y
	randomize()
	z_index = 1
	
func _input(event):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("click") and not dragging:
		dragging = true
		drag_start = get_global_mouse_position()
	if event.is_action_released("click") and dragging:
		dragging = false
		var drag_end = get_global_mouse_position()
		var dir = drag_end - drag_start
		ball0.impulse(dir * 4)

func drop_hole(ball):
	if ball.id != 0:
		score += 100
		$label.text = "Score: " + str(score)
	$hole.play()
