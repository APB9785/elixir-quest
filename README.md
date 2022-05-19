# ElixirQuest

ElixirQuest is a 2-D MMORPG game server implementing ECS (Entity-Component-System) architecture.

Backend uses ETS for active game entities, and Postgres for persistence.
Frontend uses Phoenix LiveView rendering simple assets.

## Goals

* [x] Base ECS implementation  
* [x] Game state rendering w/ LiveView  
* [x] Simple entity movement  
* [x] Wander, aggro, and seek components for mobs  
* [x] Attacking  
* [x] Entity death  
* [x] Entity respawns  
* [x] Action logs  
* [x] Game state persistence (postgres)  
* [ ] Player accounts  
* [ ] Gold from defeating mobs  
* [ ] Experience/leveling from defeating mobs  
* [ ] Inventory/items/equipment  
* [ ] Entity stats/attributes  
* [ ] Other actions  
* [ ] Player death/respawning  
* [ ] Player Chat  
* [ ] More robust UI, possibly canvas  
