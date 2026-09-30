# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the game

No build required. Open the game with any static server:

**Option 1: Python built-in server**
```bash
python3 -m http.server 8000
```
Then navigate to `http://localhost:8000` in your browser.

**Option 2: Node (npx)**
```bash
npx serve .
```

**Option 3: Direct file (single-player only, may have CORS issues)**
```bash
open index.html  # macOS
```

## Codebase structure

This is a vanilla JS Tetris implementation with zero dependencies:

- **index.html** — DOM structure with game canvas (300×600px), score panel, next-piece preview, and overlay for pause/game over states
- **game.js** — Core game logic (~300 LOC): board model (10×20 grid), piece definitions, collision detection, wall kicks, game loop with `requestAnimationFrame`, line clearing, scoring, ghost piece rendering
- **style.css** — Dark/retro arcade styling with flexbox layout, dark theme, and backdrop blur effects

## Key architectural details

**Board representation**: 2D array where each cell is `0` (empty) or `1–7` (piece color index)

**Piece structure**: Objects with `{type, shape, x, y}` where `shape` is a 2D array (matrix form)

**Rotation**: Clockwise via matrix transpose + row reversal in `rotateCW()`

**Wall kicks**: `tryRotate()` attempts rotation at ±1 and ±2 column offsets when direct rotation collides

**Game loop**: `requestAnimationFrame` with accumulated `dt` that drops a piece when `dt ≥ dropInterval`. Speed increases with level: `max(100ms, 1000 - (level - 1) × 90)`

**Line clearing**: Scans board bottom-to-top, removes complete rows, inserts blanks at top

**Ghost piece**: Semi-transparent preview (`globalAlpha = 0.2`) of where piece will land

## Customization points

These constants in `game.js` can be tuned:

- `COLS` / `ROWS` — Board dimensions (default 10×20)
- `BLOCK` — Cell size in pixels (default 30px)
- `COLORS` — 7-element array of hex color codes
- `LINE_SCORES` — Points array `[0, 1-line, 2-line, 3-line, 4-line]`

⚠️ If you change `COLS`, `ROWS`, or `BLOCK`, update the canvas dimensions in `index.html` to match: `width = COLS × BLOCK`, `height = ROWS × BLOCK`

## Controls

| Key | Action |
|-----|--------|
| `←` / `→` | Horizontal move |
| `↑` or `X` | Rotate CW |
| `↓` | Soft drop (accelerated) |
| Space | Hard drop (instant) |
| P | Pause/resume |

## Testing & debugging

No test suite. Verify changes by:

1. Running the server
2. Playing through a few games (verify piece spawn, rotation, line clears, scoring, level progression, game over)
3. Test edge cases: wall kicks near edges, hard drop scoring, level speed increases
