
We think of architecture based on what exists in the universe the player can see.

We begin with an empty universe.

First thing player sees is a menu to pick worlds. We'll leave this for later.

Second thing they see is:
- Storage building
- 5 workers
- A map, terrain, tiles.
- Resources, minerals, trees.

workers and buildings are entities. they move about.
they are positioned in 3D space.

The terrain is tile based. We begin with a 2D map. No collision.

For minerals they are entities. Later we may chose to let tiles be minerals that can be destroyed and trees that can
be mined but we'll see.

How do we structure this in code files and functions.

We have driver and hot reloading API as a base.

From there we have a render, input and tick function. Called at their respective times.


We don't make this into a generic engine.