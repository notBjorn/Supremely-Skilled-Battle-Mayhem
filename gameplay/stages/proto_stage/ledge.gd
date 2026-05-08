class_name Ledge
extends Area3D

# How long the fighter is invincible while on ledge.
@export var hang_invincibility := 1.5

# Path to the Marker3D ie where the player will snap to.
@export var hang_marker_path: NodePath = "HangPosition"

# who is on ledge
var current_occupant: Node = null

var _hang_marker: Marker3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_hang_marker = get_node_or_null(hang_marker_path) as Marker3D
	body_entered.connect(_on_body_entered)

# When body enters the ledge and it satisfies the grab conditions, 
# we call the enter ledge grab function in fighter_controller.gd.
# We pass the ledge itself as the object
func _on_body_entered(body: Node) -> void:
	if not _can_grab(body): 
		return
	current_occupant = body
	body.enter_ledge_grab(self)

func _can_grab(body: Node) -> bool:
	if current_occupant != null:
		return false                              # hogged — second player can't grab
	if not body.is_in_group("fighters"):
		return false
	if body.is_on_floor():
		return false                              # must be airborne 
	if body.velocity.y > 0.0 and body.global_position.y > global_position.y:
		return false   # rising AND above the ledge → jumping over from on stage                           
	if body.ledge_grab_cooldown_remaining > 0.0:
		return false                              # just released, can't regrab yet
	if not _is_facing_ledge(body):
		return false
	return true

func _is_facing_ledge(body: Node) -> bool:
	var direction_to_ledge := signf(global_position.z - body.global_position.z)
	if direction_to_ledge == 0.0:
		return true                               # right on top of ledge — allow either facing
	return direction_to_ledge == body.facing_z

# Called from fighter, when a player wants to release the ledge
func release(body: Node) -> void:
	if current_occupant == body: # check if current occupant is the one desireing to release the ledge
		current_occupant = null


func get_hang_position() -> Vector3:
	return _hang_marker.global_position if _hang_marker else global_position
# -----------------------







	
   
