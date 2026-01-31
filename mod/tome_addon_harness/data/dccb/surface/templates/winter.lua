-- /data/dccb/surface/templates/winter.lua
-- Winter surface template - snowy landscape with snowy trees

return {
  name = "winter",
  base = "GRASS_WINTER",
  decorations = {
    { kind = "edge_ring", grid = "TREE_WINTER", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
