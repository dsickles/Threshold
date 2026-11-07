// The Mourner (DAS-136): it opens from the menu (until Leo's things in the
// spare room in the House can start it), plays with no console errors and
// no words or buttons, its sound starts, a thing can be dragged to its
// place, and hiding the tab pauses it until a tap.
// Headless Chromium has no speaker, so how dragging feels and how the score
// sounds are Dan's to check on his phone; the whole room to the crib is
// played by the Godot tests (game/tests/test_mourner.gd).
import { test, expect, MENU } from "./game";

const MOURNER = "res://scenes/chapters/mourner/mourner.tscn";

const openMourner = async (game: any) => {
  await game.open();
  await game.tap("Tap to begin");
  await game.tap("The Mourner (rough)");
  await game.waitForScene(MENU, [MOURNER]);
};

const mourner = (game: any) => game.screen(MOURNER);

const point = (game: any, x: number, y: number) =>
  game.toPage({ text: "", disabled: false, x, y });

// Drags from one point to another (game units), a finger on phone sizes and
// the mouse on a laptop, in small steps.
const drag = async (game: any, page: any, from: { x: number; y: number }, to: { x: number; y: number }) => {
  const points: { x: number; y: number }[] = [];
  for (let k = 0; k <= 16; k++) {
    points.push(await point(game, from.x + (to.x - from.x) * k / 16, from.y + (to.y - from.y) * k / 16));
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

test("opens on the spare room, no words or buttons, and its sound starts", async ({ game }) => {
  await openMourner(game);
  expect((await game.state()).buttons, "nothing to press: no labels, no skip").toEqual([]);
  await expect.poll(async () => (await mourner(game))?.stage).toBe("OLD_THINGS");
  const state = await mourner(game);
  expect(Object.keys(state.things).sort()).toEqual(["games_box", "guitar", "poster", "stuff_box", "tshirts_box"]);
  expect(state.sound).toBe(true);
  await expect.poll(() => game.audioStates()).toContain("running");
  await game.screenshot("mourner-room");
});

test("a thing dragged to its place stays there", async ({ game, page }) => {
  test.setTimeout(120_000);
  await openMourner(game);
  await expect.poll(async () => (await mourner(game))?.stage).toBe("OLD_THINGS");
  const guitar = (await mourner(game)).things.guitar;
  await drag(game, page, { x: guitar.x, y: guitar.y }, { x: guitar.toX, y: guitar.toY });
  await expect.poll(async () => (await mourner(game)).things.guitar.placed, { timeout: 30_000 }).toBe(true);
  // One dropped in the wrong place goes back.
  const poster = (await mourner(game)).things.poster;
  const wrong = (await mourner(game)).things.games_box;
  await drag(game, page, { x: poster.x, y: poster.y }, { x: wrong.toX, y: wrong.toY });
  await page.waitForTimeout(1000);
  const after = (await mourner(game)).things.poster;
  expect(after.placed).toBe(false);
  expect(after.x).toBeCloseTo(poster.x, 0);
  await game.screenshot("mourner-guitar-placed");
});

test("hiding the tab pauses it until a tap, and never saves", async ({ game, page }) => {
  await openMourner(game);
  await expect.poll(async () => (await mourner(game))?.time ?? 0).toBeGreaterThan(1);
  const hide = (hidden: boolean) =>
    page.evaluate((hidden: boolean) => {
      Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
      Object.defineProperty(document, "visibilityState", { value: hidden ? "hidden" : "visible", configurable: true });
      document.dispatchEvent(new Event("visibilitychange"));
    }, hidden);
  await hide(true);
  await expect.poll(async () => (await mourner(game)).paused).toBe(true);
  expect((await mourner(game)).sound, "the sound stops").toBe(false);
  const frozen = (await mourner(game)).time;
  await page.waitForTimeout(1500);
  expect((await mourner(game)).time, "the clock stops while hidden").toBeCloseTo(frozen, 3);
  await hide(false);
  await game.tapMiddle();
  await expect.poll(async () => (await mourner(game)).paused).toBe(false);
  await expect.poll(async () => (await mourner(game)).time).toBeGreaterThan(frozen + 0.5);
  expect((await mourner(game)).sound).toBe(true);
  expect((await game.state()).progress.finished, "hiding never saves").toEqual([]);
});
