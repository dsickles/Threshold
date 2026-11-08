"""The Tuner's PLACEHOLDER sounds, all generated here (no recordings).

    python3 tools/tuner/make_placeholder_audio.py

Built from docs/design/story-beats.md §5 (static, the fridge hum as a false
signal, then the baby's heartbeat). Writes game/assets/audio/tuner/:

- placeholder_static.wav: 4 s of hiss and crackle, a seamless loop. Always
  under everything; it fades as the signal comes through.
- placeholder_hum.wav: 5 s of a fridge's hum, a seamless loop: a low buzz
  (120 Hz and its overtones, so a phone speaker can play it) that swells
  and settles about 72 times a minute, a steady rhythm that could pass for
  a slow heartbeat. The false signal.
- placeholder_click.wav: the fridge's motor clicking off, a short dull clunk.
  The false signal cuts out on it.
- placeholder_heartbeat.wav: 4 s of a home doppler's fetal heartbeat, a
  seamless loop: soft whooshing beats, 150 a minute (about right at 12
  weeks). The real signal.

Every sound here is a PLACEHOLDER until real ones are picked (ADR-0010).
Needs numpy; only used to regenerate the sound, not by the game.
"""
import pathlib
import sys

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "partner"))
from make_placeholder_audio import write_wav  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/tuner"
SR = 22050
RNG = np.random.default_rng(12)


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


def seamless(x, fade_s=0.25):
    """Makes `x` loop without a seam: its tail is crossfaded into its head."""
    n = int(fade_s * SR)
    head, body, tail = x[:n], x[n:-n] if n else x, x[-n:]
    ramp = np.linspace(0, 1, n)
    joined = tail * (1 - ramp) + head * ramp
    return np.concatenate([body, joined])


def static():
    n = int(4.25 * SR)
    hiss = RNG.normal(0, 1, n)
    hiss = hiss - one_pole_lowpass(hiss, 300)  # thin, radio-ish
    hiss = one_pole_lowpass(hiss, 6000)
    # Slow wavering, like a dial not quite on a station.
    t = np.arange(n) / SR
    hiss *= 0.75 + 0.25 * np.sin(2 * np.pi * 0.7 * t) * np.sin(2 * np.pi * 0.23 * t + 1)
    crackle = np.zeros(n)
    for at in RNG.integers(0, n - 200, 60):
        length = RNG.integers(20, 160)
        crackle[at:at + length] += RNG.normal(0, 1, length) * np.exp(-np.arange(length) / 30) * RNG.uniform(0.6, 1.6)
    out = seamless(hiss * 0.22 + crackle * 0.25)
    return out / np.max(np.abs(out)) * 0.6


def hum():
    n = int(5.0 * SR)
    t = np.arange(n) / SR
    buzz = sum(np.sin(2 * np.pi * 120 * k * t + k) / k ** 1.2 for k in range(1, 7))
    buzz += 0.15 * np.sign(np.sin(2 * np.pi * 120 * t))  # the motor's rasp
    # sin² peaks twice a cycle, so 0.6 Hz gives 1.2 swells a second: 72 a
    # minute, 6 in the 5 s loop (Hopper, DAS-135 round 1: it was 144).
    throb = 0.62 + 0.38 * np.sin(2 * np.pi * 0.6 * t) ** 2
    out = buzz * throb
    return out / np.max(np.abs(out)) * 0.5


def click():
    n = int(0.35 * SR)
    t = np.arange(n) / SR
    thump = np.sin(2 * np.pi * 70 * t) * np.exp(-t / 0.05)
    tick = RNG.normal(0, 1, n) * np.exp(-t / 0.006)
    out = one_pole_lowpass(thump + 0.5 * tick, 2500)
    return out / np.max(np.abs(out)) * 0.8


def heartbeat():
    beat = 60.0 / 150.0
    n = int(4.0 * SR)  # 10 beats exactly
    t = np.arange(n) / SR
    noise = bandpass(RNG.normal(0, 1, n), 120, 700)
    env = np.zeros(n)
    for k in range(10):
        for offset, size in ((0.0, 1.0), (0.12, 0.6)):  # the "whoosh-whoosh"
            start = k * beat + offset
            x = t - start
            env += size * np.where(x >= 0, (x / 0.025) * np.exp(1 - x / 0.025), 0) ** 1.5
    # Each beat also gets a soft low thud so it carries on a phone speaker.
    thud = np.zeros(n)
    for k in range(10):
        x = t - k * beat
        thud += np.where(x >= 0, np.sin(2 * np.pi * 95 * x) * np.exp(-x / 0.04), 0)
    out = noise / np.max(np.abs(noise)) * env + 0.35 * thud
    return out / np.max(np.abs(out)) * 0.75


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "placeholder_static.wav", static(), SR)
    write_wav(OUT / "placeholder_hum.wav", hum(), SR)
    write_wav(OUT / "placeholder_click.wav", click(), SR)
    write_wav(OUT / "placeholder_heartbeat.wav", heartbeat(), SR)
    print("Wrote", sorted(p.name for p in OUT.iterdir() if p.suffix == ".wav"))


if __name__ == "__main__":
    main()
