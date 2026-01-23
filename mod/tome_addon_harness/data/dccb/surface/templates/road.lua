-- /data/dccb/surface/templates/road.lua
-- Road surface template - grassy area with vertical road and tree border

return {
  name = "road",
  base = "GRASS",
  decorations = {
    { kind = "vertical_road", grid = "ROAD", width = 3 },
    { kind = "edge_ring", grid = "TREE", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
