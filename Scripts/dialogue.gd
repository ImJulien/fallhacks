extends Node

signal dialogue_finished()

@onready var dialogue_label: RichTextLabel = null
var is_typing: bool = false
var text_speed: float = 0.02  #time for scroll characters

#dialogue for each monster and emotion level
var monster_dialogues = {
	Enums.Customers.GORT: {
		Enums.AggressionLevel.PASSIVE: "Oh, hello there! Welcome to our little shop. How can I help you today?",
		Enums.AggressionLevel.IRRITATED: "Hi... Look, I'm trying to help here, but you need to pay attention.",
		Enums.AggressionLevel.AGITATED: "Seriously? Come on, focus! This isn't that complicated.",
		Enums.AggressionLevel.AGGRESSIVE: "What is WRONG with you?! Just listen to what I'm saying!",
		Enums.AggressionLevel.VIOLENT: "I'VE HAD IT! You're driving me absolutely INSANE!",
		Enums.AggressionLevel.HOSTILE: "GET OUT! GET OUT RIGHT NOW! I can't deal with this anymore!"
	},
	Enums.Customers.GORTICIA: {
		Enums.AggressionLevel.PASSIVE: "Hello darling! What a lovely day to shop, don't you think?",
		Enums.AggressionLevel.IRRITATED: "Sweetie, you really need to listen more carefully...",
		Enums.AggressionLevel.AGITATED: "Oh my goodness, this is getting quite frustrating!",
		Enums.AggressionLevel.AGGRESSIVE: "I can't believe how incompetent this service is!",
		Enums.AggressionLevel.VIOLENT: "This is absolutely RIDICULOUS! I demand better!",
		Enums.AggressionLevel.HOSTILE: "That's IT! I'm never coming back to this horrible place!"
	}
}

func setup_ui():
	print("Setting up dialogue UI...")
	var scene_name = "NONE"
	if get_tree().current_scene:
		scene_name = get_tree().current_scene.name
	print("Current scene: ", scene_name)
	dialogue_label = find_dialogue_text_recursive(get_tree().current_scene) #find the DialogueText node in current scene
	if dialogue_label:
		print("Found DialogueText successfully!")
	else:
		print("WARNING: DialogueText not found in scene!")

func start_dialogue(aggression: Enums.AggressionLevel = Enums.AggressionLevel.PASSIVE, monster: Enums.Customers = Enums.Customers.GORT):
	var monster_texts = monster_dialogues.get(monster, {})
	var text = monster_texts.get(aggression, "...")
	
	#try to find dialogue_label if we don't have it (in case of scene transition)
	if not dialogue_label:
		print("DialogueText not found, searching again...")
		setup_ui()
	
	if dialogue_label:
		print("Found DialogueText, showing dialogue: ", text)
		dialogue_label.visible = true
		type_text(text)
	else:
		print("ERROR: Could not find DialogueText node!")

func type_text(text: String):
	is_typing = true
	
	#load text first but make it invisible
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	
	#reveal characters one by one
	for i in range(text.length() + 1):
		dialogue_label.visible_characters = i
		await get_tree().create_timer(text_speed).timeout
	
	is_typing = false
	print("Dialogue finished typing")
	dialogue_finished.emit()

func hide_dialogue():
	if dialogue_label:
		dialogue_label.visible = false

func find_dialogue_text_recursive(node: Node) -> RichTextLabel:
	if node.name == "DialogueText" and node is RichTextLabel:
		return node
	
	for child in node.get_children():
		var result = find_dialogue_text_recursive(child)
		if result:
			return result
	
	return null
