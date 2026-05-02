extends Camera3D

@export var lerp_speed     := 3.0
@export var fov_min        := 45.0
@export var fov_max        := 75.0
@export var max_spread     := 25.0   # fighter distance that reaches fov_max
@export var h_padding      := 3.0    # extra space around fighters horizontally
@export var v_padding      := 2.0    # extra space vertically
@export var height_offset  := 4.0    # camera sits this far above the focus point
@export var bounds_margin  := 1.5    # how far inside the blast zone the camera stops

var _base_x: float           # camera never moves toward/away from the stage
var _base_y: float
var _focus := Vector3.ZERO

var _bound_z     := 14.0
var _bound_y_min := -2.0
var _bound_y_max :=  9.0

func _ready() -> void:
	_base_x = global_position.x
	_base_y = global_position.y
	_compute_bounds_from_death_box()
	_focus = Vector3(0.0, _base_y, 0.0)

func _process(delta: float) -> void:
	var fighters := get_tree().get_nodes_in_group("fighters")
	if fighters.size() < 2:
		return

	# Build bounding box around all fighters
	var min_z :=  INF
	var max_z := -INF
	var min_y :=  INF
	var max_y := -INF
	for f in fighters:
		var p: Vector3 = f.global_position
		min_z = minf(min_z, p.z)
		max_z = maxf(max_z, p.z)
		min_y = minf(min_y, p.y)
		max_y = maxf(max_y, p.y)

	# Midpoint clamped to stage soft bounds derived from the DeathBox
	var mid_z := clampf((min_z + max_z) * 0.5, -_bound_z, _bound_z)
	var mid_y := clampf((min_y + max_y) * 0.5, _bound_y_min, _bound_y_max)

	# FOV from the larger spread axis
	var spread := maxf((max_z - min_z) + h_padding * 2.0,
					   (max_y - min_y) + v_padding * 2.0)
	var target_fov := lerpf(fov_min, fov_max, clampf(spread / max_spread, 0.0, 1.0))

	# Smooth the focus point — single source of smoothing for both position and aim
	var target_focus := Vector3(0.0, mid_y, mid_z)
	_focus = _focus.lerp(target_focus, lerp_speed * delta)

	# Camera sits at fixed X depth, raised above the focus
	global_position = Vector3(_base_x, _focus.y + height_offset, _focus.z)

	# Always aim at the smoothed focus point
	look_at(_focus, Vector3.UP)

	# Smooth FOV
	fov = lerpf(fov, target_fov, lerp_speed * delta)

func _compute_bounds_from_death_box() -> void:
	var death_box := get_tree().get_first_node_in_group("death_zones") as Area3D
	if death_box == null:
		return

	var y_min := -INF
	var y_max :=  INF
	var z_min := -INF
	var z_max :=  INF

	for child in death_box.get_children():
		var shape_node := child as CollisionShape3D
		if shape_node == null:
			continue
		var box := shape_node.shape as BoxShape3D
		if box == null:
			continue

		var xform  := shape_node.global_transform
		var scale  := xform.basis.get_scale()
		var center := xform.origin
		var half   := (box.size * scale) * 0.5

		# Whichever axis is "thin" tells us which wall this is
		if box.size.y < box.size.x and box.size.y < box.size.z:
			# Horizontal wall (top/bottom blast zone)
			if center.y > 0.0:
				y_max = minf(y_max, center.y - half.y)
			else:
				y_min = maxf(y_min, center.y + half.y)
		elif box.size.z < box.size.x and box.size.z < box.size.y:
			# Vertical wall (left/right blast zone)
			if center.z > 0.0:
				z_max = minf(z_max, center.z - half.z)
			else:
				z_min = maxf(z_min, center.z + half.z)

	_bound_y_min = y_min + bounds_margin
	_bound_y_max = y_max - bounds_margin
	_bound_z     = minf(absf(z_min), absf(z_max)) - bounds_margin
