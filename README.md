# Meadow Dash

Meadow Dash is a 2D platformer vertical slice made with Godot 4.7 and GDScript. It includes a long OverWorld-to-castle level, forgiving modern movement, keyboard and gamepad controls, coins, varied enemies, blocks, mushroom/flower/star power-ups, fire projectiles, checkpoint restoration, score/time records, pause and victory screens, world-specific music, and sound effects.

## Play

Open `project.godot` in Godot 4.7.1 or newer and press **F6/F5**.

- Move: **A/D**, arrow keys, left stick, or D-pad
- Jump: **Space** or the south gamepad button
- Sprint: **Shift**, **X**, or the west gamepad button
- Fire (after collecting a flower): **F**, **C**, or the east gamepad button
- Pause: **Escape** or **Start**

On Android and iOS, the game runs in landscape and automatically displays on-screen **left**, **right**, **down**, **run**, **fire**, **jump**, and **pause** controls. The controls support simultaneous touches, so the player can run and jump at the same time.

## Mobile export

Android and iOS presets are included in `export_presets.cfg`. Install the matching Godot export templates, then use **Project → Export**. Android also requires a configured Android SDK; iOS export requires Xcode and an Apple signing team.

Reach the banner at the far end of the meadow. The first question-block pickup grows a small hero; the next becomes a fire flower that unlocks bouncing fireballs. A fully powered hero loses fire power on the first hit, shrinks on the second, and can break brown bricks while grown. The glowing midpoint flag is a checkpoint.

The first half of the level is a bright daytime fire course. Near the midpoint, stand inside the green pipe and press **S**, **Down**, D-pad down, or the mobile down button. A fade transition transports the player into a separate night castle presentation with moonlight, brick terrain, world-specific music, and a dedicated checkpoint.

Daytime uses the supplied hills, bushes, clouds, blocks, pipes, and ground art. The night section changes to castle scenery and a separate music track. Enemy variants include normal walkers, faster turtles, player-seeking hunters, and fixed plants that alternate between closed and attacking poses. Optional stars grant six seconds of invulnerability.

## Automated checks

On macOS, with Godot in the usual application location:

```sh
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . tests/test_runner.tscn
```

When using another installation, replace the executable path. The test runner checks scene construction, movement tuning, sprint limits, variable jumping, checkpoint state restoration, damage transitions, and pause behavior.

See [LICENSES.md](LICENSES.md) for third-party asset details.
