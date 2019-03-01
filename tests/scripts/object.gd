extends RigidBody2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
func get_size():
	return Vector2(32,32)
func underwater(yes,water_posy):
	
	var diffy=(water_posy-position.y)/100
	if yes:
		gravity_scale = diffy*30
		linear_velocity.y /= 1.5
	else:
		gravity_scale =30
	return linear_velocity
