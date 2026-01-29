-- /data/dccb/surface/templates/courtyard.lua
-- Courtyard surface template - simple grassy area with tree border

return {
  name = "courtyard",
  base = "GRASS",
  decorations = {
    { kind = "edge_ring", grid = "TREE", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
