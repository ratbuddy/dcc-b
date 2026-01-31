-- /data/dccb/surface/templates/winter_road.lua
-- Winter road template - snowy landscape with icy path and snowy trees

return {
  name = "winter_road",
  base = "GRASS_WINTER",
  decorations = {
    { kind = "vertical_road", grid = "ROAD_WINTER", width = 3 },
    { kind = "edge_ring", grid = "TREE_WINTER", thickness = 2, step = 3 },
  },
  entrances = { count = 2, grid = "DCCB_ENTRANCE" }
}
