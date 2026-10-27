// The Protector's run (DAS-97): it opens from the menu (until the bedside
// lamp in the House can start it, DAS-95), plays with no console errors, a
// tap on the left or right moves the light one lane that way, a hold through
// a gap lays the hand across it, hiding the tab pauses it until a
// tap and the sound comes back with it, the hints show at the start, it
// still rains after the song, and the ending reaches the black and hands
// back with the chapter finished.
// Headless Chromium has no speaker and draws phone sizes slowly, so the
// run's feel and sound are Dan's to check on his phone; the whole run
// (2:45) is played by the Godot tests instead (game/tests/test_protector.gd).
import { test, expect, MENU, PROTECTOR } from "./game";

const openRun = async (game: any, query = "") => {
  await game.open(query);
  await game.tap("Tap to begin");
  await game.tap("The Protector (rough)");
  await game.waitForScene(MENU, [PROTECTOR]);
};

const run = (game: any) => game.screen(PROTECTOR);

// The tab going away and coming back, as the browser says it.
const hide = (page: any, hidden: boolean) =>
  page.evaluate((hidden: boolean) => {
    Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
    Object.defineProperty(document, "visibilityState", {
      value: hidden ? "hidden" : "visible",
      configurable: true,
    });
    document.dispatchEvent(new Event("visibilitychange"));
  }, hidden);

test("opens with no words or buttons, and the light runs into the evening", async ({ game }) => {
  // The 3 s of dark and the fade-up draw slowly at phone sizes, more so with
  // the fireflies; the waits below are already up to 120 s on their own.
  test.setTimeout(240_000);
  await openRun(game);
  expect((await game.state()).buttons, "nothing to press: no skip, no menu").toEqual([]);
  // The 3 s of dark first. Phone sizes draw a few frames a second here, and
  // Godot counts at most 8/60 s a frame, so it takes longer than 3 s.
  await expect.poll(async () => (await run(game))?.part, { timeout: 120_000 }).toBe("EUPHORIA");
  await expect.poll(async () => (await run(game)).music).toBe(true);
  await expect.poll(() => game.audioStates()).toContain("running");
  await game.screenshot("protector-euphoria");
});

test("a tap on the left or right moves the light one lane that way", async ({ game }) => {
  // Three taps and a screenshot at phone sizes, a few frames a second: about
  // 2 minutes in CI, over the default 120 s.
  test.setTimeout(240_000);
  await openRun(game, "&protector_from=8");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(8);
  expect((await run(game)).hints, "the hint on each half").toEqual(["tap here", "tap here"]);
  await game.screenshot("protector-tap-here");
  await game.tapAt(0.1, 0.5);
  await expect.poll(async () => (await run(game)).lane).toBe(-1);
  await game.tapAt(0.9, 0.5);
  await expect.poll(async () => (await run(game)).lane, "one lane right: the middle").toBe(0);
  await game.tapAt(0.9, 0.5);
  await expect.poll(async () => (await run(game)).lane).toBe(1);
  await game.screenshot("protector-right-lane");
});

test("a hold through a gap lays the hand across it and the light crosses", async ({ game, page }) => {
  // The first gap touches the light at 0:32.3 and is in reach from 0:31.
  await openRun(game, "&protector_from=30.2");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(30.2);
  expect((await run(game)).hints, "the hold hint, before the first gap").toEqual(["hold"]);
  // A finger goes down in the middle of the screen before the gap is in
  // reach and stays down; the hand goes across when the gap comes into reach.
  const mouse = (type: string) =>
    page.evaluate((type) => {
      const canvas = document.querySelector("canvas")!;
      const r = canvas.getBoundingClientRect();
      const at = { clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, button: 0, bubbles: true };
      canvas.dispatchEvent(new MouseEvent(type, at));
    }, type);
  await mouse("mousedown");
  await expect.poll(async () => (await run(game)).holding).toBe(true);
  await expect.poll(async () => (await run(game)).bridged, { timeout: 60_000 }).toBe(1);
  expect((await run(game)).lane, "a hold never moves the lane").toBe(0);
  await game.screenshot("protector-hand-across-gap");
  await expect.poll(async () => (await run(game)).time, { timeout: 60_000 }).toBeGreaterThan(32.6);
  await mouse("mouseup");
  expect((await run(game)).stumbled, "the light ran over the hand").toBe(0);
});

test("hiding the tab pauses the run until a tap, and the sound comes back", async ({ game, page }) => {
  await openRun(game, "&protector_from=20");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(21);
  const setHidden = (hidden: boolean) => hide(page, hidden);
  await expect.poll(() => game.audioStates()).toContain("running");
  await setHidden(true);
  await expect.poll(async () => (await run(game)).paused).toBe(true);
  // Safari stops the page's sound while the tab is away, and it stays
  // stopped (Dan, 2026-10-27): suspend every audio context the same way.
  await page.evaluate(() => Promise.all((window as any).__audioContexts.map((c: AudioContext) => c.suspend())));
  expect(await game.audioStates()).not.toContain("running");
  const frozen = (await run(game)).time;
  await page.waitForTimeout(1500);
  expect((await run(game)).time, "the run's clock stops while hidden").toBeCloseTo(frozen, 3);
  await setHidden(false);
  await game.tapMiddle();
  await expect.poll(async () => (await run(game)).paused).toBe(false);
  await expect.poll(async () => (await run(game)).time).toBeGreaterThan(frozen + 0.5);
  await expect.poll(() => game.audioStates(), "the sound comes back with the tap").not.toContain("suspended");
  expect((await run(game)).music).toBe(true);
  expect((await game.state()).progress.finished, "hiding never saves").toEqual([]);
});

test("after the tab comes back, the first tap restarts the sound", async ({ game, page }) => {
  // Safari can say the page's sound is running while it is silent after a
  // tab switch (Dan, 2026-10-27, call 20), so the first tap back restarts it.
  await openRun(game, "&protector_from=20");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(21);
  await expect.poll(() => game.audioStates()).toContain("running");
  await hide(page, true);
  await expect.poll(async () => (await run(game)).paused).toBe(true);
  await hide(page, false);
  await game.tapMiddle();
  await expect.poll(() => page.evaluate(() => (window as any).thresholdSoundBack.restarts)).toBe(1);
  await expect.poll(() => game.audioStates()).not.toContain("suspended");
  await expect.poll(async () => (await run(game)).music).toBe(true);
  await game.tapMiddle();
  expect(await page.evaluate(() => (window as any).thresholdSoundBack.restarts), "only the first tap back").toBe(1);
});

// Phone sizes draw a few frames a second here, and Godot counts at most
// 8/60 s a frame, so a few seconds of run can take a minute or more.
const SLOW = { timeout: 150_000 };

test("the panic: dark and raining", async ({ game }) => {
  test.setTimeout(240_000);
  await openRun(game, "&protector_from=115");
  await expect.poll(async () => (await run(game))?.time ?? 0, SLOW).toBeGreaterThan(115.5);
  expect((await run(game)).raining).toBe(true);
  await game.screenshot("protector-panic");
});

test("after the song: the storm plays on and it is still raining", async ({ game }) => {
  test.setTimeout(240_000);
  await openRun(game, "&protector_from=131");
  await expect.poll(async () => (await run(game))?.time ?? 0, SLOW).toBeGreaterThan(131.5);
  expect((await run(game)).part).toBe("FADE");
  expect((await run(game)).music, "the storm plays on").toBe(true);
  expect((await run(game)).raining, "and it is still raining").toBe(true);
  await game.screenshot("protector-after-the-song");
});

test("the light goes out, then black, then the chapter is finished and saved", async ({ game }) => {
  test.setTimeout(300_000);
  // After the Partner, so the Protector is the next chapter and can be saved.
  // From 2:33, near the end of the light going out in the hand at the fallen
  // tree (2:25 to 2:35), so the slow phone sizes reach the black in time.
  await openRun(game, "&finish=partner&protector_from=153");
  await expect.poll(async () => (await run(game))?.time ?? 0, SLOW).toBeGreaterThan(153.2);
  expect((await run(game)).held, "the light is in the father's hand").toBe(true);
  expect((await run(game)).hints, "no words at the end").toEqual([]);
  await game.screenshot("protector-going-out");
  await expect
    .poll(async () => (await run(game))?.brightness ?? 0, SLOW)
    .toBe(0);
  await game.screenshot("protector-empty-hand");
  // PLACEHOLDER until the car (DAS-98): the chapter finishes at the black.
  // Phone sizes draw a few frames a second here, so the last 12 s take longer.
  await expect
    .poll(async () => (await game.state())?.overlays, { timeout: 200_000 })
    .toEqual([]);
  await game.findButton("The Protector (rough)");
  expect((await game.state()).progress.finished.map((c: any) => c.chapter)).toEqual([
    "partner",
    "protector",
  ]);
});
