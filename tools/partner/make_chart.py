"""Writes the Partner's beat chart (game/scenes/chapters/partner/beat_chart.json)
from the bar-by-bar table in the draft song and beat chart, and checks it.

    python3 tools/partner/make_chart.py              # From the plan below (PLAN)
    python3 tools/partner/make_chart.py --taps       # From Dan's taps in tools/partner/taps/
    python3 tools/partner/make_chart.py --measured   # The older chart measured from the track

The table below is the source; the JSON is generated. Edit here, re-run, commit both.
Started from the draft m1-prep/partner-song-and-beat-chart.md; the chart is
now Dan's own plan (PLAN, below).

Dan, 2026-10-20, after playing the first build: "a little hard ... most people
should be able to get most beats on at least good, with less than 5 misses
during the whole run." So this chart is calmer than the draft's table: no two
notes closer than 500 ms (the draft had 250 ms), and the build-up comes from
more notes per bar, not faster ones. Dan, later the same day: "too singular beat
focused and boring, there needs to be some more variation in the beat, but as
long as it isn't too fast". So some notes fall halfway between beats, never
closer than 500 ms to the next.

Dan, 2026-10-21, asked for "a real crescendo" in the last bars. Triplets
333 ms apart were "too fast" when he played them, so the crescendo is a note on
every beat for 12 bars: the longest run in the song, never faster than 500 ms,
while the colours bloom.

Dan, later on 2026-10-21, swapped the generated song for a real track ("Dreamy
Lo-Fi Beat", Pixabay, 90 BPM), edited by tools/partner/make_song.py. The bars
below follow its sections: soft intro (1-8), beat (9-20), drums down (21-27),
the stumble (28), beat (29-40), quiet breakdown (41-48), the fullest part
(49-56, then repeated as 57-64), the last note on bar 65 and the outro.

Dan, after playing it: "The tap should [go] along with the song. Period." The
first chart for the track kept the old patterns, so many notes fell where the
track has nothing. Now every note is on a hit measured in the track: in the
beat, the kick on 1 and the "and" of 3, the snare on 2 and 4, and in the
fullest part the extra kick on the last quarter of beat 2 (odd bars) and just
after 4 (even bars); in the soft opening, the heartbeat; with the drums down,
the keys' own rhythm. The track's hits land 25 ms after its bar lines (measured
from the snare's attack), so START_OFFSET_MS is 25.

Dan, playing that: "The beats are off ... Not on rhythm ... It was off like 15
seconds in". The kick on 1 and the "and" of 3 is too low for a phone's speaker
to play, so those notes fell where a phone plays nothing, and in the soft
opening the keys don't hit on 1 and 3 at all. So the bar table now says only
how many notes each bar gets, and pick_notes() puts them on the loudest eighths
of that bar as a phone plays the track (nothing below 300 Hz), measured from
the edited track itself: mostly the snare on 2 and 4 and the hit on 3, the
keys in the opening and with the drums down. The crescendo can't have a note
on every beat any more: its beat 1 is the kick, which the track ducks
everything else under, so on a phone it is the quietest moment of the bar.
It has three a bar on its clear hits (2, 3 and 4) for 12 bars, the longest
run in the song. main() fails if any note but the last is quieter than the
middle eighth of its bar (the last is the outro's first chord, on beat 1). Needs numpy, ffmpeg and the Pixabay download, like
make_song.py; run this first, then make_song.py.

Dan, playing that: the notes still felt "boring and then not in rhythm" with
"what I hear", and "always the same". So he records how he wants to tap (the
Partner's "Record my taps" button, with the test info on), and the chart is
built from those taps (tools/partner/taps/, oldest file first; chart_from_taps.py
says how they are tidied). Re-run make_song.py after: its heartbeat starts on
the first note's bar.

Dan, after two takes: "let's discuss the general approach. I want to start a
little earlier than the first one. Then start slow on single beats. And then
use how I modulated the next sections to design" it; he liked how the first
take ended, and the second felt "a little too fast". Playing the plan, "the
end was too fast", so its ending is calmer than his take. So the chart is PLAN
below, each section's rhythm taken from his takes (tools/partner/taps/, the
second in not-used/), with at most one quick "and" a bar except the final run.
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

BPM = 90
BEAT_MS = 60000 / BPM
BARS = 69
# Where bar 1, beat 1 falls in the song file: the track's hits land 25 ms after
# its bar lines (measured from the snare's attack in tools/partner/make_song.py's
# output).
START_OFFSET_MS = 25
# The Pixabay download (not in the repo; see make_song.py).
SOURCE = pathlib.Path("/mnt/project-files/partner/source-dreamy-lo-fi-beat-549997.mp3")
INTRO_BARS = 8  # Intro taps set the player's sound delay and never laugh.

# How many notes each bar gets; which beats they fall on is measured from the
# track (see pick_notes). X is the last note, on beat 1; - is none.
# (first bar, counts in order).
SECTIONS = [
    (1, "--"),
    (3, "222222"),           # The soft opening
    (9, "2222" "2222" "2233"),  # The beat: the snare on 2 and 4, then more
    (21, "2222222" "-"),     # Drums down, then the stumble
    (29, "3222" "3333" "3333"),  # The beat
    (41, "2222" "2222"),     # The quiet breakdown, into the fullest part
    (49, "3333"),            # The fullest part
    (53, "3333" "3333" "3333"),  # The crescendo: the fullest part again
    (65, "X"),
    (66, "----"),
]
# Dan's agreed plan, 2026-10-22: (first bar, last bar, beats in the bar
# counted from 0, in halves). 2.5 is the "and" of beat 3.
EVERY = [0, 1, 2, 3]
PLAN = [
    (4, 5, [0]),                     # The intro: slow, single beats
    (6, 8, [0, 2]),
    (9, 12, [0, 2]),                 # The first beat
    (13, 17, EVERY),
    (18, 18, [0, 1, 2, 2.5, 3]),     # A lift at the end of a phrase
    (19, 19, EVERY),
    (20, 20, [0, 1, 2, 2.5, 3]),
    (21, 27, [0, 2]),                # Drums down, calmer
    (28, 28, [0]),                   # The stumble starts
    (29, 36, [0, 1, 2, 2.5, 3]),     # After the stumble, in both his takes
    (37, 44, [1, 3]),                # The quiet part: the backbeat
    (45, 46, [1, 2, 3]),             # building
    (47, 47, EVERY),
    (48, 48, [0, 1, 2, 3, 3.5]),     # into the fullest part
    (49, 56, [1, 2.5, 3]),           # "2 ... 3-and 4", his first take
    # His first take's ending, calmed: it was "too fast" to play, so it
    # builds in steps instead (Dan, 2026-10-22: the calmed ending "doesn't
    # build anymore. it needs a little more oomph, but not as much as the
    # original"): the "and" of 3 every other bar, then every bar, then a short
    # run of three eighths into the final note, not a whole bar of them.
    (57, 57, EVERY),
    (58, 58, [0, 1, 2, 2.5, 3]),
    (59, 59, EVERY),
    (60, 60, [0, 1, 2, 2.5, 3]),
    (61, 63, [0, 1, 2, 2.5, 3]),
    (64, 64, [0, 1, 2, 2.5, 3, 3.5]),
    (65, 65, [0]),                   # The last note
]
SILENT_BARS = {28}  # The stumble: the track slows to a halt and rests.
CRESCENDO_BAR = 53
LAST_BAR = 65
NOTE_COUNT = 144  # Only the --measured chart.


def bar_counts():
    bars = {}
    for first, counts in SECTIONS:
        for i, n in enumerate(counts):
            bars[first + i] = "-" if first + i in SILENT_BARS else n
    assert sorted(bars) == list(range(1, BARS + 1)), "every bar needs a count"
    return bars


def strengths():
    """How strongly the track hits on each eighth of each bar, as a phone's
    speaker plays it (nothing below 300 Hz): the rise in loudness at that
    moment, against the bar's middle one."""
    import numpy as np
    import make_song
    sr = make_song.SR
    track = make_song.ffilter(make_song.arrange(make_song.decode(SOURCE)), make_song.TREBLE_CUT)
    track = make_song.ffilter(track, "highpass=f=300:poles=2")
    hop, win = 220, 1024
    frames = np.lib.stride_tricks.sliding_window_view(track, win)[::hop] * np.hanning(win)
    spec = np.log1p(20 * np.abs(np.fft.rfft(frames, axis=1)))
    rise = np.concatenate([[0], np.maximum(0, np.diff(spec, axis=0)).sum(1)])
    times = np.arange(len(rise)) * hop / sr + win / 2 / sr
    out = {}
    for bar in range(1, BARS + 1):
        row = []
        for e in range(8):
            t = START_OFFSET_MS / 1000 + ((bar - 1) * 4 + e / 2) * BEAT_MS / 1000
            row.append(rise[(times > t - 0.03) & (times < t + 0.06)].max())
        out[bar] = np.array(row) / max(1e-9, np.median(row))
    return out


def pick_notes(counts, strength):
    """In each bar, the loudest eighths, at least two eighths (667 ms) apart,
    up to the bar's count.
    Each bar's strengths are averaged with the other bars of its section that
    fall on the same side (odd or even), so a groove repeats as the track does."""
    import numpy as np
    section_of = {}
    for first, cs in SECTIONS:
        for i in range(len(cs)):
            section_of[first + i] = first
    notes = []  # In eighths from bar 1 beat 1.
    for bar in range(1, BARS + 1):
        n = counts[bar]
        if n == "-":
            continue
        if n == "X":
            notes.append((bar - 1) * 8)
            continue
        same = [b for b in strength if section_of[b] == section_of[bar] and b % 2 == bar % 2
                and counts[b] not in "-X"]
        score = 0.5 * strength[bar] + 0.5 * np.mean([strength[b] for b in same], axis=0)
        chosen = []
        # Only eighths that are a hit in this bar itself, so a bar with fewer
        # clear hits gets fewer notes.
        for e in sorted((e for e in range(8) if strength[bar][e] >= 1.0), key=lambda e: -score[e]):
            at = (bar - 1) * 8 + e
            if all(abs(at - c) >= 2 for c in chosen) and (not notes or at - notes[-1] >= 2):
                chosen.append(at)
            if len(chosen) == int(n):
                break
        notes += sorted(chosen)
    return notes


def plan_notes():
    """PLAN as eighths from bar 1 beat 1."""
    eighths = []
    for first, last, beats in PLAN:
        for bar in range(first, last + 1):
            eighths += [(bar - 1) * 8 + round(b * 2) for b in beats]
    assert eighths == sorted(set(eighths)), "PLAN overlaps or is out of order"
    return eighths


def main():
    if "--taps" not in sys.argv and "--measured" not in sys.argv:
        eighths = plan_notes()
        # The crescendo builds: its 12 bars are busier than any other 12.
        bars = [e // 8 + 1 for e in eighths]
        busiest = max(sum(first <= b < first + 12 for b in bars)
                      for first in range(1, CRESCENDO_BAR))
        crescendo = sum(CRESCENDO_BAR <= b < CRESCENDO_BAR + 12 for b in bars)
        assert crescendo > busiest, f"crescendo {crescendo} notes, another 12 bars {busiest}"
        return write_chart(eighths, None, min_gap=BEAT_MS / 2)
    if "--taps" in sys.argv:
        # Dan's own taps (chart_from_taps.py) decide where the notes go.
        import chart_from_taps
        paths = sorted((pathlib.Path(__file__).resolve().parent / "taps").glob("*.txt"))
        eighths, report = chart_from_taps.notes_from_taps(
            paths, BEAT_MS, SILENT_BARS, LAST_BAR)
        print(report)
        return write_chart(eighths, None, min_gap=BEAT_MS / 2)
    strength = strengths()
    eighths = pick_notes(bar_counts(), strength)
    # Every note on a hit (Dan: "The tap should [go] along with the song.
    # Period."): at least as loud as the bar's middle eighth, as a phone plays it.
    for e in eighths[:-1]:
        level = strength[e // 8 + 1][e % 8]
        assert level >= 1.0, f"bar {e // 8 + 1} beat {e % 8 / 2 + 1} is on no hit ({level:.2f})"
    if "--show" in sys.argv:
        for e in eighths:
            print(f"bar {e // 8 + 1:2d} beat {e % 8 / 2 + 1}: {strength[e // 8 + 1][e % 8]:.2f}")
    write_chart(eighths, NOTE_COUNT)


def write_chart(eighths, note_count, min_gap=500):
    notes = [round(e * BEAT_MS / 2) for e in eighths]

    # The checks the draft asks for, with Dan's 2026-10-20 easier chart.
    gaps = [b - a for a, b in zip(notes, notes[1:])]
    crescendo_ms = round((CRESCENDO_BAR - 1) * 4 * BEAT_MS)
    assert note_count is None or len(notes) == note_count, len(notes)
    assert min(gaps) >= min_gap - 1, min(gaps)
    assert notes[-1] == round((LAST_BAR - 1) * 4 * BEAT_MS), notes[-1]
    silent_ms = [[round(((b - 1) * 4 + 1.5) * BEAT_MS), round(((b - 1) * 4 + 3) * BEAT_MS)]
                 for b in sorted(SILENT_BARS)]
    for start, end in silent_ms:
        assert not [n for n in notes if start <= n < end], f"a note in the rest at {start}-{end} ms"

    chart = {
        "_comment": "Generated by tools/partner/make_chart.py. Times in ms from bar 1 beat 1; add start_offset_ms for the song file.",
        "bpm": BPM,
        "start_offset_ms": START_OFFSET_MS,
        "intro_end_ms": round(INTRO_BARS * 4 * BEAT_MS),
        "song_length_ms": round(BARS * 4 * BEAT_MS),
        # [start, end) in ms from bar 1 beat 1, where the track rests and the
        # heart stops: after the tape stop (1.5 beats) until the pickup (beat 4).
        "silent_ms": silent_ms,
        # Where the crescendo starts: denser notes, and the screen blooms.
        "crescendo_ms": crescendo_ms,
        "notes_ms": notes,
    }
    out = pathlib.Path(__file__).resolve().parents[2] / "game/scenes/chapters/partner/beat_chart.json"
    out.write_text(json.dumps(chart, indent=1) + "\n")
    print(f"{len(notes)} notes, closest gap {min(gaps)} ms, last at {notes[-1]} ms -> {out}")


if __name__ == "__main__":
    main()
