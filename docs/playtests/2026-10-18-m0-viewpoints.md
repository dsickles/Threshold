# M0 Check 3: fixed-viewpoint feel (DAS-69)

The bar is in the DAS-69 ticket: tap-only movement between 3–4 viewpoints, where you can go is visible without hover, targets at least 44px, and Dan plus one or two people new to it move around without getting lost and without explanation.

## How it works

From the M0 menu, Viewpoints opens a gray-box room (placeholder shapes, not the House). Each viewpoint frames one thing: the window, the table, the armchair and the shelf. A 110px ring sits on each thing; tapping it glides the camera to a view looking at that thing. A thing out of view has its ring pinned to the left or right screen edge with an arrow (‹ or ›). − / + buttons at the top right set the glide time (0.2–3.0 s) and show the value. Back to menu returns to the M0 menu.

## How it changed during the session

1. **Rings on the floor, camera stands on them** (build das-69-68edb77). Tapping a floor spot put you there, turned to look back into the room. Dan: it works, but where you tap then becomes where you stand, which goes against what he expects from this kind of game. He expected to end up looking at what he tapped.
2. **Walk then turn** (build das-69-ac57fb4). The camera faced the tapped spot while gliding, then turned. This answered a misreading of Dan's note and was dropped.
3. **Tap a thing to look at it** (build das-69-31f0ca9). The current version, described above.

## Results

2026-10-18, iPhone 17 Pro Safari and laptop Chrome, build das-69-31f0ca9.

| Who | Platform | Got lost? | Notes |
|---|---|---|---|
| Dan | iPhone 17 Pro Safari | No | |
| Dan | Laptop Chrome | No | |
| Tester 1 (new to it) | | | Not yet run. |
| Tester 2 (new to it) | | | Not yet run. |

**Chosen glide duration: 2.0 s** on both platforms. It is now the default.

## Dan's verdict

2026-10-18: the edge arrows read clearly, and movement with the 2 s glide is good. He likes that pressing a circle means you start looking closer at that thing, because later, when the thing starts a task, it won't be jarring that you didn't fly behind it.

Pending: the one or two new testers.
