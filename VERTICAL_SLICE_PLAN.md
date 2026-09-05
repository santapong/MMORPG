# Pixel Grinder Offline Vertical Slice

## Finish line

A new Warrior, Mage, or Ranger can complete a coherent 10-15 minute loop in one session:

1. accept **The Slime Crown** from Elder Gorn;
2. travel from Starter Village to Slime Fields;
3. defeat five slimes and receive a class weapon, Black Stones, and silver;
4. equip and enhance the sword;
5. defeat the Slime King in its marked arena;
6. return to Elder Gorn, receive the reward, and retain progress after reload.

## Included

- Offline single-player path using the existing movement, combat, inventory,
  equipment, enhancement, HUD, NPC, and save systems.
- One guided quest card with explicit current objective and progress.
- One combat zone and one non-respawning boss encounter.
- Reliable equipment use from the inventory.
- Quest progress in character save data.
- Godot 4.7.1 parse and startup validation.

## Excluded

- New currencies, crafting, auction house, multiplayer, guilds, PvP, dungeons,
  live operations, additional classes, additional zones, or an art-asset pass.
- Any claim that the whole MMORPG roadmap is complete.

## Acceptance

- [x] A fresh Warrior reaches the world without parser/runtime errors.
- [x] Elder Gorn starts the quest and the objective card advances.
- [x] Exactly five slime-family kills grant the guaranteed equipment package.
- [x] Clicking the Wooden Sword in inventory equips it without duplicating it.
- [x] A successful +1 enhancement spawns one Slime King and its arena.
- [x] The Slime King does not respawn after defeat.
- [x] Returning to Elder Gorn completes the quest and saves the state.
- [x] Reloading a character preserves quest, inventory, equipment, and enhancement.
- [x] Warrior, Mage, and Ranger each receive and enhance their matching weapon.
- [x] Every class has a distinct basic attack, combo curve, and stamina dodge.
- [x] A Crowned Slime elite and class-linked loot trait deepen the field encounter.

Validated headlessly with Godot 4.7.1 on 2026-09-05. A final hands-on feel pass
is still recommended before tagging because combat timing and camera feel are
player-experience judgments, not state-machine assertions.
