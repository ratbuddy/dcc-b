# Quick Test Command

To test the tileset gallery zone, open ToME debug console (press `~` or Ctrl+D) and run:

```lua
game:changeLevel(1, "dccb+dccb-tileset-gallery")
```

See [TESTING.md](TESTING.md) for detailed instructions and troubleshooting.

## Expected Result
You'll see 13 terrain tiles arranged in a grid pattern starting at coordinates (5,5).

Check `te4_log.txt` for detailed output like:
```
[DCCB-Gallery] ✓ [ 5, 5] FLOOR | Base Game | Standard floor tile
[DCCB-Gallery] ✓ [ 9, 5] WALL  | Base Game | Standard wall tile
... (11 more grids)
```

All tiles should render as PNG graphics, not ASCII characters.
