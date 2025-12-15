extends CanvasLayer

# [CORE] Signal to send the selected upgrade name back to the player
signal upgrade_selected(upgrade_name: String)

# MUST match the constant defined in player.gd
const UPGRADE_IGNORE = "IGNORE_SELECTION" 

# Node Connections (Check paths in LevelUpMenu.tscn!)
@onready var title_label: Label = $Background/CenterContainer/VBoxContainer/TitleLabel
@onready var buttons_container: HBoxContainer = $Background/CenterContainer/VBoxContainer/HBoxContainer
@onready var choice_buttons: Array[Button] = [
	$Background/CenterContainer/VBoxContainer/HBoxContainer/ChoiceButton1, 
	$Background/CenterContainer/VBoxContainer/HBoxContainer/ChoiceButton2, 
	$Background/CenterContainer/VBoxContainer/HBoxContainer/ChoiceButton3
]
# [NEW] Ignore Button connection (Must be inside VBoxContainer)
@onready var ignore_button: Button = $Background/CenterContainer/VBoxContainer/IgnoreButton

# Stores the three upgrade names received from player.gd
var current_choices: Array 

func _ready():
	# [FIX] Force layer to be high so it always appears above the HUD (Layer 10)
	self.layer = 10
	
	# Show mouse cursor for UI interaction
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Initialize and Connect Choice Buttons
	for i in range(choice_buttons.size()):
		var button = choice_buttons[i]
		
		# Check if the node was found (prevents 'null instance' error)
		if is_instance_valid(button):
			button.pressed.connect(Callable(self, "_on_choice_button_pressed").bind(i))
			button.mouse_filter = Control.MOUSE_FILTER_STOP
			button.text = "CHOICE " + str(i + 1)
		else:
			print("ERROR: LevelUpMenu failed to find ChoiceButton", i + 1, " node. Check path!")
	
	# Initialize and Connect Ignore Button
	if is_instance_valid(ignore_button):
		ignore_button.text = "SKIP UPGRADE"
		ignore_button.pressed.connect(_on_ignore_button_pressed)
	else:
		print("ERROR: LevelUpMenu failed to find IgnoreButton node. Check path!")

	# Set Title Text
	if is_instance_valid(title_label):
		title_label.text = "LEVEL UP!"
	else:
		print("ERROR: LevelUpMenu failed to find TitleLabel node. Check path!")
	
	# [Reminder] Ensure the background ColorRect has Mouse Filter set to 'Ignore' in the editor!

# [NEW FUNCTION] Handle unhandled input events (like keyboard keys)
func _unhandled_input(event):
	# Check if the pressed key is the ESC key (or UI Cancel action)
	if event.is_action_pressed("ui_cancel"): 
		# Consume the event so it doesn't propagate further
		get_viewport().set_input_as_handled() 
		
		# Execute the ignore logic to close the menu and resume the game
		_on_ignore_button_pressed()
		return

# Function called by player.gd to set the text on the buttons
func set_choices(choices: Array): # [FIX] Accepts untyped Array
	if choices.size() != 3:
		print("WARNING: Number of choices is not 3!")
		return
	
	# Assigns untyped array to untyped variable
	current_choices = choices 
	
	for i in range(3):
		if i < choice_buttons.size() and is_instance_valid(choice_buttons[i]):
			choice_buttons[i].text = current_choices[i]

# Handler for the 3 main upgrade buttons
func _on_choice_button_pressed(index: int):
	print("DEBUG: Upgrade button pressed, index: ", index)
	
	if index >= 0 and index < current_choices.size():
		var selected_upgrade = current_choices[index]
		
		# [CORE] Send the selected upgrade signal to player.gd
		emit_signal("upgrade_selected", selected_upgrade)
		
		# Close menu
		queue_free()

# Handler for the new Ignore (Skip) button
func _on_ignore_button_pressed():
	print("DEBUG: Ignore button pressed. Skipping upgrade.")
	
	# [CORE] Send the IGNORE signal to player.gd
	emit_signal("upgrade_selected", UPGRADE_IGNORE)
	
	# Close menu (game resumes via player.gd's apply_upgrade function)
	queue_free()
