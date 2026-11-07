"""The Arrival's PLACEHOLDER sounds, all generated here (no recordings).

    python3 tools/arrival/make_placeholder_audio.py

Built from docs/design/story-beats.md §8 (out the door, hear the cry, hold the
hand, home). Writes game/assets/audio/arrival/:

- placeholder_zip.wav: a zip pulled shut, for the bag finally closing.
- placeholder_pop.wav: the over-packed bag bursting open on the first try.
- placeholder_keys.wav: the car keys picked up, a small jingle.
- placeholder_door.wav: the front door opening, a soft latch and swing.
- placeholder_static.wav: 4 s of hiss and crackle, a seamless loop, under
  the cry beat until the cry comes through.
- placeholder_cry.wav: 4 s of a newborn's cry, a seamless loop: rising and
  falling wails with a raw edge, made from a pitched buzz through two vowel
  formants. Faint under the static, then clear.
- placeholder_heart_song.mp3: the hand beat's track, 66 s. A baby's heartbeat,
  120 a minute, with a soft warm chord on every other beat: the beats to tap.
  The first note to tap is at 4.0 s, then one every second, 56 in all (the
  last at 59 s); the first 4 are the intro that finds the sound delay. These
  numbers must match game/scenes/chapters/arrival/arrival_hand.gd.
- placeholder_breath.wav: 8 s of a baby breathing slowly and softly, a
  seamless loop, for the quiet hold at the end.

Every sound here is a PLACEHOLDER until real ones are picked (ADR-0010).
Needs numpy and ffmpeg (for the mp3); only used to regenerate the sound, not
by the game.
"""
import pathlib
import subprocess
import tempfile
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/arrival"
SR = 22050
RNG = np.random.default_rng(18)

# The hand beat's chart (arrival_hand.gd reads the same numbers).
FIRST_NOTE = 4.0
NOTE_GAP = 1.0
NOTE_COUNT = 56
SONG_LENGTH = 66.0
HEART_BPM = 120.0


def write_wav(path, samples, rate=SR):
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(rate)
        w.writeframes((np.clip(samples, -1, 1) * 32767).astype("<i2").tobytes())


def one_pole_lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return y


def bandpass(x, low, high):
    return one_pole_lowpass(x, high) - one_pole_lowpass(one_pole_lowpass(x, high), low)


def resonator(x, freq, bandwidth):
    """A two-pole resonance at `freq`: one vowel formant."""
    r = np.exp(-np.pi * bandwidth / SR)
    c = 2 * r * np.cos(2 * np.pi * freq / SR)
    y = np.zeros_like(x)
    y1 = y2 = 0.0
    for i, v in enumerate(x):
        y0 = v + c * y1 - r * r * y2
        y[i] = y0
        y2, y1 = y1, y0
    return y * (1 - r)


def seamless(x, fade_s=0.25):
    """Makes `x` loop without a seam: its tail is crossfaded into its head."""
    n = int(fade_s * SR)
    head, body, tail = x[:n], x[n:-n], x[-n:]
    ramp = np.linspace(0, 1, n)
    return np.concatenate([body, tail * (1 - ramp) + head * ramp])


def norm(x, peak):
    return x / np.max(np.abs(x)) * peak


def zip_sound():
    n = int(0.7 * SR)
    t = np.arange(n) / SR
    teeth = np.zeros(n)
    rate = np.linspace(28, 60, n)  # teeth a second, speeding up
    phase = np.cumsum(rate) / SR
    for k in np.flatnonzero(np.diff(np.floor(phase)) > 0):
        length = 90
        end = min(n, k + length)
        teeth[k:end] += RNG.normal(0, 1, end - k) * np.exp(-np.arange(end - k) / 18)
    out = bandpass(teeth, 900, 6000) * np.minimum(1, (0.7 - t) / 0.08)
    return norm(out, 0.7)


def pop_sound():
    n = int(0.6 * SR)
    t = np.arange(n) / SR
    thump = np.sin(2 * np.pi * (140 - 80 * t) * t) * np.exp(-t / 0.08)
    rustle = bandpass(RNG.normal(0, 1, n), 400, 5000) * np.exp(-t / 0.2)
    boing = np.sin(2 * np.pi * (300 + 200 * np.sin(2 * np.pi * 9 * t)) * t) * np.exp(-t / 0.15) * 0.3
    return norm(thump + 0.5 * rustle + boing, 0.75)


def keys_sound():
    n = int(0.9 * SR)
    t = np.arange(n) / SR
    out = np.zeros(n)
    for start in (0.0, 0.07, 0.16, 0.22, 0.35):
        x = np.clip(t - start, 0, None)
        on = t >= start
        f = RNG.uniform(2800, 5200)
        out += np.where(on, np.sin(2 * np.pi * f * x) * np.exp(-x / 0.09), 0) * RNG.uniform(0.5, 1)
        out += np.where(on, np.sin(2 * np.pi * f * 1.51 * x) * np.exp(-x / 0.05), 0) * 0.4
    return norm(out, 0.5)


def door_sound():
    n = int(1.4 * SR)
    t = np.arange(n) / SR
    latch = RNG.normal(0, 1, n) * np.exp(-t / 0.01) + np.sin(2 * np.pi * 900 * t) * np.exp(-t / 0.03)
    swing = bandpass(RNG.normal(0, 1, n), 80, 600) * np.sin(np.pi * np.clip((t - 0.1) / 1.2, 0, 1)) * 0.5
    outside = bandpass(RNG.normal(0, 1, n), 200, 3000) * np.clip((t - 0.3) / 1.0, 0, 1) * 0.25
    return norm(latch * 0.6 + swing + outside, 0.6)


def static():
    n = int(4.25 * SR)
    t = np.arange(n) / SR
    hiss = RNG.normal(0, 1, n)
    hiss = one_pole_lowpass(hiss - one_pole_lowpass(hiss, 300), 6000)
    hiss *= 0.75 + 0.25 * np.sin(2 * np.pi * 0.6 * t) * np.sin(2 * np.pi * 0.21 * t + 1)
    crackle = np.zeros(n)
    for at in RNG.integers(0, n - 200, 60):
        length = RNG.integers(20, 160)
        crackle[at:at + length] += RNG.normal(0, 1, length) * np.exp(-np.arange(length) / 30) * RNG.uniform(0.6, 1.6)
    return norm(seamless(hiss * 0.22 + crackle * 0.25), 0.6)


def cry():
    n = int(4.25 * SR)
    t = np.arange(n) / SR
    # Two wails in 4 s: each rises, holds and falls, with a catch of breath.
    pitch = np.full(n, 380.0)
    loud = np.zeros(n)
    for start, length in ((0.15, 1.5), (2.2, 1.65)):
        x = (t - start) / length
        inside = (x >= 0) & (x <= 1)
        shape = np.sin(np.pi * np.clip(x, 0, 1))
        pitch = np.where(inside, 380 + 170 * shape + 25 * np.sin(2 * np.pi * 6 * t), pitch)
        loud += np.where(inside, np.clip(shape * 1.6, 0, 1) ** 0.7, 0)
    phase = np.cumsum(pitch) / SR
    buzz = 2 * (phase % 1) - 1  # a raw, bright buzz like a voice
    buzz += 0.3 * RNG.normal(0, 1, n)  # breathiness
    voice = resonator(buzz, 1100, 160) + 0.7 * resonator(buzz, 2600, 260)  # "waah"
    return norm(seamless(voice * loud), 0.75)


def heart_song():
    n = int(SONG_LENGTH * SR)
    t = np.arange(n) / SR
    beat = 60.0 / HEART_BPM
    # Soft whooshing heartbeats with a low thud, every beat, from 0 s.
    whoosh = bandpass(RNG.normal(0, 1, n), 90, 500)
    env = np.zeros(n)
    thud = np.zeros(n)
    k = 0
    while k * beat < SONG_LENGTH - 2.0:
        start = k * beat
        for offset, size in ((0.0, 1.0), (0.11, 0.55)):
            x = np.clip(t - start - offset, 0, None)
            env += size * ((x / 0.03) * np.exp(1 - x / 0.03)) ** 1.5
        x = t - start
        thud += np.where(x >= 0, np.sin(2 * np.pi * 85 * x) * np.exp(-np.clip(x, 0, None) / 0.05), 0)
        k += 1
    heart = norm(whoosh, 1.0) * env + 0.4 * thud
    # A soft warm chord on each note to tap: every other heartbeat.
    chord = np.zeros(n)
    notes = [FIRST_NOTE + i * NOTE_GAP for i in range(NOTE_COUNT)]
    roots = [220.0, 196.0, 174.6, 196.0]  # A, G, F, G: two bars each, gently
    for i, at in enumerate(notes):
        root = roots[(i // 8) % len(roots)]
        x = t - at
        on = x >= 0
        decay = np.exp(-np.clip(x, 0, None) / 0.55)
        for ratio, size in ((1.0, 1.0), (1.25, 0.5), (1.5, 0.6), (2.0, 0.25)):
            chord += np.where(on, np.sin(2 * np.pi * root * ratio * x) * decay * size, 0)
    # The last note rings out longer.
    x = t - notes[-1]
    chord += np.where(x >= 0, np.sin(2 * np.pi * 220 * x) * np.exp(-np.clip(x, 0, None) / 2.5) * 0.8, 0)
    fade_in = np.clip(t / 1.5, 0, 1)
    fade_out = np.clip((SONG_LENGTH - t) / 3.0, 0, 1)
    return norm((0.55 * norm(heart, 1) + 0.35 * norm(chord, 1)) * fade_in * fade_out, 0.8)


def breath():
    n = int(8.25 * SR)
    t = np.arange(n) / SR
    air = bandpass(RNG.normal(0, 1, n), 300, 2500)
    # Two slow breaths in 8 s: in, a short rest, out.
    cycle = (t % 4.0) / 4.0
    swell = np.where(cycle < 0.4, np.sin(np.pi * cycle / 0.4) * 0.7,
                     np.where(cycle < 0.5, 0, np.sin(np.pi * (cycle - 0.5) / 0.5)))
    return norm(seamless(air * swell), 0.35)


def write_mp3(path, samples):
    with tempfile.TemporaryDirectory() as tmp:
        wav = pathlib.Path(tmp) / "song.wav"
        write_wav(wav, samples)
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav),
                        "-ar", "44100", "-ac", "1", "-b:a", "96k", str(path)], check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "placeholder_zip.wav", zip_sound())
    write_wav(OUT / "placeholder_pop.wav", pop_sound())
    write_wav(OUT / "placeholder_keys.wav", keys_sound())
    write_wav(OUT / "placeholder_door.wav", door_sound())
    write_wav(OUT / "placeholder_static.wav", static())
    write_wav(OUT / "placeholder_cry.wav", cry())
    write_wav(OUT / "placeholder_breath.wav", breath())
    write_mp3(OUT / "placeholder_heart_song.mp3", heart_song())
    print("Wrote", sorted(p.name for p in OUT.iterdir() if p.suffix in (".wav", ".mp3")))


if __name__ == "__main__":
    main()
