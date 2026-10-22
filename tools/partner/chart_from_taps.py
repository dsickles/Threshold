"""Turns Dan's recorded taps into the Partner's notes (eighths from bar 1 beat 1).

    python3 tools/partner/make_chart.py   # Reads every tools/partner/taps/*.txt

Dan, 2026-10-22: the measured chart "may technically be on some sort of beat
... but it's not a fun rhythm aligned with what I hear", so he records the way
he wants to tap (the Partner's "Record my taps", chart_recorder.gd) and pastes
the line it gives. "I'm not going to get it perfect on my first try so you'll
have to modulate it at least a bit". So, in order:

1. Takes: each file holds one or more "partner-taps from=<ms>: <ms>,<ms>,..."
   lines. A later take replaces the earlier ones from where it starts, so a
   section can be re-recorded.
2. Timing: his taps land a little late by the same amount all through (about
   45 ms in his first take); that amount is the middle of how far each tap is
   from the nearest eighth, and is taken off every tap.
3. Snap: each tap moves to the nearest eighth, the finest he tapped. Two taps
   on one eighth are one note.
4. The chart's rules: nothing in the stumble's rest, and the last note on bar
   65 beat 1. Where he didn't tap stays empty until he says to fill it.

His first take had pairs of notes an eighth (333 ms) apart, on the "and" of 3,
faster than the 500 ms he asked for on 2026-10-20 (when the crescendo's fast
triplets were "too fast"). They are his rhythm, so they stay; the closest any
two notes may be is now one eighth.
"""
import re
import statistics



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


def notes_from_taps(paths, beat_ms, silent_bars, last_bar):
    eighth_ms = beat_ms / 2
    taps = merge(read_takes(paths))
    late = lateness(taps, eighth_ms)
    last = (last_bar - 1) * 8  # In eighths from bar 1 beat 1, 8 a bar.
    snapped = [round((t - late) / eighth_ms) for t in taps]
    notes = sorted({e for e in snapped if 0 <= e < last and e // 8 + 1 not in silent_bars})
    notes.append(last)
    report = {"taps": len(taps), "late_ms": round(late), "notes": len(notes),
              "doubled_taps": len(taps) - len(set(snapped)),
              "off_by_more_than_80_ms": sum(abs(t - late - e * eighth_ms) > 80
                                            for t, e in zip(taps, snapped))}
    return notes, report
