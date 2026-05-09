extends Node3D

var p1_stocks := 0
var p2_stocks := 0
var game_over := false
var stock_loss_locked := {
	1: false,
	2: false,
}

# Timer mode tracking
var time_remaining: float = 0.0
var p1_deaths: int = 0
var p2_deaths: int = 0
var p1_total_damage: float = 0.0
var p2_total_damage: float = 0.0

@onready var hud = $HUD

func _ready() -> void:
	if GameState.game_mode == "timer":
		time_remaining = GameState.timer_minutes * 60.0
		hud.setup("timer", 0)
		hud.update_timer(int(time_remaining))
		hud.update_percent(1, 0.0)
		hud.update_percent(2, 0.0)
	else:
		p1_stocks = GameState.stock_count
		p2_stocks = GameState.stock_count
		hud.setup("stock", GameState.stock_count)
		hud.update_stocks(1, p1_stocks)
		hud.update_stocks(2, p2_stocks)
		hud.update_percent(1, 0.0)
		hud.update_percent(2, 0.0)
	for fighter in get_tree().get_nodes_in_group("fighters"):
		fighter.damaged.connect(_on_fighter_damaged)
		fighter.died.connect(_on_fighter_died)
		fighter.respawned.connect(_on_fighter_respawned)
	for zone in get_tree().get_nodes_in_group("death_zones"):
		zone.body_entered.connect(_on_death_zone_body_entered)

func _process(delta: float) -> void:
	if GameState.game_mode == "timer" and not game_over:
		time_remaining = maxf(time_remaining - delta, 0.0)
		hud.update_timer(int(time_remaining))
		if time_remaining == 0.0:
			_end_timer_game()

func _on_fighter_damaged(player_idx: int, new_percent: float) -> void:
	hud.update_percent(player_idx, new_percent)
	if GameState.game_mode == "timer":
		if player_idx == 1:
			p1_total_damage = new_percent
		else:
			p2_total_damage = new_percent

func _on_fighter_died(player_idx: int) -> void:
	if game_over:
		return
	if GameState.game_mode == "timer":
		if player_idx == 1:
			p1_deaths += 1
		else:
			p2_deaths += 1
		return
	if bool(stock_loss_locked.get(player_idx, false)):
		return
	stock_loss_locked[player_idx] = true
	if player_idx == 1:
		p1_stocks = maxi(p1_stocks - 1, 0)
		hud.update_stocks(1, p1_stocks)
		hud.update_percent(1, 0.0)
		if p1_stocks <= 0:
			_end_game(2)
	else:
		p2_stocks = maxi(p2_stocks - 1, 0)
		hud.update_stocks(2, p2_stocks)
		hud.update_percent(2, 0.0)
		if p2_stocks <= 0:
			_end_game(1)

func _on_fighter_respawned(player_idx: int) -> void:
	stock_loss_locked[player_idx] = false

func _on_death_zone_body_entered(body: Node3D) -> void:
	if body.is_in_group("fighters") and body.has_method("kill"):
		body.kill()

func _end_timer_game() -> void:
	if game_over:
		return
	game_over = true
	var winner: int
	if p1_deaths < p2_deaths:
		winner = 1
	elif p2_deaths < p1_deaths:
		winner = 2
	elif p1_total_damage <= p2_total_damage:
		winner = 1
	else:
		winner = 2
	GameState.winner = winner
	get_tree().change_scene_to_file("res://menus/results_screen.tscn")

func _end_game(winner: int) -> void:
	if game_over:
		return
	game_over = true
	GameState.winner = winner
	get_tree().change_scene_to_file("res://menus/results_screen.tscn")
