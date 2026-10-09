@tool
extends StaticBody2D
## Invisible, closed physical perimeter. Portal transitions always require F.
@export var area := Rect2(0, 0, 1280, 720):
	set(value):
		area = value
		_rebuild()
## A closed floor outline, without repeating its first point. Empty keeps rectangle mode.
@export var outline := PackedVector2Array():
	set(value):
		outline = value
		_rebuild()
@export_range(16.0, 256.0) var thickness := 64.0:
	set(value):
		thickness = value
		_rebuild()

func _ready() -> void:
	_rebuild()

func _rebuild() -> void:
	if not is_inside_tree():
		return
	var polygon := get_node_or_null("Outline") as CollisionPolygon2D
	if outline.size() >= 3:
		if polygon == null:
			polygon = CollisionPolygon2D.new()
			polygon.name = "Outline"
			add_child(polygon)
		polygon.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		polygon.polygon = outline
		polygon.disabled = false
		for wall_name: String in ["Left", "Right", "Top", "Bottom"]:
			get_node(NodePath(wall_name)).disabled = true
		return
	if polygon != null:
		polygon.disabled = true
	var walls := {
		"Left": Rect2(area.position - Vector2(thickness, thickness), Vector2(thickness, area.size.y + thickness * 2.0)),
		"Right": Rect2(Vector2(area.end.x, area.position.y - thickness), Vector2(thickness, area.size.y + thickness * 2.0)),
		"Top": Rect2(area.position - Vector2(0, thickness), Vector2(area.size.x, thickness)),
		"Bottom": Rect2(Vector2(area.position.x, area.end.y), Vector2(area.size.x, thickness))
	}
	for wall_name: String in walls:
		var collision := get_node_or_null(NodePath(wall_name)) as CollisionShape2D
		if collision == null:
			continue
		var rect: Rect2 = walls[wall_name]
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		collision.position = rect.get_center()
		collision.disabled = false

func contains_body(center: Vector2, radius: float) -> bool:
	if outline.size() < 3:
		return area.grow(-radius + 0.5).has_point(center)
	if not Geometry2D.is_point_in_polygon(center, outline):
		return false
	for index in range(outline.size()):
		var nearest := Geometry2D.get_closest_point_to_segment(center, outline[index], outline[(index + 1) % outline.size()])
		if center.distance_to(nearest) < radius - 0.5:
			return false
	return true
