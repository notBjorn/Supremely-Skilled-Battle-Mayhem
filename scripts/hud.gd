extends CanvasLayer

@onready var p1_percent: Label = $Control/P1Panel/VBox/PercentLabel
@onready var p2_percent: Label = $Control/P2Panel/VBox/PercentLabel
@onready var p1_lives_label: Label = $Control/P1Panel/VBox/LivesRow/LivesLabel
@onready var p2_lives_label: Label = $Control/P2Panel/VBox/LivesRow/LivesLabel
@onready var p1_stocks: HBoxContainer = $Control/P1Panel/VBox/LivesRow/Stocks
@onready var p2_stocks: HBoxContainer = $Control/P2Panel/VBox/LivesRow/Stocks

func update_percent(player: int, value: float) -> void:
	var label := p1_percent if player == 1 else p2_percent
	var safe_value := maxf(value, 0.0)
	label.text = "%d%%" % int(safe_value)
	var danger := clampf(safe_value / 150.0, 0.0, 1.0)
	label.add_theme_color_override("font_color", Color(1.0, lerpf(1.0, 0.35, danger), lerpf(1.0, 0.2, danger), 1.0))

func update_stocks(player: int, count: int) -> void:
	var container := p1_stocks if player == 1 else p2_stocks
	var lives_label := p1_lives_label if player == 1 else p2_lives_label
	var safe_count := mini(maxi(count, 0), container.get_child_count())
	lives_label.text = "Lives: %d" % safe_count
	for i in container.get_child_count():
		container.get_child(i).modulate.a = 1.0 if i < safe_count else 0.2
