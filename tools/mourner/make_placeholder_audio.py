"""The Mourner's PLACEHOLDER sounds, all generated here (no recordings).

    python3 tools/mourner/make_placeholder_audio.py

Built from docs/design/story-beats.md §7 (an acoustic or piano score that
thins at the memory box; a soft household sound for each placement).
Writes game/assets/audio/mourner/:

- placeholder_score_full.wav: 32 s of slow, quiet piano (70 a minute, eight
  bars), a seamless loop: low chords and a few high notes.
- placeholder_score_thin.wav: the same 32 s with only the sparse low notes,
  so the two play together and the full layer can fade out at the memory
  box, leaving the thin one.
- placeholder_place.wav: something set down softly on wood or carpet.
- placeholder_bag.wav: something put into a cloth bag or a tote, a soft rustle.

Every sound here is a PLACEHOLDER until real ones are picked (ADR-0010).
Needs numpy; only used to regenerate the sound, not by the game.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "partner"))
from make_placeholder_audio import write_wav  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/mourner"
SR = 22050
RNG = np.random.default_rng(17)
BEAT = 60.0 / 70.0
BARS = 8
LENGTH = BARS * 4 * BEAT  # About 27.4 s.


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def piano(freq, dur, lvl):
    """A soft piano-like note: a few decaying partials, the high ones faster."""
    n = int(dur * SR)
    t = np.arange(n) / SR
    tone = np.zeros(n)
    for k, amp in enumerate([1.0, 0.45, 0.22, 0.1, 0.05], start=1):
        tone += amp * np.exp(-t * (0.9 + 0.8 * k)) * np.sin(2 * np.pi * freq * k * 1.0008 ** k * t)
    attack = np.minimum(t / 0.008, 1.0)
    return lvl * attack * tone


def add(mix, start, sound):
    """Adds `sound` at `start` seconds, wrapping round the end so it loops."""
    i = int(round(start * SR)) % len(mix)
    for k in range(0, len(sound), len(mix)):
        part = sound[k:k + len(mix)]
        end = i + len(part)
        if end <= len(mix):
            mix[i:end] += part
        else:
            cut = len(mix) - i
            mix[i:] += part[:cut]
            mix[:end - len(mix)] += part[cut:]


# A slow progression, two bars each: C, Am, F, G (with soft sevenths).
CHORDS = [
    [48, 55, 64, 71], [48, 55, 64, 67],
    [45, 52, 60, 67], [45, 52, 60, 64],
    [41, 48, 57, 64], [41, 48, 57, 60],
    [43, 50, 59, 65], [43, 50, 55, 62],
]
# A few high notes, placed by beat; rests most of the time.
MELODY = {0: 76, 3: 74, 6: 72, 10: 72, 12: 71, 16: 69, 19: 72, 22: 74, 26: 74, 28: 71}


def score(full):
    mix = np.zeros(int(LENGTH * SR))
    for bar, chord in enumerate(CHORDS):
        start = bar * 4 * BEAT
        add(mix, start, piano(hz(chord[0]), 6.0, 0.22))  # The low note: both layers.
        if full:
            for k, m in enumerate(chord[1:]):  # A gently broken chord.
                add(mix, start + (k + 1) * BEAT * 0.5, piano(hz(m), 5.0, 0.11))
        else:
            add(mix, start + 2 * BEAT, piano(hz(chord[1]), 5.0, 0.08))
    if full:
        for beat, m in MELODY.items():
            add(mix, beat * BEAT, piano(hz(m), 3.5, 0.09))
    return mix * (0.5 / max(np.max(np.abs(mix)), 1e-6))


def place():
    """A soft knock: a low thud with a little wooden ring."""
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    thud = np.sin(2 * np.pi * 95 * t) * np.exp(-t / 0.05)
    ring = 0.3 * np.sin(2 * np.pi * 410 * t) * np.exp(-t / 0.03)
    noise = 0.15 * RNG.standard_normal(n) * np.exp(-t / 0.01)
    return 0.6 * (thud + ring + noise)


def bag():
    """A soft rustle: filtered noise rising and falling twice."""
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    noise = RNG.standard_normal(n)
    smooth = np.convolve(noise, np.ones(6) / 6, mode="same") - np.convolve(noise, np.ones(40) / 40, mode="same")
    shape = np.exp(-((t - 0.12) / 0.07) ** 2) + 0.6 * np.exp(-((t - 0.34) / 0.09) ** 2)
    knock = np.zeros(n)
    soft = place()
    knock[:len(soft)] = soft
    return 0.5 * smooth * shape + 0.3 * knock


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "placeholder_score_full.wav", score(True), SR)
    write_wav(OUT / "placeholder_score_thin.wav", score(False), SR)
    write_wav(OUT / "placeholder_place.wav", place(), SR)
    write_wav(OUT / "placeholder_bag.wav", bag(), SR)
    print("Wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
