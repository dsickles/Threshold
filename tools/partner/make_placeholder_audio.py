"""PLACEHOLDER audio for the Partner, until Dan picks the real song and laughs.

    python3 tools/partner/make_placeholder_audio.py

Writes game/assets/audio/partner/placeholder_song.mp3 (120 BPM, 104 bars,
bar 1 beat 1 at 0:00, a soft pluck on every chart note so the beat is easy to
hear) and placeholder_miss_1..3.wav (short wordless "hm" sounds standing in for
the awkward laughter). Needs numpy and ffmpeg; only used to regenerate these
files, not by the game.
"""
import json
import pathlib
import subprocess
import tempfile
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/partner"
CHART = json.loads((ROOT / "game/scenes/chapters/partner/beat_chart.json").read_text())
SR = 44100
BEAT = 0.5
BAR = 4 * BEAT
LENGTH = CHART["song_length_ms"] / 1000

# One chord every 4 bars: C, A minor, F, G (MIDI note numbers).
CHORDS = [[60, 64, 67], [57, 60, 64], [53, 57, 60], [55, 59, 62]]
SILENT_BAR = 48
LAST_NOTE = CHART["notes_ms"][-1] / 1000


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def chord_at(t):
    return CHORDS[int(t // (4 * BAR)) % 4]


def section_level(t):
    bar = int(t // BAR) + 1
    if bar <= 8:
        return 0.5
    if bar <= 32:
        return 0.6
    if bar <= 56:
        return 0.75
    if bar <= 88:
        return 0.9
    return 1.0


def add(mix, start, sound):
    i = int(round(start * SR))
    j = min(len(mix), i + len(sound))
    if 0 <= i < len(mix):
        mix[i:j] += sound[: j - i]


def env(dur, attack, decay):
    t = np.arange(int(dur * SR)) / SR
    return np.minimum(t / attack, 1.0) * np.exp(-t / decay), t


def thump(freq, dur=0.25, decay=0.07, level=0.8):
    e, t = env(dur, 0.003, decay)
    sweep = freq * (1 + 1.5 * np.exp(-t / 0.02))
    return level * e * np.sin(2 * np.pi * np.cumsum(sweep) / SR)


def pluck(freq, level=0.25):
    e, t = env(0.35, 0.004, 0.12)
    return level * e * (np.sin(2 * np.pi * freq * t) + 0.3 * np.sin(4 * np.pi * freq * t))


def noise_hit(dur, decay, level, seed):
    e, _ = env(dur, 0.001, decay)
    return level * e * np.random.default_rng(seed).uniform(-1, 1, len(e))


def song():
    n = int(LENGTH * SR)
    mix = np.zeros(n)
    t = np.arange(n) / SR

    # Pad: the chord, quiet, rising with the sections; silent in bar 48.
    bars = (t // BAR).astype(int) + 1
    level = np.vectorize(section_level)(t) * 0.05
    level[bars == SILENT_BAR] = 0
    level[t >= LAST_NOTE] = 0
    for k in range(3):
        f = np.array([hz(CHORDS[c][k] - 12) for c in range(4)])[(t // (4 * BAR)).astype(int) % 4]
        mix += level * np.sin(2 * np.pi * np.cumsum(f) / SR)

    for beat_i in range(int(LENGTH / BEAT)):
        bt = beat_i * BEAT
        bar = beat_i // 4 + 1
        beat_in_bar = beat_i % 4 + 1
        if bar == SILENT_BAR or bt >= LAST_NOTE:
            continue
        if bar <= 32:
            if beat_in_bar in (1, 3):  # the heartbeat, 60 a minute
                add(mix, bt, thump(50, level=0.7))
        else:
            add(mix, bt, thump(55, level=0.55 * section_level(bt)))  # kick on every beat
        if bar >= 57:
            add(mix, bt + BEAT / 2, noise_hit(0.05, 0.012, 0.08, beat_i))  # off-beat hat
        if 89 <= bar <= 100 and beat_in_bar in (2, 4):
            add(mix, bt, noise_hit(0.15, 0.04, 0.25, beat_i))  # claps

    # A pluck on every chart note, so the placeholder shows what to tap.
    for i, ms in enumerate(CHART["notes_ms"]):
        nt = ms / 1000
        tone = chord_at(nt)[i % 3] + 12
        add(mix, nt, pluck(hz(tone), level=0.22 + 0.1 * section_level(nt)))

    # The last note is the biggest; then one held chord rings out.
    add(mix, LAST_NOTE, thump(50, dur=0.6, decay=0.2, level=1.0))
    ring = np.arange(int((LENGTH - LAST_NOTE) * SR)) / SR
    chord = sum(np.sin(2 * np.pi * hz(m) * ring) for m in [48, 60, 64, 67, 72])
    add(mix, LAST_NOTE, 0.08 * chord * np.minimum(ring / 0.02, 1) * np.exp(-ring / 3.0))

    return mix / max(1.0, np.max(np.abs(mix)) / 0.9)


def miss(seed):
    """Two falling 'hm' tones, slightly different each time."""
    rng = np.random.default_rng(seed)
    base = 220 * rng.uniform(0.85, 1.25)
    parts = []
    for k, f in enumerate([base * 1.12, base]):
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
    with tempfile.TemporaryDirectory() as tmp:
        wav = pathlib.Path(tmp) / "song.wav"
        write_wav(wav, song())
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-ac", "1",
                        "-b:a", "64k", str(OUT / "placeholder_song.mp3")], check=True)
    for k in range(1, 4):
        write_wav(OUT / f"placeholder_miss_{k}.wav", miss(k))
    print("Wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
