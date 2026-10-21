"""PLACEHOLDER sounds for the Partner, until Dan picks the real ones.

    python3 tools/partner/make_placeholder_audio.py

Writes game/assets/audio/partner/:
- placeholder_celebrate.wav: a bright rising chime for the test appearing.
- placeholder_miss_1..3.wav: short wordless "hm" sounds standing in for the
  awkward laughter.

The song is no longer made here: Dan picked a real track on 2026-10-21 (the
generated one was "too '80s videogamey"), edited by make_song.py, which also
borrows this file's heartbeat thump and tap bell.

Needs numpy; only used to regenerate these files, not by the game.
"""
import pathlib
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/partner"
SR = 44100


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def add(mix, start, sound):
    i = int(round(start * SR))
    j = min(len(mix), i + len(sound))
    if 0 <= i < len(mix):
        mix[i:j] += sound[: j - i]


def env(dur, attack, decay):
    t = np.arange(int(dur * SR)) / SR
    return np.minimum(t / attack, 1.0) * np.exp(-t / decay), t


def keys(freq, dur, lvl):
    """An electric-piano note: a soft FM bell with a little tremolo."""
    e, t = env(dur, 0.006, dur * 0.45)
    index = 1.8 * np.exp(-t / 0.25) + 0.3
    tone = np.sin(2 * np.pi * freq * t + index * np.sin(2 * np.pi * freq * t))
    return lvl * e * tone * (1 + 0.15 * np.sin(2 * np.pi * 4.5 * t))


def thump(freq, dur=0.3, decay=0.08, lvl=0.8):
    e, t = env(dur, 0.003, decay)
    sweep = freq * (1 + 1.2 * np.exp(-t / 0.025))
    return lvl * e * np.sin(2 * np.pi * np.cumsum(sweep) / SR)


def bell(freq, lvl):
    """The tap cue: a short, clear bell on every chart note."""
    e, t = env(0.5, 0.002, 0.14)
    return lvl * e * (np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * 3.01 * freq * t))


def celebrate():
    """A bright rising arpeggio that blooms into a shimmering chord."""
    length = 5.0
    mix = np.zeros(int(length * SR))
    notes = [60, 64, 67, 71, 74, 76, 79, 83, 84]
    for k, m in enumerate(notes):
        add(mix, k * 0.09, keys(hz(m), 2.5, 0.10))
        add(mix, k * 0.09, bell(hz(m + 12), 0.08))
    _, t = env(length - 0.8, 0.5, 2.0)
    e = np.minimum(t / 0.6, 1.0) * np.exp(-t / 1.6)
    shimmer = sum(np.sin(2 * np.pi * hz(m) * t * (1 + 0.003 * np.sin(2 * np.pi * 6 * t)))
                  for m in [72, 76, 79, 83, 86])
    add(mix, 0.8, 0.05 * e * shimmer)
    rng = np.random.default_rng(3)
    for k in range(18):  # Sparkles.
        add(mix, 0.8 + rng.uniform(0, 2.5), bell(hz(rng.choice([88, 91, 95, 96])), 0.04))
    return mix / max(1.0, np.max(np.abs(mix)) / 0.8)


def miss(seed):
    """Two falling 'hm' tones, slightly different each time."""
    rng = np.random.default_rng(seed)
    base = 220 * rng.uniform(0.85, 1.25)
    parts = []
    for f in [base * 1.12, base]:
        e, t = env(0.18, 0.02, 0.09)
        vib = 1 + 0.02 * np.sin(2 * np.pi * 6 * t)
        parts.append(0.35 * e * np.sin(2 * np.pi * np.cumsum(f * vib) / SR))
        parts.append(np.zeros(int(0.04 * SR)))
    return np.concatenate(parts)


def write_wav(path, samples, rate=SR):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "placeholder_celebrate.wav", celebrate())
    for k in range(1, 4):
        write_wav(OUT / f"placeholder_miss_{k}.wav", miss(k))
    print("Wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
