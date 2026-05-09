extends Control

@onready var stock_button: Button = $CenterContainer/VBox/ModeRow/StockButton
@onready var timer_button: Button = $CenterContainer/VBox/ModeRow/TimerButton
@onready var stock_options: HBoxContainer = $CenterContainer/VBox/StockOptions
@onready var timer_options: HBoxContainer = $CenterContainer/VBox/TimerOptions
@onready var stock_count_label: Label = $CenterContainer/VBox/StockOptions/StockCount
@onready var timer_count_label: Label = $CenterContainer/VBox/TimerOptions/TimerCount

func _ready() -> void:
	stock_count_label.text = str(GameState.stock_count)
	timer_count_label.text = "%d min" % GameState.timer_minutes
	_apply_mode(GameState.game_mode)

func _apply_mode(mode: String) -> void:
	GameState.game_mode = mode
	stock_options.visible = (mode == "stock")
	timer_options.visible = (mode == "timer")
	stock_button.modulate = Color.WHITE if mode == "stock" else Color(0.5, 0.5, 0.5, 1.0)
	timer_button.modulate = Color.WHITE if mode == "timer" else Color(0.5, 0.5, 0.5, 1.0)

func _on_stock_button_pressed() -> void:
	_apply_mode("stock")

func _on_timer_button_pressed() -> void:
	_apply_mode("timer")

func _on_stock_minus_pressed() -> void:
	GameState.stock_count = maxi(GameState.stock_count - 1, 1)
	stock_count_label.text = str(GameState.stock_count)

func _on_stock_plus_pressed() -> void:
	GameState.stock_count = mini(GameState.stock_count + 1, 99)
	stock_count_label.text = str(GameState.stock_count)

func _on_timer_minus_pressed() -> void:
	GameState.timer_minutes = maxi(GameState.timer_minutes - 1, 1)
	timer_count_label.text = "%d min" % GameState.timer_minutes

func _on_timer_plus_pressed() -> void:
	GameState.timer_minutes = mini(GameState.timer_minutes + 1, 10)
	timer_count_label.text = "%d min" % GameState.timer_minutes

func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")
