"""The Anchor's PLACEHOLDER sounds, all generated here (no recordings).

    python3 tools/anchor/make_placeholder_audio.py

Built from docs/design/story-beats.md §6 (Leo carries the crib through a
storm version of the House; Maya's "You've got this." after the third
fall). Writes game/assets/audio/anchor/:

- placeholder_rain.wav: 6 s of rain and wind on the windows, a seamless
  loop. Quiet in the calm, louder as the storm grows.
- placeholder_creak.wav: wood straining, when the crib leans far over.
- placeholder_thud.wav: the crib hitting the floor on a fall.
- placeholder_maya_cue.wav: a soft, warm two-note swell that stands in for
  Maya's voice under the subtitle (v1 is text with a sound cue, ADR-0005).
- placeholder_set_down.wav: the crib set down gently by the window.

Every sound here is a PLACEHOLDER until real ones are picked (ADR-0010).
Needs numpy; only used to regenerate the sound, not by the game.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "partner"))
from make_placeholder_audio import write_wav  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/anchor"
SR = 22050
RNG = np.random.default_rng(17)


def lowpass(x, cutoff):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for k, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[k] = acc
    return y


def seamless(x, fade):
    """Crossfades the end into the start so the loop has no seam."""
    n = int(fade * SR)
    ramp = np.linspace(0, 1, n)
    head = x[:n].copy()
    x = x[n:]
    x[-n:] = x[-n:] * (1 - ramp) + head * ramp
    return x


def rain():
    n = int(6.5 * SR)
    hiss = lowpass(RNG.standard_normal(n), 3000) * 0.25
    # Drops: tiny clicks scattered thickly.
    drops = np.zeros(n)
    for at in RNG.integers(0, n - 200, 1800):
        drops[at:at + 120] += RNG.uniform(0.05, 0.25) * np.exp(-np.arange(120) / 18) * RNG.choice([-1, 1])
    # Wind: a slow swelling low roar.
    t = np.arange(n) / SR
    wind = lowpass(RNG.standard_normal(n), 400) * (0.6 + 0.4 * np.sin(2 * np.pi * t / 6.5)) * 0.9
    x = hiss + drops + wind
    x = seamless(x, 0.5)
    return x / np.max(np.abs(x)) * 0.7


def creak():
    t = np.arange(int(0.7 * SR)) / SR
    pitch = 180 + 60 * np.sin(2 * np.pi * 1.3 * t)
    phase = 2 * np.pi * np.cumsum(pitch) / SR
    saw = (phase / np.pi % 2) - 1
    grit = (RNG.random(len(t)) < 0.04) * 0.6
    x = lowpass(saw * 0.5 + grit, 1500)
    env = np.sin(np.pi * t / t[-1]) ** 0.7
    return x * env / np.max(np.abs(x * env)) * 0.45


def thud():
    t = np.arange(int(0.6 * SR)) / SR
    body = np.sin(2 * np.pi * 70 * t) * np.exp(-t * 9)
    knock = lowpass(RNG.standard_normal(len(t)), 900) * np.exp(-t * 30)
    rattle = sum(np.sin(2 * np.pi * f * t) * np.exp(-t * 14) for f in (310, 470, 620)) * 0.12
    x = body + knock * 0.6 + rattle
    return x / np.max(np.abs(x)) * 0.85


def maya_cue():
    t = np.arange(int(1.8 * SR)) / SR
    x = np.zeros_like(t)
    for start, f in ((0.0, 392.0), (0.35, 523.25)):
        s = np.clip(t - start, 0, None)
        env = (1 - np.exp(-s * 6)) * np.exp(-s * 1.6) * (t >= start)
        x += env * (np.sin(2 * np.pi * f * t) + 0.3 * np.sin(2 * np.pi * 2 * f * t))
    return x / np.max(np.abs(x)) * 0.4


def set_down():
    t = np.arange(int(0.8 * SR)) / SR
    x = np.sin(2 * np.pi * 110 * t) * np.exp(-t * 12) + lowpass(RNG.standard_normal(len(t)), 600) * np.exp(-t * 25) * 0.3
    return x / np.max(np.abs(x)) * 0.5


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "placeholder_rain.wav", rain())
    write_wav(OUT / "placeholder_creak.wav", creak())
    write_wav(OUT / "placeholder_thud.wav", thud())
    write_wav(OUT / "placeholder_maya_cue.wav", maya_cue())
    write_wav(OUT / "placeholder_set_down.wav", set_down())
    print("Wrote", sorted(p.name for p in OUT.iterdir()))


if __name__ == "__main__":
    main()
