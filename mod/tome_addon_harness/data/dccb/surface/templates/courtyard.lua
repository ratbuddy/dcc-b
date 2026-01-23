-- /data/dccb/surface/templates/courtyard.lua
-- Courtyard surface template - grassy area with centered rectangular road courtyard and tree border

return {
  name = "courtyard",
  base = "GRASS",
  decorations = {
    { kind = "edge_ring", grid = "TREE", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
