"""Turns Dan's recorded taps into the Partner's notes (eighths from bar 1 beat 1).

    python3 tools/partner/make_chart.py --taps tools/partner/taps/*.txt

Dan, 2026-10-22: the measured chart "may technically be on some sort of beat
... but it's not a fun rhythm aligned with what I hear", so he records the way
he wants to tap (the Partner's "Record my taps", chart_recorder.gd) and pastes
the line it gives. "I'm not going to get it perfect on my first try so you'll
have to modulate it at least a bit". So, in order:

1. Takes: each file holds one or more "partner-taps from=<ms>: <ms>,<ms>,..."
   lines. A later take replaces the earlier ones from where it starts, so a
   section can be re-recorded.
2. Timing: his taps land a little late (or early) by the same amount all
   through; that amount is the middle of how far each tap is from the nearest
   eighth, and is taken off every tap.
3. Snap: each tap moves to the nearest sixteenth.
4. Tidy: within each section's two-bar phrases, a place he tapped in at least
   half of the phrases is a note in all of them, and one he tapped only now
   and then is dropped, so a slip in one bar doesn't stick. The last phrase of
   each section keeps his taps as they are (a fill into the next section).
5. Speed: no two notes closer than 500 ms (Dan, 2026-10-20); of two too close,
   the one nearer the beat stays.
6. The rest of the chart's rules: nothing in the stumble's rest, and the last
   note on bar 65 beat 1.
"""
import re
import statistics

EIGHTH = 1.0  # Units: eighths.
SIXTEENTHS = 2  # Per eighth.
PHRASE = 2  # Bars.


def read_takes(paths):
    takes = []
    for path in paths:
        for line in open(path, encoding="utf-8"):
            m = re.search(r"partner-taps from=(-?\d+):\s*([\d,\s-]*)", line)
            if m:
                taps = [int(x) for x in m.group(2).replace(" ", "").split(",") if x]
                takes.append((int(m.group(1)), taps))
    assert takes, "no partner-taps lines found"
    return takes


def merge(takes):
    """Later takes win from where they start."""
    taps = []
    for start, take in takes:
        taps = [t for t in taps if t < start] + [t for t in take if t >= start]
    return sorted(taps)


def lateness(taps_ms, eighth_ms):
    offsets = [((t + eighth_ms / 2) % eighth_ms) - eighth_ms / 2 for t in taps_ms]
    return statistics.median(offsets)


def notes_from_taps(paths, beat_ms, sections, silent_bars, last_bar, bars):
    eighth_ms = beat_ms / 2
    taps = merge(read_takes(paths))
    late = lateness(taps, eighth_ms)
    sixteenth_ms = eighth_ms / SIXTEENTHS
    # In sixteenths from bar 1 beat 1. 32 a bar.
    per_bar = 8 * SIXTEENTHS
    slots = sorted({round((t - late) / sixteenth_ms) for t in taps})
    last = (last_bar - 1) * per_bar
    slots = [s for s in slots if 0 <= s < last and (s // per_bar + 1) not in silent_bars]

    # Tidy each section's two-bar phrases.
    tapped = set(slots)
    firsts = [first for first, _ in sections]
    kept = set()
    for k, first in enumerate(firsts):
        end = firsts[k + 1] if k + 1 < len(firsts) else bars + 1
        end = min(end, last_bar)
        phrases = [b for b in range(first, end, PHRASE) if b + PHRASE <= end]
        if len(phrases) < 3:
            kept |= {s for s in tapped if first <= s // per_bar + 1 < end}
            continue
        length = PHRASE * per_bar
        votes = {}
        for b in phrases[:-1]:
            for p in range(length):
                if (b - 1) * per_bar + p in tapped:
                    votes[p] = votes.get(p, 0) + 1
        common = {p for p, n in votes.items() if n * 2 >= len(phrases) - 1}
        for b in phrases[:-1]:
            kept |= {(b - 1) * per_bar + p for p in common}
        # The last phrase, and any odd bar left over, as he tapped them.
        kept |= {s for s in tapped if phrases[-1] <= s // per_bar + 1 < end}
    kept -= {s for s in kept if (s // per_bar + 1) in silent_bars}

    # No two closer than 500 ms: of two too close, the one nearer the beat.
    def weight(s):
        return 0 if s % (2 * SIXTEENTHS) == 0 else 1 if s % SIXTEENTHS == 0 else 2
    gap = 500 / sixteenth_ms
    chosen = [last]
    for s in sorted(kept, key=lambda s: (weight(s), s)):
        if all(abs(s - c) >= gap for c in chosen):
            chosen.append(s)
    chosen = sorted(chosen)[:-1]
    chosen.append(last)
    report = {"taps": len(taps), "late_ms": round(late), "notes": len(chosen),
              "dropped_by_tidy": len(tapped - kept), "added_by_tidy": len(kept - tapped), "dropped_as_too_fast": len(kept) - (len(chosen) - 1)}
    return [s / SIXTEENTHS for s in chosen], report
