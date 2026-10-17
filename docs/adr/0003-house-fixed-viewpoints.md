---
status: accepted
date: 2026-10-17
supersedes: "tap the floor to walk" in game-architecture §2.3, EXPERIENCE Interaction Primitives, FR34, UX-DR24, Story 1.1
---

# The House uses fixed viewpoints, not free walking

In v1 the player moves through the House by tapping a **viewpoint** (a spot or a doorway), and the camera glides to a framed shot. They do not tap any point on the floor to walk there. A short look-drag at a viewpoint is still allowed. Tapping an object still uses it.

Why: free walking needs path-finding, collisions, and art that holds up from every angle. With AI-generated assets and one person building, fixed shots are much less work, they hide asset flaws, and they let every story beat be framed like a film shot. The cost is some feeling of freedom, which careful framing and smooth camera moves mostly make up for.

## Consequences

- The House is still real 3D (simple models, lamp light, fog), not painted images. Changing the House after a chapter means moving objects and changing light, which stays consistent.
- The one-tap-scheme rule is unchanged: tap is still the only verb, on every platform.
