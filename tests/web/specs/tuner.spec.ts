// The Tuner (DAS-135): it opens from the menu (until the home doppler on the
// nightstand in the House can start it), plays with no console errors and
// no words or buttons, its sound starts, a knob turns when dragged round,
// and hiding the tab pauses it until a tap.
// Headless Chromium has no speaker, so how the knobs feel and how the hum
// and the heartbeat sound are Dan's to check on his phone; the whole search
// to the picture is played by the Godot tests (game/tests/test_tuner.gd).
import { test, expect, MENU } from "./game";

const TUNER = "res://scenes/chapters/tuner/tuner.tscn";

const openTuner = async (game: any) => {
  await game.open();
  await game.tap("Tap to begin");
  await game.tap("The Tuner (rough)");
  await game.waitForScene(MENU, [TUNER]);
};

const tuner = (game: any) => game.screen(TUNER);

// Drags round a knob, a finger on phone sizes and the mouse on a laptop:
// from its right-hand edge, `degrees` clockwise, in small steps.
const turnKnob = async (game: any, page: any, which: number, degrees: number) => {
  const knob = (await tuner(game)).knobCentres[which];
  const points: { x: number; y: number }[] = [];
  for (let k = 0; k <= 16; k++) {
    const a = (degrees * k / 16) * Math.PI / 180;
    points.push(await game.toPage({
      text: "", disabled: false,
      x: knob.x + Math.cos(a) * knob.r * 0.7,
      y: knob.y + Math.sin(a) * knob.r * 0.7,
    }));
  }
  if (game.hasTouch) {
    const cdp = await page.context().newCDPSession(page);
    const touch = (type: string, p?: { x: number; y: number }) =>
      cdp.send("Input.dispatchTouchEvent", { type, touchPoints: p ? [{ x: p.x, y: p.y }] : [] });
    await touch("touchStart", points[0]);
    for (const p of points.slice(1)) {
      await touch("touchMove", p);
      await page.waitForTimeout(30);
    }
    await touch("touchEnd");
    await cdp.detach();
  } else {
    await page.mouse.move(points[0].x, points[0].y);
    await page.mouse.down();
    for (const p of points.slice(1)) {
      await page.mouse.move(p.x, p.y);
      await page.waitForTimeout(30);
    }
    await page.mouse.up();
  }
};

test("opens with static, no words or buttons, and its sound starts", async ({ game }) => {
  await openTuner(game);
  expect((await game.state()).buttons, "nothing to press: no labels, no skip").toEqual([]);
  await expect.poll(async () => (await tuner(game))?.time ?? 0).toBeGreaterThan(1);
  const state = await tuner(game);
  expect(state.stage).toBe("SEARCH_HUM");
  expect(state.clarity, "all static at first").toBe(0);
  expect(state.sound).toBe(true);
  await expect.poll(() => game.audioStates()).toContain("running");
  await game.screenshot("tuner-static");
});

test("a knob turns when dragged round it", async ({ game, page }) => {
  test.setTimeout(180_000);
  await openTuner(game);
  await expect.poll(async () => (await tuner(game))?.time ?? 0).toBeGreaterThan(0.5);
  const before = (await tuner(game)).knobs;
  await turnKnob(game, page, 0, 120);
  await expect.poll(async () => (await tuner(game)).knobs[0], { timeout: 60_000 }).toBeGreaterThan(before[0] + 0.1);
  expect((await tuner(game)).knobs[1], "the other knob stays put").toBeCloseTo(before[1], 5);
  await turnKnob(game, page, 1, -90);
  await expect.poll(async () => (await tuner(game)).knobs[1], { timeout: 60_000 }).toBeLessThan(before[1] - 0.1);
  await game.screenshot("tuner-knobs-turned");
});

test("hiding the tab pauses it until a tap, and never saves", async ({ game, page }) => {
  await openTuner(game);
  await expect.poll(async () => (await tuner(game))?.time ?? 0).toBeGreaterThan(1);
  const hide = (hidden: boolean) =>
    page.evaluate((hidden: boolean) => {
      Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
      Object.defineProperty(document, "visibilityState", { value: hidden ? "hidden" : "visible", configurable: true });
      document.dispatchEvent(new Event("visibilitychange"));
    }, hidden);
  await hide(true);
  await expect.poll(async () => (await tuner(game)).paused).toBe(true);
  expect((await tuner(game)).sound, "the sound stops").toBe(false);
  const frozen = (await tuner(game)).time;
  await page.waitForTimeout(1500);
  expect((await tuner(game)).time, "the clock stops while hidden").toBeCloseTo(frozen, 3);
  await hide(false);
  await game.tapMiddle();
  await expect.poll(async () => (await tuner(game)).paused).toBe(false);
  await expect.poll(async () => (await tuner(game)).time).toBeGreaterThan(frozen + 0.5);
  expect((await tuner(game)).sound).toBe(true);
  expect((await game.state()).progress.finished, "hiding never saves").toEqual([]);
});
