extends PanelContainer
class_name InventoryPanel
## Inventory UI panel — shows item grid with tooltips.

@onready var grid: GridContainer = $VBoxContainer/GridContainer
@onready var title_label: Label = $VBoxContainer/TitleLabel

var inventory: Inventory
var slot_buttons: Array[Button] = []

func _ready() -> void:
	title_label.text = "Inventory"
	visible = false

	# Create inventory instance
	inventory = Inventory.new()
	add_child(inventory)
	inventory.inventory_changed.connect(_refresh_slots)

	EventBus.ui_toggle_inventory.connect(toggle)

	_create_slots()

	# Give some starter items
	inventory.add_item({
		"id": "health_potion",
		"name": "Health Potion",
		"type": "consumable",
		"effect": "heal",
		"value": 30,
		"stackable": true,
		"quantity": 3,
	})

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle()

func toggle() -> void:
	visible = !visible

func _create_slots() -> void:
	for i in Inventory.MAX_SLOTS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(48, 48)
		btn.text = ""
		btn.tooltip_text = "Empty"
		var index := i
		btn.pressed.connect(func(): _on_slot_pressed(index))
		grid.add_child(btn)
		slot_buttons.append(btn)

func _refresh_slots() -> void:
	var items := inventory.get_all_items()
	for i in items.size():
		if i >= slot_buttons.size():
			break
		if items[i].is_empty():
			slot_buttons[i].text = ""
			slot_buttons[i].tooltip_text = "Empty"
		else:
			var qty: int = items[i].get("quantity", 1)
			var name: String = items[i].get("name", "???")
			slot_buttons[i].text = name.left(3)
			if qty > 1:
				slot_buttons[i].text += "\n" + str(qty)
			slot_buttons[i].tooltip_text = name + " (x" + str(qty) + ")"

func _on_slot_pressed(index: int) -> void:
	inventory.use_item(index)
