

# Unsorted
- [ ] Loading *Iuno* model freezes the game for a moment. Fix this, it should not freeze. Is it render thread or worker thread that causes the freeze? Some mutex lock we're holding that's freezing everything? Maybe sending data for all meshes in one frame is too much? Spread out across frames?



# Game world
- [ ] Decide on beginner experience, procedural terrain or a pre-made town?
- [ ] Protoype world in Krita. buildings, blocks, monsters areas. nothing detailed.
- [ ] Model the prototype in blender. we care about speed not quality.



# Engine stuff
- [ ] Entity movement from AI pathfinding and User input, how to connect them.
- [ ] Network architecture? server verifies. If a person is messing with the connection (hacking) we don't care how buggy their client gets.
- [ ] Modding support and architecture. Even if the game won't have mods it's good to modularize the game to keep things neat.

# Improve develop experience
- [ ] Key in the game to hotreload code. (instead of typing build.py hot in a terminal)












# Real time editing in blender and export to game
https://lotusspring.substack.com/p/how-i-wrote-the-fastest-blender-exporter