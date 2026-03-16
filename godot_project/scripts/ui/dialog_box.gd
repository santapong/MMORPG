extends PanelContainer
class_name DialogBox
## NPC dialog display box.

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var text_label: RichTextLabel = $VBoxContainer/TextLabel
@onready var continue_button: Button = $VBoxContainer/ContinueButton

func _ready() -> void:
	visible = false
	continue_button.pressed.connect(_on_continue)
	EventBus.ui_show_dialog.connect(show_dialog)

func show_dialog(npc_name: String, dialog_text: String, _options: Array) -> void:
	name_label.text = npc_name
	text_label.text = dialog_text
	visible = true

func _on_continue() -> void:
	visible = false
