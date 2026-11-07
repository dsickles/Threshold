"""PLACEHOLDER sound for the Provider's stamps, until a real one is picked.

    python3 tools/provider/make_placeholder_audio.py

Writes game/assets/audio/provider/placeholder_thunk.wav: a short, dull ink
thunk (a low knock with a papery slap on top) for APPROVE and DENY.

Needs numpy; only used to regenerate the file, not by the game.
"""
import pathlib
import wave

import numpy as np

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/provider"
SR = 44100


def thunk():
    length = 0.35
    t = np.arange(int(length * SR)) / SR
    # The knock: a low tone that drops in pitch and dies fast.
    freq = 95 + 60 * np.exp(-t / 0.02)
    phase = 2 * np.pi * np.cumsum(freq) / SR
    knock = np.sin(phase) * np.exp(-t / 0.06)
    # The slap of rubber on paper: a burst of filtered noise.
    rng = np.random.default_rng(4)
    noise = rng.standard_normal(len(t))
    noise = np.convolve(noise, np.ones(12) / 12, mode="same")
    slap = noise * np.exp(-t / 0.012)
    mix = 0.9 * knock + 0.6 * slap
    attack = np.minimum(t / 0.002, 1.0)
    mix *= attack
    return mix / np.max(np.abs(mix)) * 0.8


def write(path, samples):
    data = (np.clip(samples, -1, 1) * 32767).astype("<i2")
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SR)
        f.writeframes(data.tobytes())


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    write(OUT / "placeholder_thunk.wav", thunk())
    print("wrote", OUT / "placeholder_thunk.wav")
