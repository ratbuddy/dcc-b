-- /data/dccb/surface/templates/plains.lua
-- Plains surface template - simple grassy area with tree border

return {
  name = "plains",
  base = "GRASS",
  decorations = {
    { kind = "edge_ring", grid = "TREE", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
