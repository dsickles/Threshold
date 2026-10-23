# Shared UI theme

`threshold_theme.tres` is Threshold's one button and text theme (DAS-72). It is
the project theme (`gui/theme/custom` in `project.godot`), so every screen gets
it without setting anything. Chapter skins may override it while they play
(DESIGN.md, "Brand & Style").

## Sizes

`docs/design/ux/DESIGN.md` sizes are what the player sees on a phone held
sideways. A sideways iPhone 17 Pro in Safari with the toolbar hidden is 402
points tall, and the layout is 720 tall (`canvas_items` stretch, `expand`), so
the layout shows at 402/720, about 56%. Every size in the theme is the
DESIGN.md size × 720/402 (about 1.79), rounded:

| DESIGN.md | On the phone | In the theme |
|---|---|---|
| body (default) | 16 | 29 |
| subtitle (`LabelSubtitle`) | 18 | 32 |
| reader (`LabelReader`) | 20 | 36 |
| micro-shout (`LabelMicroShout`) | 28 | 50 |
| display (`LabelDisplay`) | 32 | 57 |
| border | 1 | 2 |
| focus ring | 2 | 4 |
| rounded.md corners | 8 | 14 |
| button padding (sides / top and bottom) | 16 / 12 | 29 / 21 |
| smallest tap target | 44 | 79 |

If the phone check shows a different shrink (the M0 menu's "UI style" check
prints it), change the sizes by the same rule and the numbers in
`game/tests/test_ui_theme.gd`.

## Kinds

| Type | Use |
|---|---|
| `Button` / `ButtonQuiet` | button-quiet: outline, light label. Lists of equal choices, Back, secondary. A button with no kind set looks like this. |
| `ButtonPrimary` | button-primary: gold fill, dark label, slightly darker when pressed. The one main action on a screen. |
| `Label` | body text |
| `LabelMuted` | secondary lines, body size, muted colour |
| `LabelSubtitle`, `LabelReader`, `LabelMicroShout`, `LabelDisplay` | the other DESIGN.md sizes |

Set the kind with a node's **Theme Type Variation** in the Inspector. Hover
looks the same as resting, so nothing works only on hover.

The fonts are Godot's default for now; DESIGN.md's Source Serif 4, Source
Sans 3 and IBM Plex Mono are not in the project yet (adding them needs Dan's
OK, as an outside asset).
