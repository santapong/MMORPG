# Pixel Grinder — Development Plan

## Current Focus: Enhancement System for Armor & Weapon

### Goals
Flesh out the enhancement experience so it feels rewarding and strategic — not just a button press with RNG. This is the core gear progression loop.

### Enhancement System Improvements

#### 1. Enhancement Visual Feedback
- [ ] Glow/particle effect on enhanced items (+5 green, +10 blue, +15 purple, +20 orange)
- [ ] Screen shake and flash on success/failure
- [ ] Enhancement level shown on equipment sprite (aura overlay)
- [ ] Sound cues: distinct sounds for attempt, success, failure, and downgrade

#### 2. Enhancement Material Requirements
- [ ] Black Stone (Weapon) required for weapon enhancement
- [ ] Black Stone (Armor) required for body/helmet/gloves/boots
- [ ] Concentrated Black Stone for +16 and above (rare drop only)
- [ ] Material cost scales with enhancement level (1 stone for +1–10, 2 for +11–15, 3 for +16–20)
- [ ] Integrate with existing drop tables (stones already drop from mobs)

#### 3. Cron Stones — Downgrade Protection
- [ ] Add Cron Stones as a new material (purchasable with silver or rare drop)
- [ ] Spending Cron Stones prevents enhancement level downgrade on failure (+16 and above)
- [ ] Cron Stone cost scales with current enhance level and gear grade
- [ ] UI toggle: "Use Cron Stones" checkbox in enhancement panel

#### 4. Forced Enhancement (+16 to +20)
- [ ] At +15, enhancement name changes: PRI (+16), DUO (+17), TRI (+18), TET (+19), PEN (+20)
- [ ] Failed PRI–PEN drops enhancement by 1 level (unless Cron protected)
- [ ] Failstacks become critical strategy at this tier
- [ ] Add "Advice of Valks" item to set failstacks to a fixed value

#### 5. Enhancement UI Overhaul
- [ ] Show item stats before/after enhancement preview
- [ ] Display grade color and grade name in enhancement panel
- [ ] History log: last 10 enhancement attempts (success/fail/level)
- [ ] Failstack recommendation guide (optimal failstack ranges per level)
- [ ] Material inventory count shown inline

#### 6. Weapon vs Armor Differentiation
- [ ] Weapons gain primarily attack + crit per enhance level
- [ ] Body/Helmet gain primarily defense + max_hp per enhance level
- [ ] Gloves gain attack + crit_chance per enhance level
- [ ] Boots gain defense + speed per enhance level
- [ ] Rings/Necklaces gain mixed stats per enhance level
- [ ] Grade multiplier affects enhancement gains (Legendary gets bigger bonuses)

#### 7. Equipment Comparison
- [ ] Side-by-side comparison when equipping new gear
- [ ] Green/red stat delta indicators ("+5 ATK", "-3 DEF")
- [ ] "Would you like to equip?" confirmation with stat preview

---

## Next Phase: Map & World Design

### Goals
Design the game world with interconnected zones, navigation, and visual identity.

#### Zone Layout
- [ ] Redesign world map with natural zone transitions (paths, bridges, gates)
- [ ] Add transition areas between zones (loading boundaries)
- [ ] Each zone gets a distinct tileset and color palette
- [ ] Safe zone boundaries clearly marked

#### Zone Content
- [ ] Zone-specific environmental hazards (lava in Demon Rift, ice in Cursed Ruins)
- [ ] Hidden areas / secret paths with bonus mob spawns
- [ ] Zone boss spawn points (timed respawn, high reward)
- [ ] Resource gathering nodes per zone (future crafting prep)

#### Navigation
- [ ] Improved minimap with fog of war (reveal as explored)
- [ ] NPC quest markers on world map
- [ ] Auto-path to waypoint system
- [ ] Zone recommended level warning on entry

#### Visual Design
- [ ] Starter Village: warm green tiles, wooden buildings, peaceful
- [ ] Slime Fields: open grasslands, slime pools, bright colors
- [ ] Wolf Forest: dense trees, dark green, undergrowth
- [ ] Bandit Camp: wooden fortifications, campfires, tents
- [ ] Cursed Ruins: dark stone, broken columns, eerie purple glow
- [ ] Demon Rift: volcanic rock, lava streams, red/black sky

---

## Future Phases (Backlog)

### Phase 3: Crafting & Economy
- [ ] Crafting system using mob drops
- [ ] Marketplace / Auction House (player-to-player trading)
- [ ] NPC shops with level-gated inventory
- [ ] Silver sinks: repair costs, fast travel fees, storage expansion

### Phase 4: Party System & Social
- [ ] Party formation (up to 4 players)
- [ ] Shared XP and loot distribution
- [ ] Party-only grinding zones / dungeons
- [ ] Guild system basics

### Phase 5: Boss & Dungeon Content
- [ ] World bosses with unique mechanics
- [ ] Instanced dungeons (3-player)
- [ ] Boss loot tables with exclusive gear
- [ ] Weekly reset timers on boss rewards
