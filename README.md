# Crosses 42-key ZMK configuration

Personal configuration for the original Crosses V1, 42-key layout, using the official `crosses-42-zmk-template` build targets.

## Workflow

- Edit `config/crosses.keymap` for durable firmware configuration.
- Push to GitHub; `.github/workflows/build.yml` builds the firmware.
- Download the workflow artifact and flash the matching left and right `.uf2` files.
- Use ZMK Studio for safe experiments and quick remaps. Capture any useful Studio changes in `config/crosses.keymap` before reflashing.
- The right firmware includes ZMK Studio support. The `studio_unlock` binding is on the Mouse layer, top-right key.

## Current baseline

The initial keymap keeps the official template's Base, Lower, Raise, and Mouse layers, while adding home-row mods for Mac:

| Key | Tap | Hold |
| --- | --- | --- |
| A | A | Left Control |
| S | S | Left GUI / Command |
| D | D | Left Alt / Option |
| F | F | Left Shift |
| J | J | Right Shift |
| K | K | Right Alt / Option |
| L | L | Right GUI / Command |
| `;` | `;` | Right Control |

This is deliberately a starting point, not a finalized migration. The old UHK export is kept separately as `docs/uhk.json` for reference; UHK actions cannot be copied mechanically because its module and keymap model differs from ZMK.

## Hardware

- Original Crosses V1
- 42-key / 3x6 matrix
- Nice!Nano controllers
- Right half is the primary side and must be used for ZMK Studio

## Important migration notes

- ZMK Studio edits are stored in keyboard settings and can be lost when firmware/settings are reset or replaced. Treat this repository as the source of truth.
- `&hm` uses `tap-preferred` with a 200 ms tapping term. We can tune this after real typing tests.
- The UHK export contains several keymaps. The active baseline is the default `Mac` keymap (`RKR`), not `Dvorak for Mac` (`DVM`) or `Dvorak for PC` (`DVO`). The first iteration keeps the Crosses QWERTY geometry while we translate the Mac keymap's layers and actions.
- Keep the official Crosses shield dependency supplied by the ZMK build workflow; this repo only contains the user configuration.
