extends Node
## Global event bus for decoupled communication between systems.

# Player events
signal player_spawned(player_id: int, position: Vector2)
signal player_died(player_id: int)
signal player_respawned(player_id: int)
signal player_level_up(player_id: int, new_level: int)
signal player_health_changed(player_id: int, current_hp: int, max_hp: int)
signal player_mana_changed(player_id: int, current_mp: int, max_mp: int)
signal player_exp_changed(player_id: int, current_exp: int, exp_to_level: int)

# Combat events
signal damage_dealt(attacker_id: int, target_id: int, amount: int)
signal entity_died(entity_id: int)

# Chat events
signal chat_message_received(sender_name: String, message: String, channel: String)
signal chat_message_sent(message: String, channel: String)

# Inventory events
signal item_picked_up(item_data: Dictionary)
signal item_dropped(item_data: Dictionary)
signal item_used(item_data: Dictionary)
signal inventory_updated()

# NPC events
signal npc_interaction_started(npc_id: int, npc_name: String)
signal npc_interaction_ended(npc_id: int)
signal quest_accepted(quest_id: int)
signal quest_completed(quest_id: int)

# Network events
signal connected_to_server()
signal disconnected_from_server()
signal player_joined(player_id: int, player_name: String)
signal player_left(player_id: int)

# UI events
signal ui_toggle_inventory()
signal ui_show_dialog(npc_name: String, dialog_text: String, options: Array)
