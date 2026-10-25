"""The Protector's sound: the couple's song, drowned by a storm, then cut dead.

    python3 tools/protector/make_audio.py [path/to/source.mp3]

Built from docs/design/the-loss-run-and-car.md, "Music and sound" (Dan,
2026-10-25: the storm overtakes the song; everything stops at 2:55). Writes
game/assets/audio/protector/:

- run.mp3: one pre-mixed track for the run, from 0:05 (the light fades up)
  to 2:55 (everything stops). The run starts it at 0:05 and it ends itself.
  - 0:05-1:25 the euphoria: the Partner's song, bright.
  - 1:25-2:15 the confusion: wind, then the first rain, rise over the song.
  - 2:15-2:55 the panic: heavy rain, wind and thunder drown the song until
    only scraps of it come through.
  - 2:55 a short tape stop on the song, and storm and song stop dead.
- placeholder_clear.wav: a soft, warm click when an obstacle is cleared.
- placeholder_stumble.wav: a dull, soft thud when one reaches the light.

The song is "Dreamy Lo-Fi Beat" by NewEraMusic via Pixabay (see
tools/partner/make_song.py for the licence and where the source file is). It
starts on a bar line at 0:05 so the euphoria's obstacles, every 2 bars from
0:13, land on its beat; the bar map is in BARS below.

PLACEHOLDER: the storm (rain, wind, thunder) and the two tap sounds are
generated here, not recorded. The design says the storm is free licensed
recordings (Pixabay or CC0) or AI-made (ADR-0005); swap them in here when Dan
picks them, and the car (DAS-98) uses the same ones, muffled.

Needs numpy and ffmpeg; only used to regenerate the sound, not by the game.
"""
import pathlib
import subprocess
import sys
import tempfile

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "partner"))
from make_placeholder_audio import write_wav  # noqa: E402
from make_song import BAR, DEFAULT_SOURCE, SR, TREBLE_CUT, decode, ffilter, tape_stop  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/protector"

# Run times (seconds from the lamp click), as in run_plan.gd.
START = 5.0  # The file's time 0.
CONFUSION = 85.0
PANIC = 135.0
SILENCE = 175.0
LENGTH = SILENCE - START  # 170 s.

# Source bars (1-based) in the order they play: from the bar where the beat
# comes in, through the fullest part, then the fullest part again to fill the
# 170 s. 64 bars is 170.7 s; the cut at 2:55 comes in the last bar.
BARS = list(range(9, 57)) + list(range(41, 57))
TAPE_STOP = 0.3  # Seconds the song takes to slow to a halt at 2:55.
# Thunder in the panic (run times), and one far off as the confusion ends.
THUNDER = [(124.0, 0.35), (139.5, 0.8), (146.0, 1.0), (151.5, 0.8), (157.0, 1.0),
           (161.5, 0.9), (166.0, 1.0), (170.5, 0.9)]

RNG = np.random.default_rng(97)


def ramp(t, points):
    """Piecewise-linear level over run time t, from (time, level) points."""
    times, levels = zip(*points)
    return np.interp(t, times, levels)


def arrange(source):
    source = np.pad(source, (0, max(0, max(BARS) * BAR - len(source))))
    out = np.zeros(len(BARS) * BAR)
    fade = 882  # 20 ms at a join that isn't in the original.
    for k, src in enumerate(BARS):
        piece = source[(src - 1) * BAR: src * BAR].copy()
        if k and BARS[k - 1] != src - 1:
            piece[:fade] *= np.linspace(0, 1, fade)
        if k + 1 < len(BARS) and BARS[k + 1] != src + 1:
            piece[-fade:] *= np.linspace(1, 0, fade)
        out[k * BAR:(k + 1) * BAR] = piece
    out[:441] *= np.linspace(0, 1, 441)  # 10 ms in, so the first bar doesn't click.
    return out


def noise(n):
    return RNG.standard_normal(n)


def rain(n):
    """PLACEHOLDER rain: a hiss of filtered noise with drops pattering in it."""
    hiss = ffilter(noise(n), "highpass=f=500,lowpass=f=7000")
    drops = np.zeros(n)
    for i in RNG.integers(0, n - 400, n // 60):
        drops[i: i + 400] += RNG.uniform(0.3, 1.0) * np.exp(-np.arange(400) / 40) \
            * RNG.standard_normal(400)
    drops = ffilter(drops, "highpass=f=1500")
    return hiss / np.max(np.abs(hiss)) + 0.5 * drops / np.max(np.abs(drops))


def wind(n, t):
    """PLACEHOLDER wind: low noise that swells and falls."""
    body = ffilter(noise(n), "lowpass=f=500,highpass=f=60")
    swell = 0.55 + 0.45 * np.sin(2 * np.pi * t / 7.3) * np.sin(2 * np.pi * t / 3.1 + 1.0)
    return body / np.max(np.abs(body)) * swell


def thunder(n):
    """PLACEHOLDER thunder: a crack, then a long low rumble."""
    out = np.zeros(n)
    for at, level in THUNDER:
        length = int(5.0 * SR)
        t = np.arange(length) / SR
        rumble = ffilter(noise(length), "lowpass=f=140")
        rumble = rumble / np.max(np.abs(rumble)) * np.minimum(t / 0.15, 1) * np.exp(-t / 1.6)
        crack = ffilter(noise(length), "highpass=f=900") * np.exp(-t / 0.08)
        crack = crack / np.max(np.abs(crack)) * 0.4 * level
        i = int((at - START) * SR)
        j = min(n, i + length)
        out[i:j] += (level * rumble + crack)[: j - i]
    return out


def run_track(source):
    n = int(LENGTH * SR)
    t = START + np.arange(n) / SR
    song = ffilter(arrange(source), TREBLE_CUT)[:n]
    song = song / np.max(np.abs(song))
    # The song: full, then further away as the storm comes in, then only
    # scraps of it come through the panic (a slow, uneven swell).
    scraps = np.clip(np.interp(t, np.arange(PANIC, SILENCE + 2, 0.9),
                               RNG.uniform(-0.15, 0.35, len(np.arange(PANIC, SILENCE + 2, 0.9)))),
                     0.0, 1.0)
    song_level = ramp(t, [(START, 1.0), (CONFUSION, 1.0), (PANIC, 0.5), (PANIC + 12, 0.12),
                          (SILENCE, 0.12)])
    song_level = np.where(t >= PANIC + 12, 0.06 + scraps * 0.45, song_level)
    stop = int(TAPE_STOP * SR)
    song[n - stop:] = tape_stop(song[n - stop:], stop)
    wind_level = ramp(t, [(START, 0.0), (CONFUSION, 0.0), (CONFUSION + 20, 0.25), (PANIC, 0.5),
                          (PANIC + 8, 0.7), (SILENCE, 0.75)])
    rain_level = ramp(t, [(START, 0.0), (CONFUSION + 10, 0.0), (CONFUSION + 35, 0.15),
                          (PANIC, 0.35), (PANIC + 8, 0.9), (SILENCE, 1.0)])
    mix = song * song_level + 1.5 * wind(n, t) * wind_level + 1.6 * rain(n) * rain_level \
        + 1.2 * thunder(n)
    # The storm takes over, as loud as the song was or louder: set the level
    # from the song alone, and let a soft limit catch the thunder's peaks.
    euphoria = slice(0, int((CONFUSION - START) * SR))
    mix *= 0.22 / np.sqrt(np.mean(mix[euphoria] ** 2))
    mix = np.tanh(mix * 1.1) / np.tanh(1.1)
    mix[-441:] *= np.linspace(1, 0, 441)  # Stops dead: 10 ms, so it doesn't click.
    return mix * 0.95


def clear_click():
    """PLACEHOLDER: a soft, warm click, two quick low tones."""
    t = np.arange(int(0.12 * SR)) / SR
    env = np.minimum(t / 0.003, 1) * np.exp(-t / 0.025)
    tone = np.sin(2 * np.pi * 660 * t) + 0.5 * np.sin(2 * np.pi * 990 * t)
    return ffilter(env * tone, "lowpass=f=2500") * 0.5


def stumble_thud():
    """PLACEHOLDER: a dull, soft thud. Not a buzzer."""
    t = np.arange(int(0.35 * SR)) / SR
    env = np.minimum(t / 0.006, 1) * np.exp(-t / 0.07)
    body = np.sin(2 * np.pi * 75 * t * (1 - 0.3 * t)) + 0.3 * noise(len(t))
    return ffilter(env * body, "lowpass=f=300") * 0.6


def main():
    source = decode(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE)
    OUT.mkdir(parents=True, exist_ok=True)
    write_wav(OUT / "placeholder_clear.wav", clear_click())
    write_wav(OUT / "placeholder_stumble.wav", stumble_thud())
    with tempfile.TemporaryDirectory() as tmp:
        wav = pathlib.Path(tmp) / "run.wav"
        write_wav(wav, run_track(source))
        subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-ac", "1",
                        "-b:a", "96k", str(OUT / "run.mp3")], check=True)
    print(f"Wrote run.mp3 ({LENGTH:.0f} s), placeholder_clear.wav and placeholder_stumble.wav")


if __name__ == "__main__":
    main()
