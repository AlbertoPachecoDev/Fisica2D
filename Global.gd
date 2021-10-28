extends Node2D

var level = 1
var score = 0
var first_ball # issue-8 winning ball
var tot_balls  # issue-13
var root       # issue-13 main scene

onready var cont = get_node("buttons/cont")
onready var quit = get_node("buttons/quit")

func _ready():
	z_index = 10 # isssue-13 score over main scene
	$buttons.z_index = 10 # isssue-13 buttons over
	pause_mode = Node.PAUSE_MODE_PROCESS # issue-4 avoids pausing input
	hide_buttons() # issue-13
	tot_balls = 5 if level==1 else 10 # issue 7 8 13
	var rng = RandomNumberGenerator.new() # issue 8
	rng.randomize()
	first_ball = rng.randi_range(1, tot_balls - 1) # issue-8
	set_score(0, "Try first ball #" + str(first_ball))
	
func _input(_event): # issue-13
	if Input.is_action_pressed("ui_cancel"): # issue-5 quit game
		show_buttons()
		root.set_pause(true) # BUG
		#get_tree().paused = true
		#pause_mode = Node.PAUSE_MODE_PROCESS
	elif Input.is_action_pressed("ui_accept"): # issue-4 pause mode
		root.toggle_pause()

func set_main(scene): # issue-13
	root = scene
	# print(root.name)

func show_buttons(c=true, q=true): # issue-13
	cont.visible = c
	quit.visible = q

func hide_buttons(c=true, q=true): # issue-13
	cont.visible = not c
	quit.visible = not q

func set_score(num=0, info=""): # issue-13
	score += num
	$score.text = "Level: "+str(level)+"  Score: "+str(score)
	if info != "":
		$info.text = info

func _on_cont_pressed(): # issue-13
	root.set_pause(false) # issue-5 bug
	# warning-ignore:return_value_discarded
	get_tree().reload_current_scene()

func _on_quit_pressed(): #issue 5 13
	print("End & play again")
	get_tree().quit()
