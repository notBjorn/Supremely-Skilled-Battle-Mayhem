extends Node3D

const MAX_STOCKS := 3

var p1_stocks := MAX_STOCKS
var p2_stocks := MAX_STOCKS
var p1_percent := 0.0
var p2_percent := 0.0

@onready var hud = $HUD

func _ready() -> void:
	hud.update_stocks(1, p1_stocks)
	hud.update_stocks(2, p2_stocks)
	hud.update_percent(1, p1_percent)
	hud.update_percent(2, p2_percent)

# Call from character script when a player takes dmg
func player_took_damage(player: int, amount: float) -> void:
	if player == 1:
		p1_percent += amount
		hud.update_percent(1, p1_percent)
	else:
		p2_percent += amount
		hud.update_percent(2, p2_percent)

# Call from the death zone when a player goes pas the blast zone
func player_died(player: int) -> void:
	if player == 1:
		p1_stocks -= 1
		p1_percent = 0.0
		hud.update_stocks(1, p1_stocks)
		hud.update_percent(1, p1_percent)
		if p1_stocks <= 0:
			_end_game(2)
	else:
		p2_stocks -= 1
		p2_percent = 0.0
		hud.update_stocks(2, p2_stocks)
		hud.update_percent(2, p2_percent)
		if p2_stocks <= 0:
			_end_game(1)

func _end_game(winner: int) -> void:
	GameState.winner = winner
	get_tree().change_scene_to_file("res://scenes/ResultsScreen.tscn")
