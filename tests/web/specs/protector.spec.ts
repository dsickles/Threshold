// The Protector's run (DAS-97): it opens from the menu (until the bedside
// lamp in the House can start it, DAS-95), plays with no console errors, a
// tap on a third of the screen moves the light to that lane, a tap with a
// gap in reach lays the hand across it, hiding the tab pauses it until a
// tap, it still rains after the song, and the ending reaches the black and
// hands back with the chapter finished.
// Headless Chromium has no speaker and draws phone sizes slowly, so the
// run's feel and sound are Dan's to check on his phone; the whole run
// (3:35) is played by the Godot tests instead (game/tests/test_protector.gd).
import { test, expect, MENU, PROTECTOR } from "./game";

const openRun = async (game: any, query = "") => {
  await game.open(query);
  await game.tap("Tap to begin");
  await game.tap("The Protector (rough)");
  await game.waitForScene(MENU, [PROTECTOR]);
};

const run = (game: any) => game.screen(PROTECTOR);

test("opens with no words or buttons, and the light runs into the evening", async ({ game }) => {
  await openRun(game);
  expect((await game.state()).buttons, "nothing to press: no skip, no menu").toEqual([]);
  // The 5 s of dark first. Phone sizes draw a few frames a second here, and
  // Godot counts at most 8/60 s a frame, so it takes longer than 5 s.
  await expect.poll(async () => (await run(game))?.part, { timeout: 120_000 }).toBe("EUPHORIA");
  await expect.poll(async () => (await run(game)).music).toBe(true);
  await expect.poll(() => game.audioStates()).toContain("running");
  await game.screenshot("protector-euphoria");
});

test("a tap on a third of the screen moves the light to that lane", async ({ game }) => {
  await openRun(game, "&protector_from=8");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(8);
  await game.tapAt(0.1, 0.5);
  await expect.poll(async () => (await run(game)).lane).toBe(-1);
  await game.tapAt(0.9, 0.5);
  await expect.poll(async () => (await run(game)).lane).toBe(1);
  await game.screenshot("protector-right-lane");
});

test("a tap with a gap in reach lays the hand across it", async ({ game, page }) => {
  // The first gap touches the light at 0:34 and is in reach from 0:32.7.
  await openRun(game, "&protector_from=31.5");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(31.5);
  // Headless Chromium draws slowly: a tap sent from here after reading the
  // probe can land too late for the 1.3 s window. So the page itself watches
  // for the gap to come into reach and clicks the middle of the canvas in
  // the same frame.
  await page.evaluate(
    (scene) =>
      new Promise<void>((resolve) => {
        const look = () => {
          const probe = JSON.parse((window as any).thresholdProbe ?? "{}");
          if (!(probe.screens?.[scene]?.in_reach > 0)) return requestAnimationFrame(look);
          const canvas = document.querySelector("canvas")!;
          const r = canvas.getBoundingClientRect();
          const at = { clientX: r.left + r.width / 2, clientY: r.top + r.height / 2, button: 0, bubbles: true };
          canvas.dispatchEvent(new MouseEvent("mousedown", at));
          canvas.dispatchEvent(new MouseEvent("mouseup", at));
          resolve();
        };
        look();
      }),
    PROTECTOR,
  );
  await expect.poll(async () => (await run(game)).bridged).toBe(1);
  await game.screenshot("protector-hand-across-gap");
  await expect.poll(async () => (await run(game)).time, { timeout: 60_000 }).toBeGreaterThan(34.2);
  expect((await run(game)).stumbled, "the light ran over the hand").toBe(0);
});

test("hiding the tab pauses the run until a tap", async ({ game, page }) => {
  await openRun(game, "&protector_from=20");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(21);
  const setHidden = (hidden: boolean) =>
    page.evaluate((hidden) => {
      Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
      Object.defineProperty(document, "visibilityState", {
        value: hidden ? "hidden" : "visible",
        configurable: true,
      });
      document.dispatchEvent(new Event("visibilitychange"));
    }, hidden);
  await setHidden(true);
  await expect.poll(async () => (await run(game)).paused).toBe(true);
  const frozen = (await run(game)).time;
  await page.waitForTimeout(1500);
  expect((await run(game)).time, "the run's clock stops while hidden").toBeCloseTo(frozen, 3);
  await setHidden(false);
  await game.tapMiddle();
  await expect.poll(async () => (await run(game)).paused).toBe(false);
  await expect.poll(async () => (await run(game)).time).toBeGreaterThan(frozen + 0.5);
  expect((await game.state()).progress.finished, "hiding never saves").toEqual([]);
});

test("the panic, and the rain after the song", async ({ game }) => {
  await openRun(game, "&protector_from=150");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(151);
  expect((await run(game)).raining).toBe(true);
  await game.screenshot("protector-panic");
  await openRun(game, "&protector_from=178");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(179);
  expect((await run(game)).part).toBe("FADE");
  expect((await run(game)).music, "the storm plays on").toBe(true);
  expect((await run(game)).raining, "and it is still raining").toBe(true);
  await game.screenshot("protector-after-the-song");
});

test("the light goes out, then black, then the chapter is finished and saved", async ({ game }) => {
  test.setTimeout(300_000);
  // After the Partner, so the Protector is the next chapter and can be saved.
  await openRun(game, "&finish=partner&protector_from=197");
  await expect.poll(async () => (await run(game))?.time ?? 0).toBeGreaterThan(198);
  expect((await run(game)).held, "the light is in the father's hand").toBe(true);
  await game.screenshot("protector-going-out");
  await expect
    .poll(async () => (await run(game))?.brightness ?? 0, { timeout: 60_000 })
    .toBe(0);
  await game.screenshot("protector-empty-hand");
  // PLACEHOLDER until the car (DAS-98): the chapter finishes at the black.
  // Phone sizes draw a few frames a second here, so the last 18 s take longer.
  await expect
    .poll(async () => (await game.state())?.overlays, { timeout: 200_000 })
    .toEqual([]);
  await game.findButton("The Protector (rough)");
  expect((await game.state()).progress.finished.map((c: any) => c.chapter)).toEqual([
    "partner",
    "protector",
  ]);
});
