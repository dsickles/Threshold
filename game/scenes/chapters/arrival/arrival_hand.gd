extends RefCounted
## The Arrival's hand beat (DAS-137), as plain numbers, so it can be tested on
## a fake clock. Tap in time with the baby's heartbeat while holding the
## baby's hand (docs/design/story-beats.md §8, beat 3; Dan, 2026-10-25).
## The judging is the Partner's (scenes/chapters/partner/partner.gd),
## copied, not reached into: the same Perfect and Good windows, the same
## grace before a Miss, and the same intro taps that find the sound delay
## (ADR-0006), so the rhythm the player learned in the Partner is the one
## they use here. A miss still moves on; nothing here can fail.
##
## Song times are seconds from the start of the song file.

enum Judged { PENDING, HIT, MISSED }

## The chart, matching tools/arrival/make_placeholder_audio.py: the baby's
## heartbeat at 120 a minute, and a note to tap on every other beat, where
## the song's soft chord is. PLACEHOLDER tempo, a call for Dan.
const FIRST_NOTE := 4.0
const NOTE_GAP := 1.0
const NOTE_COUNT := 56
const SONG_LENGTH := 66.0
## The first notes are the intro: their taps find the sound delay.
const INTRO_NOTES := 4

## From the Partner (its numbers and reasons are there). GOOD_WINDOW +
## MISS_GRACE must stay under half the gap between notes, so one tap can't
## count twice.
const PERFECT_WINDOW := 0.070
const GOOD_WINDOW := 0.160
const MISS_GRACE := 0.080
const CALIBRATION_WINDOW := 0.400
const MAX_SOUND_DELAY := 0.400
const MIN_CALIBRATION_TAPS := 3

var notes := PackedFloat64Array()
var judged := PackedByteArray()
## Seconds the sound reaches the player after the song clock says (from the
## intro taps); taps are judged against the notes plus this.
var sound_delay := 0.0
var intro_end := 0.0

var _next := 0  # First note not yet passed.
var _calibration: Array[float] = []


func _init() -> void:
	for k in NOTE_COUNT:
		notes.append(FIRST_NOTE + k * NOTE_GAP)
	judged.resize(NOTE_COUNT)
	intro_end = notes[INTRO_NOTES - 1] + NOTE_GAP / 2.0


func hits() -> int:
	return judged.count(Judged.HIT)


func misses() -> int:
	return judged.count(Judged.MISSED)


## Notes hit or missed so far, 0 to 1.
func progress() -> float:
	return float(hits() + misses()) / NOTE_COUNT


func last_note() -> float:
	return notes[NOTE_COUNT - 1]


## Judges a tap heard at song time `raw`. Returns "Perfect", "Good", or ""
## for a stray tap with no note near it (it does nothing: no Miss).
func judge(raw: float) -> String:
	if raw < 0.0:
		return ""
	if raw < intro_end:
		_calibrate(raw)
	var t := raw - sound_delay
	var i := _next
	while i < NOTE_COUNT and notes[i] <= t + GOOD_WINDOW:
		var offset := t - notes[i]
		if judged[i] == Judged.PENDING and absf(offset) <= GOOD_WINDOW:
			judged[i] = Judged.HIT
			return "Perfect" if absf(offset) <= PERFECT_WINDOW else "Good"
		i += 1
	return ""


## Marks every note now too far past to hit as missed. Returns how many.
func mark_misses(song_time: float) -> int:
	var t := song_time - sound_delay
	var missed := 0
	while _next < NOTE_COUNT and notes[_next] + GOOD_WINDOW + MISS_GRACE < t:
		if judged[_next] == Judged.PENDING:
			judged[_next] = Judged.MISSED
			missed += 1
		_next += 1
	return missed


## Seconds until note `i` is heard, from song time `t`, with the sound delay.
func until(i: int, t: float) -> float:
	return notes[i] + sound_delay - t


## The first note not yet passed (NOTE_COUNT once all have).
func next_note() -> int:
	return _next


# Intro taps set the sound delay: the middle of how early or late they land,
# measured from the tap as heard, before any delay is applied (the
# Partner's rule).
func _calibrate(raw: float) -> void:
	var nearest := INF
	for k in INTRO_NOTES:
		if absf(raw - notes[k]) < absf(nearest):
			nearest = raw - notes[k]
	if absf(nearest) > CALIBRATION_WINDOW:
		return
	_calibration.append(nearest)
	if _calibration.size() < MIN_CALIBRATION_TAPS:
		return
	var sorted := _calibration.duplicate()
	sorted.sort()
	var mid := sorted.size() / 2
	var median: float = sorted[mid] if sorted.size() % 2 == 1 \
			else (sorted[mid - 1] + sorted[mid]) / 2.0
	sound_delay = clampf(median, -MAX_SOUND_DELAY, MAX_SOUND_DELAY)
