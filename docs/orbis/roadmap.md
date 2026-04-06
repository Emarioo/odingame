*Orbis* is a prototype for real time strategy game with one big world instead of a campaign with smaller maps.



![](/docs/orbis/img/2026-04-05_20-27.png)


Since this is a prototype we are aiming for a Minimal Viable Product. If the game is fun even with:
- Bad art
- Scuffed movement
- Poor building placement
- Dumb AI
- Few units and buildings

Then we might be on to something.

For the **MVP** we must have
- A big world (since that's the special)
- Workers to command
- Buildings to place
- Marines to defend and attack
- Enemies for some challange and threat. It also makes the world feel alive, you are not alone.
- Fog of war for mystery, otherwise you don't need to scout and you can just see that there are no enemies near you so you feel like the game is too easy and boring. Probably one of the later things to implement.

Then later add some NPCs that have missions on the map like clear the enemies near the port. Continously defend the supply route in the mountains.
NPCs reward you if you succeed and punish you if you don't. Perhaps becomes your enemy and attacks you. You can make enemies of everyone if you wish.

Terminolgy has not been established and we will therefore use StarCraft 2 concepts.

A typical playthrough would be close to the following:

1. Start game and create a world
2. Early game
   1. Spawn in with 5 workers and a command center.
   2. Some dialog to give you backstory to why you are here. For example "Your mission is to establish an outpost in this area. We want you to investigate the threat in this area. We have recieved reports of vast resources being supplied and suspect training of large armies to storm nearby settlements to steal their resources and eventually attack neighbouring regions and possibly continents." (visually you are dropped of from a ship, maybe some extra story about you being a promising cadet from the academy where they have high hopes. Since the mission is important they believe you can gather useful information at the very least, they want you to expand and do more but can send in an elderly commander to take your place if you fail, they'd rather not since they are required elsewhere. they are not allied with settlements so you can choose to steal as well they just don't want the threat to gain more momentum)
   3. Tell workers to collect resources nearby (trees, minerals)
   4. Tell workers to construct a barrack
   5. Produce marines to defend early attacks. Alternatively focus on just making workers for higher resource gathering if you're feeling risky or you have scouted no threads nearby.
3. Mid game
   1. Scout with marines to find more resources and discover threats.
   2. Decide whether you should make more marines with resources, more workers.
   3. Take out the nearby threats.
   4. Expand into their lands.
   5. Resources are exhausted. With higher tech you can mine deeper in mines for more resources but until then resources are finite.
4. Late game
   1. Massive attacks on multiple fronts to take out the enemy
   2. Eventually the map is clear of all enemies. At this point you won.
   3. OR on the edges of the map the enemy has massive production of marines which is very hard to break through. They won't move forward though they just stay at the edge.

The theme may be robotic. If so we can use energy as supply to workers and marines. Rather than marines they would be robots with guns?

# Questions to answer:
Is them map generated or handcrafted. Not sure maybe both.






# Extra features
- Multiplayer (i will design the architecture in mind to support this without too much rewriting, not for the MVP though)