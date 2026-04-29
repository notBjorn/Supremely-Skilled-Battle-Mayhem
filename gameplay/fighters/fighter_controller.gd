extends CharacterBody3D

signal damaged(player_idx: int, new_percent: float)
signal died(player_idx: int)
signal respawned(player_idx: int)

const STATE_IDLE := "idle"
const STATE_JUMP := "jump"
const STATE_ATTACK := "attack"
const STATE_DAMAGE := "damage"
const STATE_SHIELD := "shield"

const ACTION_ATTACK := "attack"
const ACTION_SPECIAL := "special"
const ACTION_JUMP := "jump"
const ACTION_SHIELD := "shield"
const ACTION_DODGE := "dodge"

const STATE_COLORS := {
	STATE_IDLE: Color.WHITE,
	STATE_JUMP: Color.GREEN,
	STATE_ATTACK: Color.RED,
	STATE_DAMAGE: Color.PURPLE,
	STATE_SHIELD: Color.BLUE,
}

@export var player_label := "P1"
@export var move_left_action := "p1_move_left"
@export var move_right_action := "p1_move_right"
@export var jump_action := "p1_jump"
@export var down_action := "p1_down"
@export var attack_action := "p1_attack"
@export var special_action := "p1_special"
@export var shield_action := "p1_shield"
@export var dodge_action := "p1_dodge"

@export var run_speed := 7.0
@export var jump_velocity := 8.5
@export var gravity := 24.0
@export var weight := 1.0
@export var fall_speed_limit := 16.0
@export var spawn_position := Vector3.ZERO
@export var bounds_z := 19.0
@export var lower_death_y := -12.0
@export var upper_death_y := 12.0
@export var max_jumps := 2
@export var double_jump_velocity_scale := 0.95
@export var drop_through_duration := 0.3
@export var ground_layer_bit := 1
@export var platform_layer_bit := 2
@export var fighter_layer_bit := 4
@export var pushbox_layer_bit := 8
@export var pushbox_size := Vector3(0.55, 1.0, 0.55)
@export var push_speed_threshold := 4.0
@export var push_force := 8.0

@export var attack_damage := 7.0
@export var attack_duration := 0.36
@export var attack_active_time := 0.18
@export var attack_base_knockback := 7.0
@export var attack_knockback_scale := 0.11
@export var special_damage := 11.0
@export var special_duration := 0.55
@export var special_active_time := 0.22
@export var special_base_knockback := 9.0
@export var special_knockback_scale := 0.14
@export var damage_stun_duration := 0.28

var state := STATE_IDLE
var damage_percent := 0.0
var facing_z := 1.0
var action_lock_remaining := 0.0
var hitbox_active_remaining := 0.0
var queued_action := ""
var current_attack_damage := 0.0
var current_base_knockback := 0.0
var current_knockback_scale := 0.0
var hit_bodies := {}
var previous_action_states := {}
var input_event_count := 0
var last_input_action := ""
var last_started_action := ""
var jumps_used := 0
var drop_through_remaining := 0.0

var mesh_instance: MeshInstance3D
var state_material: StandardMaterial3D
var hitbox: Area3D
var hitbox_shape: CollisionShape3D
var pushbox: Area3D
var pushbox_shape: CollisionShape3D

func _ready() -> void:
	if spawn_position == Vector3.ZERO:
		spawn_position = global_position
	mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D
	state_material = StandardMaterial3D.new()
	if mesh_instance:
		mesh_instance.material_override = state_material
	_ensure_hitbox()
	_ensure_pushbox()
	collision_layer = fighter_layer_bit
	collision_mask = ground_layer_bit | platform_layer_bit
	_set_state(STATE_IDLE)
	add_to_group("fighters")

func _physics_process(delta: float) -> void:
	if _is_out_of_bounds():
		_respawn()
		if not is_inside_tree():
			return
	_check_drop_through_input()
	_tick_drop_through(delta)
	_update_collision_mask()
	_tick_action_locks(delta)
	if action_lock_remaining > 0.0:
		_queue_action_during_lock()
		_apply_gravity(delta)
		move_and_slide()
		_position_hitbox()
		return
	if not queued_action.is_empty():
		var next_action := queued_action
		queued_action = ""
		_start_action(next_action)
	elif not _try_start_new_action():
		_apply_movement(delta)
	_apply_gravity(delta)
	_apply_pushbox(delta)
	move_and_slide()
	_update_passive_state()
	_position_hitbox()

func get_damage_percent() -> float:
	return damage_percent

func take_damage(amount: float, knockback: Vector3) -> void:
	damage_percent += amount
	velocity = knockback / maxf(weight, 0.1)
	queued_action = ""
	action_lock_remaining = damage_stun_duration
	_disable_hitbox()
	_set_state(STATE_DAMAGE)
	damaged.emit(_player_index(), damage_percent)

func _input(event: InputEvent) -> void:
	input_event_count += 1
	var requested_action := _event_to_action(event)
	last_input_action = requested_action
	if requested_action.is_empty():
		return
	if action_lock_remaining > 0.0:
		if queued_action.is_empty():
			queued_action = requested_action
	else:
		_start_action(requested_action)

func _event_to_action(event: InputEvent) -> String:
	if event.is_action_pressed(attack_action):
		return ACTION_ATTACK
	if event.is_action_pressed(special_action):
		return ACTION_SPECIAL
	if event.is_action_pressed(dodge_action):
		return ACTION_DODGE
	if event.is_action_pressed(jump_action):
		return ACTION_JUMP
	if event.is_action_pressed(shield_action):
		return ACTION_SHIELD
	return ""

# Runtime-created hitbox keeps the scene file simple while still giving each fighter an attack volume.
func _ensure_hitbox() -> void:
	hitbox = get_node_or_null("Hitbox") as Area3D
	if hitbox == null:
		hitbox = Area3D.new()
		hitbox.name = "Hitbox"
		add_child(hitbox)
	hitbox.monitorable = false
	hitbox.monitoring = false
	hitbox.collision_mask = fighter_layer_bit
	if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
		hitbox.body_entered.connect(_on_hitbox_body_entered)
	hitbox_shape = hitbox.get_node_or_null("HitboxShape") as CollisionShape3D
	if hitbox_shape == null:
		hitbox_shape = CollisionShape3D.new()
		hitbox_shape.name = "HitboxShape"
		hitbox.add_child(hitbox_shape)
	var box := BoxShape3D.new()
	box.size = Vector3(0.65, 0.725, 0.525)
	hitbox_shape.shape = box
	hitbox_shape.disabled = true

func _try_start_new_action() -> bool:
	var requested_action := _read_action_input()
	if requested_action.is_empty():
		return false
	_start_action(requested_action)
	return true

func _read_action_input() -> String:
	var attack_pressed := _pressed_once(attack_action)
	var special_pressed := _pressed_once(special_action)
	var dodge_pressed := _pressed_once(dodge_action)
	var jump_pressed := _pressed_once(jump_action)
	if attack_pressed:
		return ACTION_ATTACK
	if special_pressed:
		return ACTION_SPECIAL
	if dodge_pressed:
		return ACTION_DODGE
	if jump_pressed:
		return ACTION_JUMP
	if Input.is_action_pressed(shield_action):
		return ACTION_SHIELD
	return ""

func _pressed_once(action_name: String) -> bool:
	var pressed := Input.is_action_pressed(action_name)
	var was_pressed := bool(previous_action_states.get(action_name, false))
	previous_action_states[action_name] = pressed
	return pressed and not was_pressed

func _start_action(action: String) -> void:
	last_started_action = action
	match action:
		ACTION_ATTACK:
			_start_attack(attack_damage, attack_duration, attack_active_time, attack_base_knockback, attack_knockback_scale)
		ACTION_SPECIAL:
			_start_attack(special_damage, special_duration, special_active_time, special_base_knockback, special_knockback_scale)
		ACTION_JUMP:
			_try_jump()
			_set_state(STATE_JUMP)
		ACTION_SHIELD:
			if is_on_floor():
				velocity.z = 0.0
				_set_state(STATE_SHIELD)
		ACTION_DODGE:
			velocity.z = facing_z * run_speed * 1.4
			action_lock_remaining = 0.25
			_set_state(STATE_SHIELD)

func _start_attack(damage: float, duration: float, active_time: float, base_knockback: float, knockback_scale: float) -> void:
	velocity.z = 0.0
	action_lock_remaining = duration
	hitbox_active_remaining = active_time
	current_attack_damage = damage
	current_base_knockback = base_knockback
	current_knockback_scale = knockback_scale
	hit_bodies.clear()
	_position_hitbox()
	_set_hitbox_enabled(true)
	_set_state(STATE_ATTACK)

# This is the input queue: one action can buffer while the current locked action finishes.
func _queue_action_during_lock() -> void:
	if not queued_action.is_empty():
		return
	var requested_action := _read_action_input()
	if not requested_action.is_empty():
		queued_action = requested_action

func _tick_action_locks(delta: float) -> void:
	var was_locked := action_lock_remaining > 0.0
	if action_lock_remaining > 0.0:
		action_lock_remaining = maxf(action_lock_remaining - delta, 0.0)
	if hitbox_active_remaining > 0.0:
		hitbox_active_remaining = maxf(hitbox_active_remaining - delta, 0.0)
		if hitbox_active_remaining == 0.0:
			_disable_hitbox()
	if was_locked and action_lock_remaining == 0.0:
		_finish_locked_action()

func _finish_locked_action() -> void:
	_disable_hitbox()
	if not queued_action.is_empty():
		return
	_set_state(STATE_JUMP if not is_on_floor() else STATE_IDLE)

func _apply_movement(delta: float) -> void:
	var direction := Input.get_axis(move_right_action, move_left_action)
	if direction != 0.0:
		facing_z = signf(direction)
	velocity.z = move_toward(velocity.z, direction * run_speed, run_speed * 8.0 * delta)
	if Input.is_action_pressed(down_action) and is_on_floor():
		velocity.z = move_toward(velocity.z, 0.0, run_speed * 12.0 * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = maxf(velocity.y - gravity * delta, -fall_speed_limit)
	else:
		if velocity.y < 0.0:
			velocity.y = 0.0
		jumps_used = 0

func _try_jump() -> bool:
	if jumps_used >= max_jumps:
		return false
	var scale_factor := 1.0 if jumps_used == 0 else double_jump_velocity_scale
	velocity.y = jump_velocity * scale_factor
	jumps_used += 1
	return true

func _check_drop_through_input() -> void:
	if _pressed_once(down_action) and is_on_floor():
		drop_through_remaining = drop_through_duration

func _tick_drop_through(delta: float) -> void:
	if drop_through_remaining > 0.0:
		drop_through_remaining = maxf(drop_through_remaining - delta, 0.0)

func _update_collision_mask() -> void:
	var pass_through := drop_through_remaining > 0.0 or velocity.y > 0.01
	collision_mask = ground_layer_bit if pass_through else (ground_layer_bit | platform_layer_bit)

func _update_passive_state() -> void:
	if action_lock_remaining > 0.0:
		return
	if Input.is_action_pressed(shield_action) and is_on_floor():
		_set_state(STATE_SHIELD)
	elif not is_on_floor():
		_set_state(STATE_JUMP)
	else:
		_set_state(STATE_IDLE)

func _position_hitbox() -> void:
	if hitbox == null:
		return
	hitbox.position = Vector3(0.0, 0.1, facing_z * 0.475)

func _set_hitbox_enabled(enabled: bool) -> void:
	if hitbox == null or hitbox_shape == null:
		return
	hitbox.monitoring = enabled
	hitbox_shape.disabled = not enabled

func _disable_hitbox() -> void:
	hitbox_active_remaining = 0.0
	_set_hitbox_enabled(false)

func _ensure_pushbox() -> void:
	pushbox = get_node_or_null("Pushbox") as Area3D
	if pushbox == null:
		pushbox = Area3D.new()
		pushbox.name = "Pushbox"
		add_child(pushbox)
	pushbox.collision_layer = pushbox_layer_bit
	pushbox.collision_mask = pushbox_layer_bit
	pushbox.monitorable = true
	pushbox.monitoring = true
	pushbox_shape = pushbox.get_node_or_null("PushboxShape") as CollisionShape3D
	if pushbox_shape == null:
		pushbox_shape = CollisionShape3D.new()
		pushbox_shape.name = "PushboxShape"
		pushbox.add_child(pushbox_shape)
	var box := BoxShape3D.new()
	box.size = pushbox_size
	pushbox_shape.shape = box

# Melee-style soft push: fighters phase through each other, but slow grounded
# overlaps get a gentle separation nudge. High relative speed = clean pass-through.
func _apply_pushbox(delta: float) -> void:
	if pushbox == null:
		return
	if state == STATE_ATTACK or state == STATE_DAMAGE:
		return
	if not is_on_floor():
		return
	for area in pushbox.get_overlapping_areas():
		var other := area.get_parent()
		if other == null or other == self:
			continue
		if not other.is_in_group("fighters"):
			continue
		if not other.is_on_floor():
			continue
		if other.state == STATE_ATTACK or other.state == STATE_DAMAGE:
			continue
		if absf(velocity.z - other.velocity.z) > push_speed_threshold:
			continue
		var direction := signf(global_position.z - other.global_position.z)
		if direction == 0.0:
			direction = 1.0 if _player_index() < other._player_index() else -1.0
		velocity.z += direction * push_force * delta

func _on_hitbox_body_entered(body: Node3D) -> void:
	if body == self or hit_bodies.has(body):
		return
	if not body.has_method("take_damage"):
		return
	hit_bodies[body] = true
	var target_damage := 0.0
	if body.has_method("get_damage_percent"):
		target_damage = body.get_damage_percent()
	# Use post-hit percent so the HUD number directly tracks knockback risk.
	var resulting_damage := target_damage + current_attack_damage
	var knockback_strength := current_base_knockback + resulting_damage * current_knockback_scale
	body.take_damage(current_attack_damage, Vector3(0.0, knockback_strength * 0.45, facing_z * knockback_strength))

func _set_state(next_state: String) -> void:
	state = next_state
	if state_material:
		state_material.albedo_color = STATE_COLORS.get(state, Color.WHITE)

func _is_out_of_bounds() -> bool:
	return global_position.y < lower_death_y or global_position.y > upper_death_y or absf(global_position.z) > bounds_z

func _player_index() -> int:
	return 2 if player_label == "P2" else 1

func _respawn() -> void:
	died.emit(_player_index())
	if not is_inside_tree():
		return
	global_position = spawn_position
	velocity = Vector3.ZERO
	damage_percent = 0.0
	action_lock_remaining = 0.0
	queued_action = ""
	jumps_used = 0
	drop_through_remaining = 0.0
	_disable_hitbox()
	_set_state(STATE_IDLE)
	respawned.emit(_player_index())
