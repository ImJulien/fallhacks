extends Control

var windows = ['news', 'play', 'options']
@onready var play_window = $Windows/Margins/PlayWindow
@onready var options_window = $Windows/Margins/OptionsWindow
@onready var changelog_window = $Windows/Margins/ChangelogWindow

@onready var general_tab = $Windows/Margins/OptionsWindow/General
@onready var controls_tab = $Windows/Margins/OptionsWindow/Controls
@onready var display_tab = $Windows/Margins/OptionsWindow/Display

@export var selected_window = windows[0]

func _on_play_pressed():
	play_window.visible = true
	options_window.visible = false
	changelog_window.visible = false
	selected_window = windows[1]
	pass

func _on_options_pressed():
	play_window.visible = false
	options_window.visible = true
	changelog_window.visible = false
	selected_window = windows[2]
	pass

func _on_quit_pressed():
	get_tree().quit()
	

func _on_general_pressed():
	general_tab.visible = true
	controls_tab.visible = false
	display_tab.visible = false
	
func _on_controls_pressed():
	general_tab.visible = false
	controls_tab.visible = true
	display_tab.visible = false
	
func _on_display_pressed():
	general_tab.visible = false
	controls_tab.visible = false
	display_tab.visible = true

func _on_training_pressed():
	get_tree().change_scene_to_file('res://Scenes/main_game.tscn')
