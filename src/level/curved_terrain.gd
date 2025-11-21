@tool
class_name curved_terrain
extends Path2D

@export var edge_texture: Texture2D
@export var center_texture: Texture2D
@export var visible_collision := true

var polygon2d: Polygon2D
var line2d: Line2D
var collision_shape2d: CollisionShape2D
var collision_polygon2d: CollisionPolygon2D


func _ready() -> void:
    polygon2d = Polygon2D.new()
    polygon2d.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    add_child(polygon2d)

    line2d = Line2D.new()
    line2d.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
    line2d.texture_mode = Line2D.LINE_TEXTURE_TILE
    add_child(line2d)

    var collision_staticbody: StaticBody2D = StaticBody2D.new()
    collision_polygon2d = CollisionPolygon2D.new()
    collision_staticbody.add_child(collision_polygon2d)
    add_child(collision_staticbody)

    texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    _generate_terrain()


func _process(_delta: float) -> void:
    if not Engine.is_editor_hint():
        set_process(false)
        return
    _generate_terrain()


func _generate_terrain() -> void:
    if !curve or curve.get_point_count() == 0:
        collision_polygon2d.polygon = []
        polygon2d.polygon = []
        line2d.points = []
        return
    
    var points = curve.get_baked_points()
    var collider_points = curve.get_baked_points()

    if points.size() > 1:
        points.append(points[1])

    polygon2d.polygon = points
    polygon2d.texture = center_texture

    line2d.points = points
    line2d.texture = edge_texture

    if collider_points.size() > 2:
        collision_polygon2d.polygon = collider_points
    collision_polygon2d.visible = visible_collision
