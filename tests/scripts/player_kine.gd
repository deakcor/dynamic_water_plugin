extends KinematicBody2D

var motion=Vector2()
var dir=Vector2(0,0)
const jump=400
const speed=200
var g=10
var slow=1
var inwater=false
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
func get_size():
	return Vector2(32,32)
func underwater(yes,water_posy):
	inwater=yes
	var diffy=(water_posy-position.y)/100
	if yes:
		slow =max(0.5,0.99*slow)
	else:
		slow=1
	return motion
func _physics_process(delta):
	if Input.is_action_pressed("left"):
		dir.x=-1
	elif Input.is_action_pressed("right"):
		dir.x=1
	else:
		dir.x=0
	if Input.is_action_pressed("jump"):
		if is_on_floor() or inwater:
			motion.y=-jump
	motion.y+=g
	motion.x=dir.x*speed
	motion=move_and_slide(motion*slow,Vector2(0,-1))
