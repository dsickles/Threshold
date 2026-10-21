"""The Partner's song: Dan's pick of a real track, edited to fit the chapter.

    python3 tools/partner/make_song.py [path/to/source.mp3]

Source: "Dreamy Lo-Fi Beat" by NewEraMusic, Pixabay
(https://pixabay.com/music/beats-dreamy-lo-fi-beat-549997/), under the Pixabay
Content License: free to use and modify in a game, no credit required, but not
to be shared on its own. So the original download is not in the repo; download
it from that page (or use the copy in the project's shared folder) and pass its
path. Credit it anyway on the credits screen: "Music: Dreamy Lo-Fi Beat by
NewEraMusic via Pixabay".

Dan, 2026-10-21: the generated song sounded "too '80s videogamey"; he picked
this track and agreed the edits:
1. Our heartbeat over its soft opening (bars 3-8), for the intro taps.
2. The stumble: one bar of silence (bar 28) just before the beat comes back.
3. The fullest part (source bars 49-56) plays twice; the crescendo runs from
   bar 53 to the last note at bar 65, then the track's own outro fades out.
4. A gentle treble cut to soften the hi-hats (Dan: "i don't like the ticks").
5. The streak brightens the song: song.mp3 is the track slightly muffled, and
   song_bright.mp3 is the rest of it (the track minus the muffled one), which
   the Conductor fades in as the streak layer.
6. A quieter bell on every chart note, pitched A and D to sit in the track's
   key (D minor / F major).

The bar map below must match tools/partner/make_chart.py (90 BPM, 69 bars).
Needs numpy and ffmpeg; only used to regenerate the song, not by the game.
"""
import json
import pathlib
import subprocess
import sys
import tempfile

import numpy as np

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from make_placeholder_audio import bell, thump, write_wav  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/partner"
DEFAULT_SOURCE = pathlib.Path("/mnt/project-files/partner/source-dreamy-lo-fi-beat-549997.mp3")
CHART = json.loads((ROOT / "game/scenes/chapters/partner/beat_chart.json").read_text())
SR = 44100
BPM = 90
BAR = round(4 * 60 / BPM * SR)  # 117600 samples, exactly 8/3 s.
MUFFLE_HZ = 1800
TREBLE_CUT = "highshelf=f=7000:g=-6"

# Which source bar (1-based) plays in each bar of the chapter; None is silence.
BARS = (list(range(1, 28)) + [None] + list(range(29, 57)) + list(range(49, 57))
        + list(range(57, 62)))
assert len(BARS) == CHART["song_length_ms"] * SR // 1000 // BAR, len(BARS)


def decode(path):
    raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(path), "-ac", "1", "-ar", str(SR),
                          "-f", "f32le", "-"], check=True, capture_output=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(float)


def ffilter(samples, af):
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "in.wav"
        write_wav(src, samples / max(1e-9, np.max(np.abs(samples))) * 0.9)
        raw = subprocess.run(["ffmpeg", "-loglevel", "error", "-i", str(src), "-af", af,
                              "-f", "f32le", "-"], check=True, capture_output=True).stdout
    out = np.frombuffer(raw, dtype=np.float32).astype(float)
    out = out[: len(samples)] * (max(1e-9, np.max(np.abs(samples))) / 0.9)
    return np.pad(out, (0, len(samples) - len(out)))


def arrange(source):
    source = np.pad(source, (0, max(0, 61 * BAR - len(source))))
    out = np.zeros(len(BARS) * BAR)
    fade = 882  # 20 ms
    for k, src in enumerate(BARS):
        if src is None:
            continue
        piece = source[(src - 1) * BAR: src * BAR].copy()
        prev = BARS[k - 1] if k else None
        if k and prev != src - 1:  # A join that isn't in the original: fade in.
            piece[:fade] *= np.linspace(0, 1, fade)
        nxt = BARS[k + 1] if k + 1 < len(BARS) else None
        if nxt != src + 1 and nxt is not None:
            # Fade out, and at the stumble stop a little longer so it doesn't click.
            n = fade * (2 if nxt is None or BARS[k + 1] is None else 1)
            piece[-n:] *= np.linspace(1, 0, n)
        out[k * BAR:(k + 1) * BAR] = piece
    return out


def main():
    source = decode(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE)
    track = ffilter(arrange(source), TREBLE_CUT)
    muffled = ffilter(track, f"lowpass=f={MUFFLE_HZ}:poles=2")
    bright = track - muffled

    extra = np.zeros(len(track))
    intro_end = CHART["intro_end_ms"] / 1000
    last = CHART["notes_ms"][-1] / 1000
    peak = np.max(np.abs(track))
    for i, ms in enumerate(CHART["notes_ms"]):
        t = ms / 1000
        start = int(round(t * SR))
        sounds = []
        if t < intro_end:  # The heartbeat the intro taps follow: lub-dub.
            sounds += [(0, thump(48, lvl=0.5)), (0.2, thump(44, lvl=0.3))]
        sounds.append((0, bell(880.0 if i % 2 else 1174.66, 0.07)))
        for delay, s in sounds:
            j = start + int(delay * SR)
            extra[j: j + len(s)] += s[: len(extra) - j] * peak

    # The outro fades out after the last note, under the test.
    n = len(track)
    fade = np.clip((n / SR - np.arange(n) / SR) / (n / SR - last - 2.0), 0.0, 1.0) ** 1.5
    song = (muffled + extra) * fade
    bright = bright * fade
    scale = 0.95 / max(1e-9, np.max(np.abs(song + bright)))

    OUT.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        wav = pathlib.Path(tmp) / "out.wav"
        for name, samples in (("song", song * scale), ("song_bright", bright * scale)):
            write_wav(wav, samples)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(wav), "-ac", "1",
                            "-b:a", "96k", str(OUT / f"{name}.mp3")], check=True)
    print(f"Wrote song.mp3 and song_bright.mp3, {len(BARS)} bars, {n / SR:.1f} s")


if __name__ == "__main__":
    main()
