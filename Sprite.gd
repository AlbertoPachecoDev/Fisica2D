# CLIPART: https://openclipart.org/download/277205/7SegmentNumbers.svg
# TWEENS:  https://docs.godotengine.org/en/stable/classes/class_tween.html
extends Sprite

var vel
var spin
var id = 0
onready var bouncex = false
onready var bouncey = false
onready var selected = false
onready var screensize = get_viewport_rect().size
onready var  width = int(texture.get_width()  * get_scale().x / 2)
onready var height = int(texture.get_height() * get_scale().y / 2)

func _ready():
	# warning-ignore:return_value_discarded
	Score.connect("digit_key", self, "choosen")
	# warning-ignore:return_value_discarded
	Score.connect("pause", self, "pause")
	$gamble.interpolate_property(self, 'modulate:a',
		null, 0.6, 1.0, Tween.TRANS_BACK, Tween.EASE_IN_OUT)
	$efecto_scale.interpolate_property(self, 'scale',
		null, Score.SCALE*0.75, 0.25, Tween.TRANS_QUAD, Tween.EASE_OUT)
	$efecto_final.interpolate_property(self, 'modulate:a',
		null, 0, 0.3, Tween.TRANS_QUAD, Tween.EASE_OUT)
	spin = rand_range(-PI, PI)
	set_position(Vector2(rand_range(250,screensize.x-250), rand_range(150,screensize.y-150)))
	vel = Score.get_vel()
	set_process(true)

func _process(delta):
	set_rotation(get_rotation() + spin * delta)
	var pos = get_position()
	pos += vel * delta
	if pos.x+width >= screensize.x or pos.x-width <= 0:
		if not bouncex: bouncex = true
		if bouncey:
			$efecto_final.start()
		else: # last-bounce-issue#7
			if not $bounce.playing: $bounce.play()
			vel.x *= -1 
	if pos.y+height >= screensize.y or pos.y-height <= 0:
		if not bouncey: bouncey = true
		if bouncex:
			$efecto_final.start()
		else: # last-bounce-issue#7
			$efecto_scale.start()
			if not $bounce.playing: $bounce.play()
			vel.y *= -1 
	set_position(pos)

func choosen(digit): # user-signal
	selected = (digit == id)
	if selected: $gamble.start()

func _on_efecto_final_tween_completed(_object, _key):
	if selected: $gamble.stop_all()
	Score.update_score(id) # score stop issue#1
	$out.play()

func _on_out_finished():
	queue_free()

func pause(mode):
	set_visible(not mode)
	
func set_vel(v):
	vel = v
