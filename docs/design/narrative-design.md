# Threshold - Narrative Design Document

**Author:** Dan (with Samus Shepard)
**Game Type:** Narrative Anthology
**Narrative Complexity:** High (Emotional, Metaphorical, Non-Linear)
**2026-10-17:** Copied out of BMAD into `docs/design/`. Updated for one result per chapter (2026-09-22), [ADR-0004](../adr/0004-journal-wording-varies-no-mastery.md) (journal wording) and [ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md) (text dialogue in v1). Timeline aligned with the epics.

---

## Executive Summary

### Narrative Premise

_Threshold_ is the story of a man trying to build a home for a family he isn't sure he's ready for, while battling the silent ghosts of infertility and anxiety. It is a journey from the self-centered "Me" to the selfless "Us," told through the lens of a house that physically manifests his internal state.

### Core Themes

- **Transition:** The liminal space between who you were and who you must become.
- **Vulnerability:** The strength found in admitting fear and weakness.
- **Resilience:** The quiet endurance required to keep trying after loss.
- **Connection:** Finding intimacy in the mundane and the difficult.

### Tone and Atmosphere

- **Grounded & Raw:** The dialogue and situations are hyper-realistic (IVF shots, assembling furniture, quiet arguments).
- **Surreal & Metaphorical:** The gameplay and the House's reaction to it are dreamlike and expressive.
- **Balanced:** The weight of grief is counterbalanced by the absurdity of new parenthood and the warmth of genuine love. **Every segment, no matter how dark, contains at least one moment of levity or human awkwardness.**

---

### Story Structure

### Story Type

- **Excitement (Partner)** -> **Tragedy (Protector)** -> **Humor/Absurdity (Novice)** -> **Anxiety (Provider)** -> **Connection (Tuner)** -> **Growth (Anchor)** -> **Acceptance (Mourner)**.

---

## Characters

### Protagonist: "The Dad" (Player)

- **Name:** Leo.
- **Personality:** A fixer. He wants to solve problems with logic and effort. He struggles to sit with uncomfortable emotions.
- **Arc:** Learning that he can't "fix" everything. Learning to be present rather than just productive.
- **Flaw:** Believes his value comes from what he _provides_, not who he _is_.

### Deuteragonist: "The Mom" (Maya)

- **Role:** The emotional anchor. She is going through the physical reality of this journey.
- **Personality:** Witty, resilient, but **anxious**. She over-researches everything and worries about small, everyday details (e.g., "Is this milk expired?" "Did we lock the back door?").
- **Humor:** Her anxiety is a source of "couple comedy." Leo teases her gently, and they bond over the absurdity of her worries.
- **Dynamic:** They are a team. Leo tries to "fix" her anxiety, while she just wants him to listen to it.

### The House (Antagonist/Ally)

- **Role:** The physical manifestation of Leo's psyche.
- **Behavior:** It creaks when he is anxious. It glows when he is hopeful. It rots when he is grieving.

---

### Dialogue Style

- **Naturalistic:** Overlapping speech, unfinished sentences, "couple shorthand."
- **Subtext-Heavy:** What isn't said is often more important. (e.g., Asking "Did you pay the gas bill?" instead of "Are we going to be okay?").

### Key Conversations

1.  **The Injection (Act 1):** Maya asks Leo to help with her IVF shot. He is terrified of hurting her.
2.  **The Silence (Act 2):** After the loss, sitting in the car. No words, just the sound of rain.
3.  **The Panic (Act 3):** Leo tries to build the crib without instructions. Maya laughs, breaking the tension.

---

## Integration with Gameplay

### Narrative-Gameplay Harmony

- **Ludonarrative Consistency:** The mechanics _are_ the feelings. We don't tell the player "The insurance company is confusing," we force them to cross-reference three different forms in _The Provider_ to find a typo.
- **Authored Narrative:** In _The Provider_ and _The Protector_, the bills and obstacles are a fixed, hand-written sequence, not random. A sequence of bills tells the story of one specific injury.
- **Story Gates:** Completing a minigame is the "Key" to unlock the next room/chapter in the House.

### Player Agency

- **Micro-Choices:** In dialogue, choosing to be "Stoic" (closed-off) or "Vulnerable" (open). This doesn't change the plot, the House objects, or the big story beats, but changes the _tone_ of the scene and the wording of the matching Journal entry ([ADR-0004](../adr/0004-journal-wording-varies-no-mastery.md)).

---

## Production Notes

### Writing Scope

- ~5,000 words of dialogue.
- ~2,000 words of journal entries/flavor text.

### Voice Acting

_Not in v1 ([ADR-0005](../adr/0005-ai-assets-text-dialogue-v1.md)): v1 dialogue is text with subtitles. The plan below is for a later version._

- **Leo:** Internal Monologue (Heavy), Dialogue (Medium).
- **Maya:** Dialogue (Medium).
- **The Boss/Doctor/etc.:** Muffled, indistinct voices (Charlie Brown style) to keep focus on the couple.

---

## Appendix

### Timeline

- **Month 0:** Natural Conception (_Partner_).
- **Month 2:** Miscarriage (_Protector_).
- **Month 3-9:** **The Long Haul (IVF).** 6 months of retrievals. (_Novice_).
  - _Note:_ Starts desaturated and quiet. Color and chaos bleed in as the hormones take effect.
- **End of Month 9:** Conception via IVF (positive test at the end of _The Novice_).
- **Month 10:** The bills for the pregnancy (_Provider_).
- **Month 12:** The Wait begins: hearing the heartbeat (_Tuner_).
- **Month 17:** The last weeks (_Anchor_, then _Mourner_).
- **Month 18:** The Arrival, at full term (about 40 weeks). _(Updated 2026-10-25, [ADR-0009](../adr/0009-full-term-pregnancy-timeline.md).)_

### References

- _Marriage Story_ (Dialogue style).
- _Bluey_ (For the "Novice" humor).
- _Up_ (The opening montage, for emotional efficiency).
