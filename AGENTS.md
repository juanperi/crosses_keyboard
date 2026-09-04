# Crosses Project Notes

## Hardware And Workflow

- Target: original Crosses V1, 42-key 3x6 layout, Nice!Nano controllers.
- Right half is the primary ZMK side and is the side used for ZMK Studio.
- Durable source of truth: `config/crosses.keymap`.
- Local build command: `./build-local.sh`.
- Local artifacts: `build-local/crosses_42_left.uf2` and `build-local/crosses_42_right.uf2`.
- Local flashing helper: `./flash-local.sh [all|left|right]`.
- Flash right first, then left. Do not use `settings_reset.uf2` unless intentionally resetting settings.
- `flash-local.sh` waits for `/Volumes/NICENANO`, copies the matching UF2, and treats the bootloader volume disappearing during `cp` as a successful reboot.
- Generated/cache directories are ignored: `.zmk-workspace/`, `build-local/`, and downloaded reference checkouts.
- Never flash or reset without explicit user approval.

## Official Hardware Sources

The local project initially recreated the Crosses shield incorrectly. The correct hardware integration comes from the official template/module:

- Crosses release v1.3: https://github.com/Good-Great-Grand-Wonderful/crosses/releases/tag/v1.3
- Crosses wiki: https://github.com/Good-Great-Grand-Wonderful/crosses/wiki#firmware-templates
- Official 42-key template: https://github.com/Good-Great-Grand-Wonderful/crosses-42-zmk-template
- Official hardware module: https://github.com/Good-Great-Grand-Wonderful/gggw-zmk-keebs

`config/west.yml` imports `gggw-zmk-keebs` on its `zephyr-4.1` revision. The official module provides the physical layout, matrix transforms, Nice!Nano overlays, OLED setup, PMW3610 trackball setup, and related modules. Do not replace it with a hand-written local shield unless necessary.

The official wiki flashing sequence is right half first, then left half. The halves require distinct firmware files and are not interchangeable.

## Current Keymap

Layer numbering in `config/crosses.keymap`:

```text
BASE = 0
NAV  = 1
NUM  = 2
SYM  = 3
FUN  = 4
SYS  = 5
```

Base thumb layout, from left to right:

```text
Hold Num       Hold Nav + Win       Cmd       Enter       Space       Tap Backspace / Hold Sym
```

Base outer columns:

```text
Left first column:  Esc, Tab, transparent
Right last column: Backspace, apostrophe, transparent
```

Base home-row mods:

```text
Left:  A/Ctrl, S/Option, D/Shift, F/Command
Right: J/Command, K/Shift, L/Option, semicolon/Ctrl
```

Home-row mods use the positional/timing-safe pattern from ZMK documentation:

- Separate `hml` and `hmr` behaviors.
- `flavor = "balanced"`.
- `tapping-term-ms = <280>`.
- `quick-tap-ms = <175>`.
- `require-prior-idle-ms = <150>`.
- `hold-trigger-on-release`.
- Left mods trigger holds from right-side positions; right mods trigger holds from left-side positions.

Current layers:

- `Nav + Win`: arrows, Home/End, page movement, editing, UHK window actions, left/right click, screenshot.
- `Num`: right-hand numpad/arithmetic. The `0` key is in the former comma position on the bottom row.
- `Sym`: ISO/QWERTY-oriented symbol layer.
- `Fun`: media and F-keys.
- `Sys`: Bluetooth, Studio unlock, bootloader and reset keys.

`Nav + Win` known actions:

```text
W: previous tab             E: Mission Control       R: next tab
S: previous Space           D: Cmd+Tab               F: next Space
X: previous Slack thread    V: next Slack thread
T: right click              G: left click
```

The `D` action is currently a one-shot `Cmd+Tab` macro. Multiple `D` taps while holding Nav do not yet maintain Command. A tri-state/swapper experiment was attempted and reverted because it did not behave correctly. Do not describe it as solved. The current behavior is simply one-shot `Cmd+Tab` per press.

The Base `J+K` combo is the current experiment for Enter:

```dts
timeout-ms = <35>;
require-prior-idle-ms = <100>;
key-positions = <18 19>;
layers = <BASE>;
bindings = <&kp RET>;
```

The combo is positional and uses the official Crosses 42-key layout. It is intended to produce Enter when J and K are pressed together. Combos overlapping home-row mods should be tested carefully for false positives.

The left trackball scroll overlay is in `config/scroll-invert.overlay`:

- Converts left trackball XY to scroll.
- Inverts vertical wheel direction with a scaler of `-1/1`.
- Reduces scroll intensity with `1/16`.
- Applies BLE report-rate limiting.

The right trackball is supplied by the official Crosses module and is not locally redefined.

The screenshot macro emits:

```text
Cmd+Ctrl+Shift+4
```

On macOS this copies a selected screenshot region to the clipboard rather than saving it as a file.

## Visual Documentation

`docs/proposed-layout.html` is an interactive visual reference, while `config/crosses.keymap` is the firmware source of truth. Keep them aligned: any change to layers, key bindings, combos, macros, behaviors, timing, thumb actions, or documented key positions must update both files in the same change. Do not leave the HTML describing stale firmware behavior.

- Select a layer tab to show one layer.
- Click the selected tab again to show all layers.
- Print CSS supports landscape and portrait output.
- The current visual layer list is Base, Num, Sym, Nav + Win, Fun, and Sys.
- The HTML includes the current thumb layout, Enter combo, Sys access, click locations, and screenshot behavior.
- The Base `T+Y` combo types `()` and moves the cursor between the parentheses; its marker and explanation must remain synchronized with the keymap.

## Sys Access

On Base, the Sys combo is:

```text
Hold left outer Num + hold right outer Sym/Backspace
```

Sys includes:

- Bluetooth profiles and clear on the top-left.
- Studio unlock on the top-right.
- Left second-row outer key: bootloader for the left half.
- Right second-row outer key: bootloader for the right half.
- Left second-row next key: system reset.

These source bindings only apply after flashing the latest firmware.

## Build And Verification

Before any flash:

```bash
git status --short --ignored
./build-local.sh
ls -lh build-local/crosses_42_left.uf2 build-local/crosses_42_right.uf2
```

The build script updates dependencies on the host, then compiles in Docker. It does not flash or reset.

The expected normal artifacts are:

```text
build-local/crosses_42_left.uf2
build-local/crosses_42_right.uf2
```

## Important Untracked Data

- `docs/uhk.json` is intentionally untracked and should not be committed. It is the raw UHK export and contains more device-specific data than needed for the migration.
- Do not commit `.zmk-workspace/`, `build-local/`, or downloaded reference repositories.

## Sources And Documentation

ZMK:

- ZMK keymaps: https://zmk.dev/docs/keymaps
- ZMK combos: https://zmk.dev/docs/keymaps/combos
- ZMK hold-tap: https://zmk.dev/docs/keymaps/behaviors/hold-tap
- ZMK macros: https://zmk.dev/docs/keymaps/behaviors/macros
- ZMK sticky keys: https://zmk.dev/docs/keymaps/behaviors/sticky-key
- ZMK reset/bootloader: https://zmk.dev/docs/keymaps/behaviors/reset
- ZMK mouse emulation: https://zmk.dev/docs/keymaps/behaviors/mouse-emulation
- ZMK split keyboards: https://zmk.dev/docs/features/split-keyboards
- ZMK local container toolchain: https://zmk.dev/docs/development/local-toolchain/setup/container

Public layout references:

- Stock ZMK Corne keymap: https://github.com/zmkfirmware/zmk/blob/main/app/boards/shields/corne/corne.keymap
- Miryoku: https://github.com/manna-harbour/miryoku
- Miryoku ZMK: https://github.com/manna-harbour/miryoku_zmk
- Urob ZMK configuration: https://github.com/urob/zmk-config
- Urob combo definitions: https://github.com/urob/zmk-config/blob/main/config/combos.dtsi
- AndersonBA ZMK configuration: https://github.com/andersonba/zmk-config
- AndersonBA combo definitions: https://github.com/andersonba/zmk-config/blob/main/config/combos.dtsi
- Home-row mods guide: https://precondition.github.io/home-row-mods
- Callum Oakley compact layout: https://github.com/callum-oakley/qmk_firmware/tree/master/users/callum

Third-party module considered for app switching:

- ZMK tri-state: https://github.com/urob/zmk-tri-state

The tri-state module was tested experimentally but removed from the committed configuration because repeated Cmd+Tab did not work as required.
