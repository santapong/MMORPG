# Pixel Grinder — Development Roadmap

> Gameplay-first development. Every phase should make the game more fun to play.

---

## Completed

### v0.1 — Core Systems
- [x] 3 classes: Warrior, Mage, Ranger with unique stats
- [x] Leveling with XP scaling, 14 enemy types across 6 zones
- [x] Basic enhancement (+0 to +20) with failstacks
- [x] 7 equipment slots, inventory (20 slots), silver economy
- [x] Combat with crits, ENet multiplayer, full UI suite

### v0.2 — Maps & Navigation
- [x] World map with 6 grinding zones, minimap, zone indicator
- [x] Waypoint navigation system

### v0.3 — Skill Trees & Equipment Database
- [x] 27 skills (3 classes x 3 branches x 3 tiers), passive & buff skills
- [x] 40+ equipment items with 5 grades, class restrictions, level requirements
- [x] Gear score system

### v0.4 — Enhancement System Overhaul
- [x] Material requirements: Black Stones, Concentrated Black Stones
- [x] Cron Stones for downgrade protection
- [x] Forced enhancement (PRI/DUO/TRI/TET/PEN) with downgrade risk
- [x] Advice of Valks, failstack guide, enhancement history
- [x] Weapon vs armor stat differentiation per slot
- [x] Equipment comparison panel with stat deltas
- [x] Visual feedback: screen shake, color flash, glow tiers

### v0.5 — Save System
- [x] 5 character slots with create/load/delete
- [x] Character select screen with stats summary
- [x] Auto-save every 60s + save on exit
- [x] Full state serialization (stats, equipment, inventory, skills, position)

---

## Current Focus: Multi-Currency Economy & Cash System

### Goals
Build a layered economy with multiple currency tiers that each serve a distinct purpose. This creates meaningful choices — grind silver, earn gold through challenges, save diamonds for premium items, and contribute to your legion.

### Phase 1: Currency System Foundation

#### Diamond (Premium Currency)
- [ ] Add Diamond as premium currency (rare, valuable)
- [ ] Diamond balance tracked per character in CurrencyManager
- [ ] Diamond display on HUD (top-right, gem icon color)
- [ ] Sources: world boss first-kill reward, weekly login bonus, achievement milestones, rare drop from Demon Lord
- [ ] Diamond purchases: exclusive cosmetic name colors, character slot expansion (beyond 5), premium stash tabs
- [ ] Diamond-to-Gold exchange at NPC (one-way, fixed rate: 1 Diamond = 1,000 Gold)
- [ ] Cannot buy gameplay power directly with Diamonds (cosmetic + convenience only)

#### Gold (Mid-Tier Currency)
- [ ] Add Gold as mid-tier currency (earned through skill, not just grinding)
- [ ] Gold balance tracked per character
- [ ] Gold display on HUD
- [ ] Sources: zone boss kills, dungeon completion rewards, daily challenge quests, PvP arena wins, rare mob bounties
- [ ] Gold purchases: Cron Stones from NPC shop, Concentrated Black Stones, skill reset scrolls, fast travel passes, storage expansion
- [ ] Gold-to-Silver exchange at NPC (1 Gold = 10,000 Silver)
- [ ] Gold sinks: enhancement insurance (pay gold to guarantee no downgrade), repair costs for high-grade gear, guild creation fee

#### Silver (Grinding Currency — Already Exists)
- [ ] Keep silver as the primary grinding currency
- [ ] Silver remains: mob drops, trash loot auto-sell, enhancement costs
- [ ] Add silver sinks: NPC shop consumables, gear repair, waypoint fast travel fee, inventory expansion
- [ ] Silver-to-Gold exchange NOT allowed (must earn Gold through gameplay challenges)
- [ ] Rebalance silver costs for enhancement to account for new economy

#### Legion Marks (Guild/Legion Currency)
- [ ] Add Legion Marks as guild-specific currency
- [ ] Earned by: participating in legion activities, legion boss raids, territory wars, donating silver/gold to legion treasury
- [ ] Spent at: legion quartermaster NPC for exclusive gear, legion skill books, legion banners/cosmetics
- [ ] Legion rank determines which items you can buy (Recruit, Member, Officer, Leader)
- [ ] Weekly earning cap to prevent no-life dominance (e.g., 500 marks/week)
- [ ] Legion Marks reset if you leave/get kicked from legion (risk/reward for loyalty)

### Phase 2: CurrencyManager & UI

#### CurrencyManager Autoload
- [ ] Replace SilverManager with CurrencyManager handling all 4 currencies
- [ ] Unified API: `add_currency(type, amount)`, `remove_currency(type, amount)`, `get_balance(type)`
- [ ] Per-currency signals: `currency_changed(type, new_amount)`
- [ ] Exchange functions with rate lookup
- [ ] Session tracking per currency type
- [ ] Save/load integration with SaveManager

#### HUD Currency Display
- [ ] Top bar showing: Diamond (blue gem), Gold (yellow coin), Silver (gray coin)
- [ ] Legion Marks shown only when in a legion (shield icon)
- [ ] Compact format with icons + abbreviated amounts (1.2K, 3.5M)
- [ ] Currency gain popup: floating "+50 Gold" text on earn

#### NPC Currency Exchange
- [ ] Exchange NPC in Starter Village
- [ ] Exchange UI panel: select source currency, enter amount, see conversion result
- [ ] Confirmation dialog before exchange
- [ ] Exchange history log

---

## Phase 3: Combat & Gameplay Loop

### Goals
Make moment-to-moment combat feel impactful and give players reasons to keep grinding.

#### Mob & Combat Improvements
- [ ] Elite mobs: rare spawn variants with 3x HP, 2x drops, gold reward, special nameplate
- [ ] Mob aggro system: aggro table, tank/DPS roles matter
- [ ] Combo system: chain attacks within a window for bonus damage
- [ ] Dodge roll mechanic (spacebar, i-frames, stamina cost)
- [ ] Status effects: poison, burn, freeze, stun (mobs inflict and players resist)
- [ ] Damage types: physical vs magical, enemies have resistances

#### Zone Bosses
- [ ] 1 boss per zone (except Starter Village), timed respawn (10-15 min)
- [ ] Boss mechanics: telegraphed attacks, AoE danger zones, enrage timer
- [ ] Boss loot: guaranteed Gold, rare equipment, zone-specific materials
- [ ] First-kill bonus: Diamond reward per character per boss
- [ ] Boss HP scales with number of nearby players

#### Daily & Weekly Challenges
- [ ] 3 daily challenges (random from pool): "Kill 50 wolves", "Enhance an item", "Earn 10K silver"
- [ ] Daily rewards: Gold + XP bonus
- [ ] Weekly challenge: "Clear Demon Rift boss 3 times", "Reach +15 on any gear"
- [ ] Weekly rewards: Diamonds + rare materials

---

## Phase 4: Map & World Design

### Goals
Make the world feel alive with distinct zones, exploration rewards, and environmental storytelling.

#### Zone Layout & Transitions
- [ ] Natural zone transitions: paths, bridges, gates between areas
- [ ] Each zone gets a distinct tileset and color palette
- [ ] Safe zone boundaries clearly marked with visual indicator
- [ ] Loading-free seamless transitions

#### Zone Content
- [ ] Environmental hazards: lava damage in Demon Rift, ice slow in Cursed Ruins
- [ ] Hidden areas / secret paths with bonus mob spawns and treasure chests
- [ ] Resource gathering nodes per zone (ore, herbs, wood — for crafting)
- [ ] Zone-specific ambient effects (particles, lighting)

#### Navigation
- [ ] Fog of war on minimap (reveal as explored, persists per character)
- [ ] NPC quest markers on world map
- [ ] Fast travel between discovered waypoints (silver cost)
- [ ] Zone recommended level warning on entry

#### Visual Identity
- [ ] Starter Village: warm green tiles, wooden buildings, market stalls
- [ ] Slime Fields: open grasslands, slime pools, bright cheerful colors
- [ ] Wolf Forest: dense trees, dark green canopy, undergrowth
- [ ] Bandit Camp: wooden fortifications, campfires, tents, loot piles
- [ ] Cursed Ruins: dark stone, broken columns, eerie purple glow, fog
- [ ] Demon Rift: volcanic rock, lava streams, red/black sky, ash particles

---

## Phase 5: Crafting & Economy Sinks

### Goals
Give players something to do with all their materials and create meaningful silver/gold sinks.

#### Crafting System
- [ ] Crafting stations in Starter Village (Forge, Alchemy Lab, Workbench)
- [ ] Recipes unlocked by level and discovery
- [ ] Craft equipment, consumables, and enhancement materials
- [ ] Crafting uses mob drops + gathered resources + silver
- [ ] Craft quality: Normal/Fine/Masterwork based on crafting skill level
- [ ] Crafting skill levels up with use (separate from combat level)

#### NPC Shops
- [ ] Consumable shop: potions, buffs, teleport scrolls (silver)
- [ ] Enhancement shop: Cron Stones, Black Stones (gold)
- [ ] Premium cosmetic shop (diamonds)
- [ ] Legion quartermaster (legion marks)
- [ ] Shop inventories rotate weekly for rare items

#### Marketplace (Player Trading)
- [ ] Auction house: list items for silver or gold
- [ ] Listing fee (5% of price) as currency sink
- [ ] Tax on sales (10%) as currency sink
- [ ] Price floor/ceiling per item to prevent manipulation
- [ ] Search and filter by slot, grade, level, price

#### Gear Repair
- [ ] Equipment durability system: loses durability on death
- [ ] 0 durability = stats halved until repaired
- [ ] Repair cost scales with grade and enhance level (silver + gold for Epic/Legendary)
- [ ] Repair NPC in each zone's safe area

---

## Phase 6: Party System & Social

### Goals
Make grinding with friends rewarding and build the social foundation for legions.

#### Party System
- [ ] Party formation: invite by name, up to 4 players
- [ ] Shared XP (split evenly with distance check)
- [ ] Loot distribution modes: round-robin, free-for-all, need/greed
- [ ] Party member HP bars on HUD
- [ ] Party chat channel

#### Legion (Guild) System
- [ ] Create legion: name, banner, costs Gold
- [ ] Legion ranks: Leader, Officer, Member, Recruit (permissions per rank)
- [ ] Legion treasury: members donate silver/gold, used for legion upgrades
- [ ] Legion chat channel
- [ ] Legion member list with online status, level, class, gear score
- [ ] Max 30 members per legion (expandable with gold)

#### Legion Activities
- [ ] Legion daily quests: contribute kills, silver, materials as a group
- [ ] Legion boss raids: special boss only accessible by legion parties
- [ ] Territory control: legions claim grinding zones for a buff (bonus drop rate)
- [ ] Legion vs Legion wars: scheduled PvP events with legion mark rewards
- [ ] Legion shop: exclusive items purchasable with Legion Marks

---

## Phase 7: Boss & Dungeon Content

### Goals
Endgame content that requires coordination, skill, and the best gear.

#### World Bosses
- [ ] 2 world bosses: Titan Golem (Cursed Ruins), Arch Demon (Demon Rift)
- [ ] Spawn every 4 hours, server-wide announcement
- [ ] Unique mechanics per boss (phases, adds, enrage)
- [ ] Loot distributed to top damage dealers and all participants get Gold
- [ ] Exclusive boss-only Legendary drops

#### Instanced Dungeons
- [ ] 3-player instanced dungeons (party required)
- [ ] Dungeon tiers: Normal, Hard, Nightmare (scaling rewards)
- [ ] 3 dungeons: Slime Caverns (Lv10), Bandit Fortress (Lv20), Demon Sanctum (Lv35)
- [ ] Dungeon loot: exclusive gear sets, crafting recipes, Gold, Diamond (first clear)
- [ ] Weekly lockout on Nightmare difficulty rewards

#### PvP Arena
- [ ] 1v1 arena: ranked matches, Gold entry fee, winner takes pot
- [ ] 3v3 arena: team-based, Legion Marks as reward
- [ ] Seasonal rankings with exclusive cosmetic rewards
- [ ] Matchmaking based on gear score + level bracket

---

## Phase 8: Polish & Live Ops

### Goals
Quality of life, retention mechanics, and the systems needed for a live game.

#### Quality of Life
- [ ] Settings menu: audio, display, keybinds
- [ ] Damage numbers style options
- [ ] Auto-loot toggle
- [ ] Quick-equip best gear button
- [ ] Achievement system with Diamond rewards

#### Retention & Progression
- [ ] Daily login rewards: escalating 7-day cycle (silver -> gold -> materials -> diamond)
- [ ] Season pass: free + premium track with cosmetics and materials
- [ ] Character titles earned through achievements
- [ ] Prestige system at max level (reset for permanent stat bonus)

#### Performance & Technical
- [ ] Object pooling for enemies and projectiles
- [ ] LOD system for distant entities
- [ ] Network optimization: delta compression, interest management
- [ ] Server-authoritative movement and damage validation
