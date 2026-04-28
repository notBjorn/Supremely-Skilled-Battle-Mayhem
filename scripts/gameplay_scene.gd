extends Node3D

const MAX_STOCKS := 3

var p1_stocks := MAX_STOCKS
var p2_stocks := MAX_STOCKS

@onready var hud = $HUD

func _ready() -> void:
	hud.update_stocks(1, p1_stocks)
	hud.update_stocks(2, p2_stocks)
	hud.update_percent(1, 0.0)
	hud.update_percent(2, 0.0)
	for fighter in get_tree().get_nodes_in_group("fighters"):
		fighter.damaged.connect(_on_fighter_damaged)
		fighter.died.connect(_on_fighter_died)

func _on_fighter_damaged(player_idx: int, new_percent: float) -> void:
	hud.update_percent(player_idx, new_percent)

func _on_fighter_died(player_idx: int) -> void:
	if player_idx == 1:
		p1_stocks -= 1
		hud.update_stocks(1, p1_stocks)
		hud.update_percent(1, 0.0)
		if p1_stocks <= 0:
			_end_game(2)
	else:
		p2_stocks -= 1
		hud.update_stocks(2, p2_stocks)
		hud.update_percent(2, 0.0)
		if p2_stocks <= 0:
			_end_game(1)

func _end_game(winner: int) -> void:
	GameState.winner = winner
	get_tree().change_scene_to_file("res://scenes/ResultsScreen.tscn")
