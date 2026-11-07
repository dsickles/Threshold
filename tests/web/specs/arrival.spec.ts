// The Arrival (DAS-137): it opens from the menu (until the hospital bag and
// the keys in the House can start it), plays with no console errors and no
// buttons, sound starts only after a tap, the door beat's taps work, a knob
// turns when dragged in the cry beat, the hand beat uses the browser's audio
// clock and judges a tap, and hiding the tab pauses it until a tap.
// Headless Chromium has no speaker, so whether the cry lands and whether
// the taps line up with the heartbeat you hear are Dan's to check on his
// phone; the whole chapter is played by the Godot tests
// (game/tests/test_arrival.gd).
import { test, expect, MENU } from "./game";

const ARRIVAL = "res://scenes/chapters/arrival/arrival.tscn";

const openArrival = async (game: any, query = "") => {
  await game.open(query);
  await game.tap("Tap to begin");
  await game.tap("The Arrival (rough)");
  await game.waitForScene(MENU, [ARRIVAL]);
};

const arrival = (game: any) => game.screen(ARRIVAL);

const tapTarget = async (game: any, name: string) => {
  const at = (await arrival(game)).targets[name];
  await game.tapButton({ text: "", x: at.x, y: at.y, disabled: false });
};

// Drags round a knob, a finger on phone sizes and the mouse on a laptop:
// from its right-hand edge, `degrees` clockwise, in small steps.
const turnKnob = async (game: any, page: any, which: number, degrees: number) => {
  const knob = (await arrival(game)).knobCentres[which];
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

test("opens at the door, with no buttons, and the bag, keys and door take taps in order", async ({ game }) => {
  await openArrival(game);
  expect((await game.state()).buttons, "nothing to press: no labels, no skip").toEqual([]);
  await expect.poll(async () => (await arrival(game))?.beat).toBe("DOOR");
  expect((await arrival(game)).next).toBe("bag");
  await game.screenshot("arrival-door");
  await tapTarget(game, "bag");
  await expect.poll(async () => (await arrival(game)).bagTries).toBe(1);
  expect((await arrival(game)).next, "the bag won't shut the first time").toBe("bag");
  await game.screenshot("arrival-bag-burst");
  await tapTarget(game, "bag");
  await expect.poll(async () => (await arrival(game)).next).toBe("keys");
  await tapTarget(game, "keys");
  await expect.poll(async () => (await arrival(game)).next).toBe("door");
  await tapTarget(game, "door");
  await expect.poll(async () => (await arrival(game)).beat, { timeout: 15_000 }).toBe("CRY");
  expect((await arrival(game)).sound).toBe(true);
  await expect.poll(() => game.audioStates()).toContain("running");
  expect((await game.state()).progress.finished, "playing never saves part-way").toEqual([]);
});

test("in the cry beat a knob turns when dragged round it", async ({ game, page }) => {
  test.setTimeout(180_000);
  await openArrival(game, "&arrival_beat=cry");
  await expect.poll(async () => (await arrival(game))?.beat).toBe("CRY");
  await expect.poll(async () => (await arrival(game)).time).toBeGreaterThan(0.5);
  expect((await arrival(game)).clarity, "all static at first").toBe(0);
  await game.screenshot("arrival-cry-static");
  const before = (await arrival(game)).knobs;
  await turnKnob(game, page, 0, 120);
  await expect.poll(async () => (await arrival(game)).knobs[0], { timeout: 60_000 }).toBeGreaterThan(before[0] + 0.1);
  expect((await arrival(game)).knobs[1], "the other knob stays put").toBeCloseTo(before[1], 5);
  await game.screenshot("arrival-cry-knob-turned");
});

test("the hand beat plays on the browser's clock and judges a tap", async ({ game }) => {
  test.setTimeout(120_000);
  await openArrival(game, "&arrival_beat=hand");
  await expect.poll(async () => (await arrival(game))?.beat).toBe("HAND");
  expect((await arrival(game)).clock, "the web build uses the browser's audio clock").toBe("browser");
  // The song needs a tap to make sound on a phone; the first tap also counts.
  await game.tapMiddle();
  await expect.poll(async () => (await arrival(game)).songTime, { timeout: 30_000 }).toBeGreaterThan(3);
  await expect.poll(() => game.audioStates()).toContain("running");
  // Headless timing is loose and the probe lags a frame, so rather than aim
  // for one note, tap every 100 ms for a few seconds after the intro: some
  // tap always lands inside the Good window of a note. Stray taps between
  // notes do nothing, so any hit shows the rhythm is judging taps.
  await expect.poll(async () => (await arrival(game)).songTime, { timeout: 30_000 }).toBeGreaterThan(8);
  let judged = false;
  for (let k = 0; k < 40 && !judged; k++) {
    await game.tapMiddle();
    await game.page.waitForTimeout(100);
    judged = (await arrival(game)).hits > 0;
  }
  expect(judged, "a tap on the beat was judged a hit").toBe(true);
  await game.screenshot("arrival-hand");
  // Untapped notes become misses; the beat keeps going.
  await expect.poll(async () => (await arrival(game)).misses, { timeout: 15_000 }).toBeGreaterThan(0);
  expect((await arrival(game)).beat).toBe("HAND");
});

test("hiding the tab pauses it until a tap, and never saves", async ({ game, page }) => {
  await openArrival(game, "&arrival_beat=cry");
  await expect.poll(async () => (await arrival(game))?.time ?? 0).toBeGreaterThan(1);
  const hide = (hidden: boolean) =>
    page.evaluate((hidden: boolean) => {
      Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
      Object.defineProperty(document, "visibilityState", { value: hidden ? "hidden" : "visible", configurable: true });
      document.dispatchEvent(new Event("visibilitychange"));
    }, hidden);
  await hide(true);
  await expect.poll(async () => (await arrival(game)).paused).toBe(true);
  expect((await arrival(game)).sound, "the sound stops").toBe(false);
  const frozen = (await arrival(game)).time;
  await page.waitForTimeout(1500);
  expect((await arrival(game)).time, "the clock stops while hidden").toBeCloseTo(frozen, 3);
  await hide(false);
  await game.tapMiddle();
  await expect.poll(async () => (await arrival(game)).paused).toBe(false);
  await expect.poll(async () => (await arrival(game)).time).toBeGreaterThan(frozen + 0.5);
  expect((await game.state()).progress.finished, "hiding never saves").toEqual([]);
});
