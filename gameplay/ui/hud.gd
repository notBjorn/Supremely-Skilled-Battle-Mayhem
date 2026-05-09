extends CanvasLayer

@onready var p1_percent: Label = $Control/P1Panel/VBox/PercentLabel
@onready var p2_percent: Label = $Control/P2Panel/VBox/PercentLabel
@onready var p1_stocks_container: HBoxContainer = $Control/P1Panel/VBox/LivesRow/Stocks
@onready var p2_stocks_container: HBoxContainer = $Control/P2Panel/VBox/LivesRow/Stocks
@onready var timer_panel: PanelContainer = $Control/TimerPanel
@onready var timer_label: Label = $Control/TimerPanel/TimerLabel

var _use_blocks := true
var _max_stocks := 3

func setup(mode: String, stock_count: int) -> void:
	if mode == "timer":
		timer_panel.visible = true
		_clear_stock_icons(p1_stocks_container)
		_clear_stock_icons(p2_stocks_container)
	else:
		timer_panel.visible = false
		_max_stocks = stock_count
		_use_blocks = stock_count <= 5
		_build_stock_icons(p1_stocks_container, stock_count, Color(0.3, 0.65, 1.0, 1))
		_build_stock_icons(p2_stocks_container, stock_count, Color(1.0, 0.35, 0.35, 1))

func _clear_stock_icons(container: HBoxContainer) -> void:
	for child in container.get_children():
		child.queue_free()

func _build_stock_icons(container: HBoxContainer, count: int, color: Color) -> void:
	_clear_stock_icons(container)
	if _use_blocks:
		for i in count:
			var rect := ColorRect.new()
			rect.custom_minimum_size = Vector2(22, 22)
			rect.color = color
			container.add_child(rect)
	else:
		# Melee style: one icon + ×N label
		var rect := ColorRect.new()
		rect.custom_minimum_size = Vector2(22, 22)
		rect.color = color
		container.add_child(rect)
		var lbl := Label.new()
		lbl.name = "CountLabel"
		lbl.text = "×%d" % count
		lbl.add_theme_font_size_override("font_size", 18)
		container.add_child(lbl)

func update_percent(player: int, value: float) -> void:
	var label := p1_percent if player == 1 else p2_percent
	var safe_value := maxf(value, 0.0)
	label.text = "%d%%" % int(safe_value)
	var danger := clampf(safe_value / 150.0, 0.0, 1.0)
	label.add_theme_color_override("font_color", Color(1.0, lerpf(1.0, 0.35, danger), lerpf(1.0, 0.2, danger), 1.0))

func update_stocks(player: int, count: int) -> void:
	var container := p1_stocks_container if player == 1 else p2_stocks_container
	if _use_blocks:
		var child_count := container.get_child_count()
		for i in child_count:
			container.get_child(i).modulate.a = 1.0 if i < count else 0.2
	else:
		# Melee style: dim the single block when out, update count label
		if container.get_child_count() >= 1:
			container.get_child(0).modulate.a = 1.0 if count > 0 else 0.2
		var count_label := container.get_node_or_null("CountLabel") as Label
		if count_label:
			count_label.text = "×%d" % count

func update_timer(seconds: int) -> void:
	var mins := seconds / 60
	var secs := seconds % 60
	timer_label.text = "%d:%02d" % [mins, secs]
