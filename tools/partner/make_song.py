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
2. The stumble (bar 28), just before the beat comes back.
3. The fullest part (source bars 49-56) plays twice; the crescendo runs from
   bar 53 to the last note at bar 65, then the track's own outro fades out.
4. A gentle treble cut to soften the hi-hats (Dan: "i don't like the ticks").
5. The streak brightens the song: song.mp3 is the track slightly muffled, and
   song_bright.mp3 is the rest of it (the track minus the muffled one), which
   the Conductor fades in as the streak layer.

After playing it (Dan, 2026-10-21): "The tap should [go] along with the song.
Period. No additional sound comes from the tap. Period", so the bell on each
note is gone and the chart follows the track's own hits (make_chart.py). The
heartbeat "is ok as a background track. Just not artificial sounding", so it is
a soft, muffled thud like one heard through a chest, not a tone. The stumble was
a bar of silence cut into the pads, "not a natural stop", so now the track
slows to a halt like a tape stopping, rests, and comes back in on the drum
pickup the track itself uses to bring the beat in (the end of source bar 8).

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
from make_placeholder_audio import write_wav  # noqa: E402

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / "game/assets/audio/partner"
DEFAULT_SOURCE = pathlib.Path("/mnt/project-files/partner/source-dreamy-lo-fi-beat-549997.mp3")
CHART = json.loads((ROOT / "game/scenes/chapters/partner/beat_chart.json").read_text())
SR = 44100
BPM = 90
BAR = round(4 * 60 / BPM * SR)  # 117600 samples, exactly 8/3 s.
MUFFLE_HZ = 1800
TREBLE_CUT = "highshelf=f=7000:g=-6"
HEARTBEAT_LEVEL = 0.35  # Of the track's peak: in the background.

BEAT = BAR // 4
# Which source bar (1-based) plays in each bar of the chapter; STOP is the stumble.
STOP = "stop"
BARS = (list(range(1, 28)) + [STOP] + list(range(29, 57)) + list(range(49, 57))
        + list(range(57, 62)))
STOP_BEATS = 1.5  # How long the tape takes to slow to a halt.
PICKUP_BAR = 8  # Its last beat is the drum pickup that brings the beat in.
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


def tape_stop(audio, length):
    """Plays audio slowing from full speed to a halt over `length` samples."""
    speed = 1.0 - np.arange(length) / length
    pos = np.cumsum(speed)
    out = np.interp(pos, np.arange(len(audio)), audio)
    return out * np.minimum(1.0, (length - np.arange(length)) / (0.15 * length))


def stumble(source, src_bar):
    """The track slows to a halt, rests, then the pickup brings the beat back."""
    out = np.zeros(BAR)
    start = (src_bar - 1) * BAR
    n = int(STOP_BEATS * BEAT)
    out[:n] = tape_stop(source[start: start + n], n)
    pickup = source[PICKUP_BAR * BAR - BEAT: PICKUP_BAR * BAR].copy()
    pickup[:441] *= np.linspace(0, 1, 441)
    out[-BEAT:] = pickup
    return out


def arrange(source):
    source = np.pad(source, (0, max(0, 61 * BAR - len(source))))
    out = np.zeros(len(BARS) * BAR)
    fade = 882  # 20 ms
    for k, src in enumerate(BARS):
        if src == STOP:
            out[k * BAR:(k + 1) * BAR] = stumble(source, k + 1)
            continue
        piece = source[(src - 1) * BAR: src * BAR].copy()
        prev = BARS[k - 1] if k else None
        if k and prev != STOP and prev != src - 1:  # A join that isn't in the original: fade in.
            piece[:fade] *= np.linspace(0, 1, fade)
        nxt = BARS[k + 1] if k + 1 < len(BARS) else None
        if nxt is not None and nxt != STOP and nxt != src + 1:
            piece[-fade:] *= np.linspace(1, 0, fade)
        out[k * BAR:(k + 1) * BAR] = piece
    return out


def heartbeat():
    """One soft lub-dub, low and muffled, like a heart heard through a chest."""
    rng = np.random.default_rng(7)
    out = np.zeros(int(0.6 * SR))
    for delay, lvl, hz, dur in ((0.0, 1.0, 55, 0.11), (0.22, 0.6, 70, 0.08)):
        t = np.arange(int(dur * 2.5 * SR)) / SR
        env = (1 - np.exp(-t / 0.012)) * np.exp(-t / (dur / 2.5))
        body = np.sin(2 * np.pi * hz * t * (1 - 0.15 * t / t[-1]))
        thud = np.convolve(rng.standard_normal(len(t)), np.ones(200) / 200, "same") * 3
        i = int(delay * SR)
        out[i: i + len(t)] += lvl * env * (0.8 * body + 0.2 * thud)
    return out


def main():
    source = decode(sys.argv[1] if len(sys.argv) > 1 else DEFAULT_SOURCE)
    track = ffilter(arrange(source), TREBLE_CUT)
    muffled = ffilter(track, f"lowpass=f={MUFFLE_HZ}:poles=2")
    bright = track - muffled

    # The heartbeat under the soft opening, on every beat from the bar of the
    # first note: background, not a tap sound (it plays whether or not the
    # player taps).
    beats = np.zeros(len(track))
    offset = CHART["start_offset_ms"] / 1000
    intro_end = CHART["intro_end_ms"] / 1000
    last = CHART["notes_ms"][-1] / 1000
    t = CHART["notes_ms"][0] // (4 * 60000 / BPM) * 4 * 60 / BPM
    while t < intro_end - 0.01:
        beats[int(round((offset + t) * SR)):][:len(heartbeat())] += heartbeat()
        t += BEAT / SR
    beats = ffilter(beats, "lowpass=f=250:poles=2") * HEARTBEAT_LEVEL * np.max(np.abs(track))
    extra = beats

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
