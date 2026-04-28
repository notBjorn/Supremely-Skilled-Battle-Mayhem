extends CanvasLayer

@onready var p1_percent: Label = $Control/P1Panel/VBox/PercentLabel
@onready var p2_percent: Label = $Control/P2Panel/VBox/PercentLabel
@onready var p1_stocks: HBoxContainer = $Control/P1Panel/VBox/Stocks
@onready var p2_stocks: HBoxContainer = $Control/P2Panel/VBox/Stocks

func update_percent(player: int, value: float) -> void:
	var label := p1_percent if player == 1 else p2_percent
	label.text = "%d%%" % int(value)

func update_stocks(player: int, count: int) -> void:
	var container := p1_stocks if player == 1 else p2_stocks
	for i in container.get_child_count():
		container.get_child(i).modulate.a = 1.0 if i < count else 0.2
