extends CollisionPolygon2D

func _ready():
	self.polygon = $"../wall".polygon
	pass
