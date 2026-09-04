#!/usr/bin/env bash
# Launch Pixel Grinder with the shared Godot in /mnt/data/games.
# Pass --editor to open the Godot editor instead of playing.
GODOT=/mnt/data/games/godot/godot
PROJECT=/mnt/data/games/MMORPG/godot_project

if [[ "$1" == "--editor" ]]; then
    exec "$GODOT" --path "$PROJECT" -e
fi
exec "$GODOT" --path "$PROJECT"
