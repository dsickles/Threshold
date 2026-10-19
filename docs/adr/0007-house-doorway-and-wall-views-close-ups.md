---
status: accepted
date: 2026-10-19
supersedes: part of ADR-0003 ("tap a viewpoint (a spot or a doorway)"); the House movement lines in game-architecture §2.3, EXPERIENCE Interaction Primitives, FR34, UX-DR24, gdd Input
---

# The House is moved through by doorway views, wall views and close-ups

ADR-0003 still holds: the House uses fixed camera shots, not free walking, and tap is the only verb. This ADR says how those shots are arranged. Decided with Dan in the M1 prep thread, 2026-10-19, building on the M0 viewpoint check (decision-history 17: tapping a thing glides to a view looking *at* it, 2.0 s glide, off-screen rings pin to the screen edge with an arrow).

- **Doorway view.** Every room has one: a view from its doorway looking into the whole room. Tapping a doorway glides to the next room's doorway view.
- **Wall view.** From inside a room, tapping a wall or corner glides to a view framed on it from the middle of the room. A room has 2 to 4. A short look-drag still works in any view.
- **Close-up.** Tapping an object glides to a close view of it. Each object has **one action** (read it, open it, switch it on), done by tapping it again. Tapping anywhere off the object steps back to the view it was opened from.
- **Rings.** In every view, the room's other wall views and every doorway in sight show as tap rings; anything off screen pins to the screen edge with an arrow. There is no back button.
- **Chapter objects** work the same way: close-up first, then the action starts the chapter (for the Loss, picking up the keys).
- **House objects** (objects that don't start a chapter) are never required, never scored and never saved. What the House shows still comes only from the finished-chapter list. Any words on them are Dan's to write.

Why: standing at the doorway, then looking at what you tapped, is what Dan expected in the M0 check. Close views hide the flaws of AI-made art. One verb (tap to look closer, tap again to act) works for walls, House objects and chapter objects alike.

## Consequences

- Each room needs a doorway view plus 2–4 wall views, framed by hand. M1 has about 15 views ([house-floor-plan.md](../design/house-floor-plan.md)).
- Story beats fire on arriving at a view (the opening beat on first arriving at the living room's doorway view).
- House objects are environmental storytelling; each gets a lifeline in [continuity-ledger.md](../design/continuity-ledger.md), the same for every player.
- Roadmap success criterion 2 (find the first object within about 3 minutes) must still hold with more views; the floor plan says how.
