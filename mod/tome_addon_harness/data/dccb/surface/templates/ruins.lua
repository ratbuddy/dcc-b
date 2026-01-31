-- /data/dccb/surface/templates/ruins.lua
-- Ruins surface template - ancient weathered courtyard with ruined pillars

return {
  name = "ruins",
  base = "GRASS_RUINS",
  decorations = {
    { kind = "edge_ring", grid = "TREE_RUINS", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
