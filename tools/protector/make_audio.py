"""The Protector's sound: the couple's song, drowned by a storm that never stops.

    python3 tools/protector/make_audio.py [path/to/song.mp3]

Built from docs/design/the-loss-run-and-car.md, "Music and sound" (Dan,
2026-10-25: the storm overtakes the song; revised after his first play, call
15: the song drowns instead of stopping, and the rain never stops). Writes
game/assets/audio/protector/:

- run.mp3: one pre-mixed track for the run, from 0:05 (the light fades up)
  to 3:25 (black). The run starts it at 0:05 and it plays to the end.
  - 0:05-1:25 the euphoria: the Partner's song, bright.
  - 1:25-2:15 the confusion: wind, then the first rain, rise over the song.
  - 2:15-2:45 the panic: heavy rain, wind and thunder drown the song until
    only scraps of it come through, and by 2:45 it is gone under the rain.
  - 2:45-3:25 the light goes out: the storm without the song, the wind
    easing, the rain not; thunder far off, and none while the light goes out.
- placeholder_clear.wav: a soft, warm sound when the hand moves the light or
  covers a gap.
- placeholder_stumble.wav: a dull, soft thud when something reaches the light.

The song is "Dreamy Lo-Fi Beat" by NewEraMusic via Pixabay (see
tools/partner/make_song.py for the licence and where the source file is). It
starts on a bar line at 0:05 so the euphoria's obstacles, every 2 bars from
0:13, land on its beat; the bar map is in BARS below.

The storm is three Pixabay recordings Dan picked (2026-10-25), kept in
/mnt/project-files/protector/ (credits in game/assets/audio/protector/CREDITS.md):
the rain and the wind are looped with long crossfades, starting each pass at
a different place so the loop is hard to hear; the thunder is taken from
the storm recording and placed again and again, each time a little lower or
further off. The two tap sounds are still generated PLACEHOLDERS.

Needs numpy and ffmpeg; only used to regenerate the sound, not by the game.
"""
import pathlib
import subprocess
import sys
import tempfile

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parents[1] / "partner"))
from make_placeholder_audio import write_wav  # noqa: E402
from make_song import BAR, DEFAULT_SOURCE, SR, TREBLE_CUT, decode, ffilter  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/protector"
SOURCES = pathlib.Path("/mnt/project-files/protector")
RAIN = SOURCES / "source-juliush-heavy-rain-nature-sounds-8186.mp3"
WIND = SOURCES / "source-dragon-studio-harsh-wind-515272.mp3"
STORM = SOURCES / "source-eco-art-sounds-of-a-storm-with-wind-and-thunder-375923.mp3"

# Run times (seconds from the lamp click), as in run_plan.gd.
START = 5.0  # The file's time 0.
CONFUSION = 85.0
PANIC = 135.0
FADE = 165.0  # The song is gone under the rain (2:45 since call 18).
STOPPED = 185.0
OUT_AT = 195.0
BLACK = 205.0
LENGTH = BLACK - START  # 200 s.

# Source bars (1-based) in the order they play: from the bar where the beat
# comes in, through the fullest part, then the fullest part again past 2:45.
# 64 bars is 170.7 s.
BARS = list(range(9, 57)) + list(range(41, 57))
# Thunder (run time, level, how far off: 0 near, 1 far): one far off as the
# confusion ends, near through the panic, far off after, none while the light
# goes out (3:05 to 3:15).
THUNDER = [(124.0, 0.35, 1.0), (139.5, 0.8, 0.3), (146.0, 1.0, 0.0), (151.5, 0.8, 0.4),
           (157.0, 1.0, 0.0), (161.5, 0.9, 0.2), (168.5, 0.55, 0.7), (177.5, 0.4, 0.9),
           (198.0, 0.3, 1.0)]
# The steady parts of each recording, in seconds, that are looped.
RAIN_LOOP = (2.0, 26.0)
WIND_LOOP = (1.0, 12.0)
THUNDER_CLIP = (0.6, 9.5)
CROSSFADE = 2.0

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


def rms(x):
    return np.sqrt(np.mean(x ** 2))


def loop(path, span, n):
    """A recording's steady part, looped to n samples with equal-power
    crossfades; each pass starts at a different place in it."""
    clip = decode(path)[int(span[0] * SR): int(span[1] * SR)]
    fade = int(CROSSFADE * SR)
    out = np.zeros(n + len(clip))
    up = np.sin(np.linspace(0, np.pi / 2, fade))
    down = np.cos(np.linspace(0, np.pi / 2, fade))
    at = 0
    k = 0
    while at < n:
        offset = int((k * 0.37 % 1.0) * (len(clip) - fade * 2))
        piece = np.concatenate([clip[offset:], clip[:offset]])
        piece[:fade] *= up
        piece[-fade:] *= down
        out[at: at + len(piece)] += piece
        at += len(piece) - fade
        k += 1
    out = out[:n]
    return out / rms(out)


def thunder(n):
    clip = decode(STORM)[int(THUNDER_CLIP[0] * SR): int(THUNDER_CLIP[1] * SR)]
    clip = clip * np.minimum(1.0, np.arange(len(clip))[::-1] / (1.5 * SR))  # Tail fades out.
    clip /= np.max(np.abs(clip))
    out = np.zeros(n)
    for at, level, far in THUNDER:
        # Further off: lower in pitch and duller.
        rate = int(SR * (1.0 - 0.12 * far))
        hit = ffilter(clip, f"asetrate={rate},aresample={SR},lowpass=f={int(4000 - 3300 * far)}")
        hit = hit / np.max(np.abs(hit)) * level
        i = int((at - START) * SR)
        j = min(n, i + len(hit))
        out[i:j] += hit[: j - i]
    return out


def run_track(source):
    n = int(LENGTH * SR)
    t = START + np.arange(n) / SR
    song = ffilter(arrange(source), TREBLE_CUT)
    song = np.pad(song, (0, max(0, n - len(song))))[:n]
    song = song / rms(song[: int((CONFUSION - START) * SR)])
    # The song: full, then further away as the storm comes in, then only
    # scraps of it come through the panic, fewer and fainter until it is
    # gone under the rain at 2:45.
    grid = np.arange(PANIC, FADE + 2, 0.9)
    scraps = np.clip(np.interp(t, grid, RNG.uniform(-0.15, 0.35, len(grid))), 0.0, 1.0)
    song_level = ramp(t, [(START, 1.0), (CONFUSION, 1.0), (PANIC, 0.5), (PANIC + 12, 0.12)])
    under = ramp(t, [(PANIC + 12, 1.0), (FADE - 8, 0.5), (FADE, 0.0)])
    song_level = np.where(t >= PANIC + 12, (0.06 + scraps * 0.45) * under, song_level)
    wind_level = ramp(t, [(START, 0.0), (CONFUSION, 0.0), (CONFUSION + 20, 0.3), (PANIC, 0.55),
                          (PANIC + 8, 0.75), (FADE, 0.75), (FADE + 10, 0.45), (BLACK, 0.45)])
    rain_level = ramp(t, [(START, 0.0), (CONFUSION + 10, 0.0), (CONFUSION + 25, 0.2),
                          (PANIC, 0.45), (PANIC + 8, 1.0), (BLACK, 1.0)])
    rain = ffilter(loop(RAIN, RAIN_LOOP, n), "highpass=f=120")
    wind = loop(WIND, WIND_LOOP, n)
    mix = song * song_level + 1.1 * rain / rms(rain) * rain_level + 0.7 * wind * wind_level \
        + 2.2 * thunder(n)
    # The storm takes over, as loud as the song was or louder: set the level
    # from the song alone, and let a soft limit catch the thunder's peaks.
    euphoria = slice(0, int((CONFUSION - START) * SR))
    mix *= 0.22 / rms(mix[euphoria])
    mix = np.tanh(mix * 1.1) / np.tanh(1.1)
    mix[-int(0.5 * SR):] *= np.linspace(1, 0, int(0.5 * SR))  # PLACEHOLDER until the car.
    return mix * 0.88  # Headroom: the mp3 overshoots a little.


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
    body = np.sin(2 * np.pi * 75 * t * (1 - 0.3 * t)) + 0.3 * RNG.standard_normal(len(t))
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
