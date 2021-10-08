extends Node2D

func _on_table_body_entered(body):
	if body.name.substr(0,4) == "ball":
		Global.drop_hole(body.id)
