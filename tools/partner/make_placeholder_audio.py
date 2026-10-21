"""PLACEHOLDER audio for the Partner, until Dan picks the real song and laughs.

    python3 tools/partner/make_placeholder_audio.py

Writes game/assets/audio/partner/:
- placeholder_song.mp3: neo-soul (Dan's pick, 2026-10-20), 120 BPM felt as a
  slow half-time groove, 104 bars, bar 1 beat 1 at 0:00. Warm electric piano
  chords, a round bass, laid-back drums, and a soft bell on every chart note
  so the beat is easy to hear. It starts with the heartbeat alone and builds
  to a light crescendo, then one chord rings out.
- placeholder_layer.mp3: an extra layer in time with the song (a high
  electric-piano line, a shaker and a soft pad). The game turns it up while
  the player keeps a streak of hits and lets it settle back after a miss
  (Dan, 2026-10-21: "a streak of hits ... adds a layer to the song").
- placeholder_celebrate.wav: a bright rising chime for the test appearing.
- placeholder_miss_1..3.wav: short wordless "hm" sounds standing in for the
  awkward laughter.

Needs numpy and ffmpeg; only used to regenerate these files, not by the game.
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
SILENT_BAR = 48
LAST_NOTE = CHART["notes_ms"][-1] / 1000
CRESCENDO_BAR = int(CHART["crescendo_ms"] / 1000 // BAR) + 1
SWING = 0.06  # How late the off-beat sixteenths fall, in seconds.

# One chord every 2 bars, the neo-soul ii-V-I-vi in C (MIDI note numbers):
# Dm9, G13, Cmaj9, Am9.
CHORDS = [
    [50, 53, 57, 60, 64],
    [43, 53, 59, 64, 69],
    [48, 52, 55, 59, 62],
    [45, 52, 55, 60, 59 + 12],
]
ROOTS = [38, 31, 36, 33]


def hz(midi):
    return 440.0 * 2 ** ((midi - 69) / 12)


def chord_index(t):
    return int(t // (2 * BAR)) % 4


def level(t):
    """How full the band is, 0..1, rising through the song."""
    bar = int(t // BAR) + 1
    for last, value in [(8, 0.35), (32, 0.55), (56, 0.7), (80, 0.85), (100, 1.0)]:
        if bar <= last:
            return value
    return 1.0


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


def bass(freq, dur, lvl):
    e, t = env(dur, 0.01, dur * 0.6)
    tone = np.tanh(1.6 * (np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(4 * np.pi * freq * t)))
    return lvl * e * tone


def thump(freq, dur=0.3, decay=0.08, lvl=0.8):
    e, t = env(dur, 0.003, decay)
    sweep = freq * (1 + 1.2 * np.exp(-t / 0.025))
    return lvl * e * np.sin(2 * np.pi * np.cumsum(sweep) / SR)


def noise(dur, decay, lvl, seed, tone=0.0):
    e, t = env(dur, 0.001, decay)
    n = np.random.default_rng(seed).uniform(-1, 1, len(e))
    if tone:
        n = 0.6 * n + 0.4 * np.sin(2 * np.pi * tone * t)
    return lvl * e * n


def bell(freq, lvl):
    """The tap cue: a short, clear bell on every chart note."""
    e, t = env(0.5, 0.002, 0.14)
    return lvl * e * (np.sin(2 * np.pi * freq * t) + 0.25 * np.sin(2 * np.pi * 3.01 * freq * t))


def song():
    n = int(LENGTH * SR)
    mix = np.zeros(n)

    for bar in range(1, 101):
        bt = (bar - 1) * BAR
        if bar == SILENT_BAR:
            continue
        chord = CHORDS[chord_index(bt)]
        lv = level(bt)
        # Keys: the chord on beat 1, and from bar 33 a softer push on the "and" of 2.
        for k, m in enumerate(chord):
            add(mix, bt + k * 0.012, keys(hz(m), 2.2, 0.05 + 0.03 * lv))
            if bar >= 33:
                add(mix, bt + 1.5 * BEAT + SWING, keys(hz(m), 0.9, 0.03 + 0.02 * lv))
        # Bass from bar 9: root on 1, a walk up to the fifth before beat 3.
        if bar >= 9:
            root = ROOTS[chord_index(bt)]
            add(mix, bt, bass(hz(root), 1.3, 0.28 * lv))
            add(mix, bt + 2 * BEAT - 0.25 + SWING, bass(hz(root + 7), 0.25, 0.18 * lv))
            add(mix, bt + 2 * BEAT, bass(hz(root + 12), 0.9, 0.22 * lv))
        for beat in range(4):
            t = bt + beat * BEAT
            if bar <= 32:
                if beat in (0, 2):  # The heartbeat, 60 a minute: lub-dub.
                    add(mix, t, thump(48, lvl=0.5))
                    add(mix, t + 0.2, thump(44, lvl=0.3))
            else:
                if beat in (0, 2) or (bar >= 57 and beat == 1 and bar % 2 == 0):
                    add(mix, t, thump(52, lvl=0.75 * lv))  # Kick
                if beat == 2:
                    add(mix, t, noise(0.25, 0.06, 0.22 * lv, bar, tone=190))  # Half-time snare
            if bar >= 57:  # Swung hats on the sixteenths.
                for s in range(2):
                    add(mix, t + s * BEAT / 2 + (SWING if s else 0),
                        noise(0.05, 0.012, (0.05 if s else 0.07) * lv, bar * 8 + beat * 2 + s))
            if bar >= 81 and beat in (1, 3):
                add(mix, t, noise(0.18, 0.045, 0.14 * lv, bar * 4 + beat))  # Claps

        # Strings-like pad for the crescendo.
        if bar >= 81:
            e, tt = env(BAR, 0.4, 4.0)
            pad = sum(np.sin(2 * np.pi * hz(m + 12) * tt * (1 + 0.002 * np.sin(2 * np.pi * 5 * tt)))
                      for m in chord[1:])
            add(mix, bt, 0.025 * lv * e * pad)
        # The crescendo (from the chart's crescendo bar): a cymbal swell into
        # it, and the pad doubled an octave higher.
        if bar == CRESCENDO_BAR - 1:
            swell = noise(BAR, 10.0, 0.08, 99) * np.linspace(0, 1, int(BAR * SR)) ** 2
            add(mix, bt, swell)
        if bar == CRESCENDO_BAR:
            add(mix, bt, noise(2.5, 0.8, 0.2, 98))
        if bar >= CRESCENDO_BAR:
            e, tt = env(BAR, 0.2, 4.0)
            high = sum(np.sin(2 * np.pi * hz(m + 24) * tt) for m in chord[1:])
            add(mix, bt, 0.015 * e * high)

    # The tap cue on every chart note, on a chord tone.
    for i, ms in enumerate(CHART["notes_ms"]):
        nt = ms / 1000
        tone = sorted(CHORDS[chord_index(nt)])[2 + i % 3] + 24
        add(mix, nt, bell(hz(tone), 0.12 + 0.06 * level(nt)))

    # The last note is the biggest; then one held Cmaj9 rings out.
    add(mix, LAST_NOTE, thump(48, dur=0.8, decay=0.25, lvl=1.0))
    ring = np.arange(int((LENGTH - LAST_NOTE) * SR)) / SR
    chord = sum(keys(hz(m), LENGTH - LAST_NOTE, 0.09)[: len(ring)] for m in [36, 48, 52, 55, 59, 62, 67])
    add(mix, LAST_NOTE, chord)

    # Loud enough for a phone speaker: level to the body of the song, then a
    # soft limit so the final hit doesn't clip.
    body = np.max(np.abs(mix[: int(LAST_NOTE * SR)]))
    return np.tanh(mix / body * 1.6) * 0.9


def layer():
    """The streak layer: same bars and chords as the song, nothing on its own."""
    n = int(LENGTH * SR)
    mix = np.zeros(n)
    for bar in range(1, 100):
        bt = (bar - 1) * BAR
        if bar == SILENT_BAR:
            continue
        chord = sorted(CHORDS[chord_index(bt)])
        # A rising and falling line of chord tones, two octaves up, on the eighths.
        line = chord[1:] + chord[-2:0:-1]
        for k in range(8):
            t = bt + k * BEAT / 2 + (SWING if k % 2 else 0)
            add(mix, t, keys(hz(line[k % len(line)] + 24), 0.6, 0.05 if k % 2 else 0.07))
        for s in range(16):  # Shaker on the sixteenths.
            add(mix, bt + s * BEAT / 4 + (SWING / 2 if s % 2 else 0),
                noise(0.06, 0.015, 0.05 if s % 2 else 0.035, 1000 + bar * 16 + s))
        e, tt = env(BAR, 0.3, 3.0)
        pad = sum(np.sin(2 * np.pi * hz(m + 12) * tt) for m in chord[1:])
        add(mix, bt, 0.02 * e * pad)
    # Fades out under the last note; the song's own chord rings on alone.
    fade = np.clip((LAST_NOTE + 0.5 - np.arange(n) / SR) / 1.5, 0.0, 1.0)
    mix *= fade
    return mix / max(1e-6, np.max(np.abs(mix))) * 0.7


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
    with tempfile.TemporaryDirectory() as tmp:
        wav = pathlib.Path(tmp) / "song.wav"
        for name, samples in [("placeholder_song", song()), ("placeholder_layer", layer())]:
            write_wav(wav, samples)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-ac", "1",
                            "-b:a", "64k", str(OUT / f"{name}.mp3")], check=True)
    write_wav(OUT / "placeholder_celebrate.wav", celebrate())
    for k in range(1, 4):
        write_wav(OUT / f"placeholder_miss_{k}.wav", miss(k))
    print("Wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
