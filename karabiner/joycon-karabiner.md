# Joy-Con (L) Karabiner Mapping Spec

Device: Joy-Con (L) — vendor_id: 1406, product_id: 8198
Held sideways (horizontal grip) — physical orientations are rotated 90° from Karabiner's perspective.

## Input mapping

Karabiner sees Joy-Con inputs differently from their physical layout:

- **Stick** → `generic_desktop:dpad_*`. Karabiner treats stick as d-pad. Held sideways: `dpad_down` = physical left, `dpad_up` = physical right, `dpad_left` = physical up, `dpad_right` = physical down.
- **Directional buttons** (face buttons) → `pointing_button:button1-4`. Physical arrow cluster on the Joy-Con face.
- **Other buttons** → `pointing_button` with various IDs.

## Architecture

Two-layer approach for stick inputs (complex actions need key combos):
1. Simple modifications: `generic_desktop` → intermediate keys (F13-F16)
2. Complex modifications: F13-F16 → actual actions (combos, modifiers)

Buttons (`pointing_button`) go directly into complex modifications, device-scoped to Joy-Con.

L shoulder acts as a combo modifier via `set_variable` (`joycon_l_held`). Hold L alone = F18 (Claude Code voice push-to-talk). Hold L + another button = combo action (e.g., L+Minus = Ctrl+C). Variable-conditioned rules must appear before the solo-button fallback.

## Mappings

### Stick — simple mod → F13-F16 → complex mod

| Karabiner input | Physical | Action | Intermediate |
|---|---|---|---|
| `generic_desktop:dpad_down` | Stick left | Prev iTerm tab (⌘⇧[) | F13 |
| `generic_desktop:dpad_up` | Stick right | Next iTerm tab (⌘⇧]) | F14 |
| `generic_desktop:dpad_left` | Stick up | Scroll up (mouse_key) | F15 |
| `generic_desktop:dpad_right` | Stick down | Scroll down (mouse_key) | F16 |

### Buttons — complex modifications (device-scoped)

| Karabiner input | Physical | Action |
|---|---|---|
| `pointing_button:button16` | ZL (trigger) | Enter |
| `pointing_button:button15` | L (shoulder) | Modifier (hold = F18 + combo prefix). Hold triggers Claude Code voice push-to-talk. No tap action (macOS dictation removed) |
| `pointing_button:button9` | Minus | Escape (with L held: Ctrl+C) |
| `pointing_button:button3` | Dir Up | Up arrow |
| `pointing_button:button2` | Dir Down | Down arrow |
| `pointing_button:button5` | SL | Shift+Tab |
| `pointing_button:button6` | SR | New tab + `default-repo && ccv` (⌘T + type). Starts Claude Code with voice mode auto-enabled |
| `pointing_button:button14` | Capture | Close tab (⌘W) |
| `pointing_button:button1` | Dir Left | Option+← (word jump left) |
| `pointing_button:button4` | Dir Right | Option+→ (word jump right) |
| `pointing_button:button11` | Stick click | Option+Delete (delete word) |

## macOS setup

- Claude Code keybinding: `voice:pushToTalk` mapped to F18 in `~/.claude/keybindings.json`
- `ccv` shell function: starts Claude Code and auto-sends `/voice` after 3s (via tmux or iTerm2 AppleScript)

## Goal

Control Claude Code in iTerm one-handed with Joy-Con (L).
