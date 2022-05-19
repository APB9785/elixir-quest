# ElixirQuest

ElixirQuest is a 2-D MMORPG game server implementing ECS (Entity-Component-System) architecture.

Backend uses ETS for active game entities, and Postgres for persistence.
Frontend uses Phoenix LiveView rendering simple assets.

## Goals

* [x] Base ECS implementation  
* [x] Game state rendering w/ LiveView  
* [x] Simple entity movement  
* [x] Wander, aggro, and seek components for mobs  
* [/] Attacking  
* [x] Entity death  
* [x] Entity respawns  
* [ ] Other actions  
* [x] Action logs  
* [x] Game state persistence (postgres)  
* [ ] Player accounts  
* [ ] Player Chat  
* [ ] More robust UI, possibly canvas  
