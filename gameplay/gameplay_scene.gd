extends Node3D

const MAX_STOCKS := 4

var p1_stocks := MAX_STOCKS
var p2_stocks := MAX_STOCKS
var game_over := false
var stock_loss_locked := {
	1: false,
	2: false,
}

@onready var hud = $HUD

func _ready() -> void:
	hud.update_stocks(1, p1_stocks)
	hud.update_stocks(2, p2_stocks)
	hud.update_percent(1, 0.0)
	hud.update_percent(2, 0.0)
	for fighter in get_tree().get_nodes_in_group("fighters"):
		fighter.damaged.connect(_on_fighter_damaged)
		fighter.died.connect(_on_fighter_died)
		fighter.respawned.connect(_on_fighter_respawned)

func _on_fighter_damaged(player_idx: int, new_percent: float) -> void:
	hud.update_percent(player_idx, new_percent)

func _on_fighter_died(player_idx: int) -> void:
	if game_over or bool(stock_loss_locked.get(player_idx, false)):
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

func _end_game(winner: int) -> void:
	if game_over:
		return
	game_over = true
	GameState.winner = winner
	get_tree().change_scene_to_file("res://menus/results_screen.tscn")
