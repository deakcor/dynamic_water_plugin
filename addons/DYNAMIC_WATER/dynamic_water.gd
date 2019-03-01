tool
extends Node2D

#variables seen in editor
export (float) var HEIGHT = 0
export (float) var WIDTH = 0
export (float) var QUALITY = 1
export (Color) var COR = Color(1.0, 1.0, 1.0, 1.0)
export (ParticlesMaterial) var droplets_material_path

export (float) var TENSION = 0.025
export (float) var DAMPING = 0.001
export (int) var PASSES = 1
export (float) var DISPERSION = 0.01
export (float) var force_multiplier = 0.01
export (int) var NUMBER_OF_VECS_TO_APPLY_FORCE = 1

#non-modifiable variables
var vecs_positions = []
var vecs_velocity = []
var left_vec = []
var right_vec = []

var water
var area
var _col
#var to stock body underwater
var bodies=[]
func _ready(): #function called up in the execution of the node
	if Engine.is_editor_hint() == false:
 		create_water_block()
	set_process(true)

func _process(delta): #function called every frame
	if Engine.is_editor_hint() == false:
		_dynamic_physics()
	else:
		update()
	#update water for each body in water
	for body in bodies:
		var vel=body.underwater(true,self.position.y-HEIGHT)
		distortion(vel,body.position,body.get_size().x)
	
func _dynamic_physics(): #function responsible for the dynamic physics of water
	for i in vecs_positions.size() - 2:
		var target_y = -HEIGHT - vecs_positions[i].y
		vecs_velocity[i] += (TENSION * target_y) - (DAMPING * vecs_velocity[i])
		vecs_positions[i].y += vecs_velocity[i]
		
		water.polygon[i] = vecs_positions[i]
	
	#dispersion
	for i in vecs_positions.size() - 2:
		left_vec[i] = 0
		right_vec[i] = 0
	
	for j in PASSES:
		for i in vecs_positions.size() - 2:
			if i > 0:
				left_vec[i] = DISPERSION * (vecs_positions[i].y - vecs_positions[i - 1].y)
				vecs_velocity[i - 1] += left_vec[i]
			if i < vecs_positions.size() - 3:
				right_vec[i] = DISPERSION * (vecs_positions[i].y - vecs_positions[i + 1].y)
				vecs_velocity[i + 1] += right_vec[i]
		for i in vecs_positions.size() - 2:
			if i > 0:
				vecs_positions[i - 1].y += left_vec[i]
			if i < vecs_positions.size() - 3:
				vecs_positions[i + 1].y += right_vec[i]
		
func create_water_block(): #water creation
	#creation of custom nodes variables
	var water_block = Polygon2D.new()
	var area = Area2D.new()
	var col = CollisionPolygon2D.new()
	
	#creation of value variables
	var distance_beetween_vecs = WIDTH / QUALITY
	var vecs = PoolVector2Array([])
	
	vecs.insert(0, Vector2(0, -HEIGHT))
	
	for i in QUALITY:
		vecs.insert(i+1, Vector2(distance_beetween_vecs * (i + 1),-HEIGHT))
	
	vecs.insert(QUALITY + 1, Vector2(WIDTH, 0))
	vecs.insert(QUALITY + 2, Vector2(0, 0))
		
	#assignment of variables to custom nodes
	water_block.name = "water_base"
	water_block.polygon = vecs
	water_block.color = COR

	area.name = "water_area"
	
	col.name = "water_col"
	col.polygon = water_block.polygon
	
	#custom nodes to scene
	self.add_child(water_block)
	water_block.add_child(area)
	area.add_child(col)
	
	#signals
	area.connect("body_entered", self, "body_emerged")
	area.connect("body_exited", self, "body_not_emerged")
	
	#variables to dynamic physics
	for i in water_block.polygon.size():
		vecs_positions.insert(i, water_block.polygon[i])
		vecs_velocity.insert(i, 0)
		left_vec.insert(i, 0)
		right_vec.insert(i, 0)
	
	#new nodes
	water = $"./water_base"
	_col = $"./water_base/water_area/water_col"
#water distortion, take velocity of the object, his position and his size
func distortion(velocity,pos,size):
	#the force, the more the body is deep, less the water will be impacted
	var force_applied = -(-abs(velocity.x)+velocity.y) * force_multiplier*(1-min(2*(pos.y-self.position.y+HEIGHT)/HEIGHT,1))
	var offset=min(velocity.x,size) if velocity.x>0 else max(velocity.x,-size)
	var body_pos = pos.x - self.position.x+(offset)
	var closest_vec_pos_x = 9999999
	var closest_vec = 0
	for i in vecs_positions.size() - 2:
		var distance_diference = vecs_positions[i].x - body_pos 
		if distance_diference < 0:
			distance_diference *= -1
		if distance_diference < closest_vec_pos_x:
			closest_vec = i
			closest_vec_pos_x = distance_diference
	
	vecs_velocity[closest_vec] -= force_applied
	
	for i in NUMBER_OF_VECS_TO_APPLY_FORCE:
		if closest_vec - i > -vecs_velocity.size():
			vecs_velocity[closest_vec - i] -= force_applied
		if closest_vec + i < vecs_velocity.size():
			vecs_velocity[closest_vec + i] -= force_applied
func body_emerged(body): #body go underwater
	#the body need an underwater method and a get_size method
	if body.has_method("underwater"):
		var vel=body.underwater(true,self.position.y-HEIGHT)
		distortion(vel,body.position,body.get_size().x)
		bodies.append(body)
		
		
		
		#effects
		if droplets_material_path != null:
			var droplets = Particles2D.new()
			droplets.name = "particles"
			droplets.amount = 20
			droplets.lifetime = 2
			droplets.explosiveness = 1
			droplets.one_shot = true
			droplets.local_coords = false
			droplets.process_material = droplets_material_path
			
			droplets.global_position = Vector2(body.global_position.x, body.global_position.y + 30)
			droplets.rotation_degrees = -90
			
			$"..".add_child(droplets)
			
			droplets.visibility_rect = Rect2(Vector2(-900, -2000), Vector2(9999, 9999))
		
	pass

func body_not_emerged(body): 
	if body.has_method("underwater"):
		var vel=body.underwater(false,self.position.y-HEIGHT)
		distortion(vel,body.position,body.get_size().x)
		bodies.remove(bodies.find(body))

func _draw(): #polygon drawing for viewing by the editor
	var vecs = PoolVector2Array([])
	var color = PoolColorArray([])
	if Engine.is_editor_hint():
		vecs = PoolVector2Array([Vector2(0, -HEIGHT), Vector2(WIDTH, -HEIGHT), Vector2(WIDTH, 0), Vector2(0, 0)])
		color = PoolColorArray([Color(1.0, 1.0, 1.0, 0.4), Color(1.0, 1.0, 1.0, 0.4), Color(1.0, 1.0, 1.0, 0.4), Color(1.0, 1.0, 1.0, 0.4)])
		
	draw_polygon(vecs, color)
