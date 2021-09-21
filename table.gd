extends Node2D

func _on_table_body_entered(body):
	Global.drop_hole(body)
	body.queue_free()
