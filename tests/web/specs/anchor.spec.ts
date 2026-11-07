// The Anchor (DAS-138): it opens from the menu (until the flat-pack crib box
// in the House can start it), plays with no console errors and no words or
// buttons, its sound starts, holding a zone leans Leo that way, and hiding
// the tab pauses it until a tap.
// Headless Chromium has no speaker, so how heavy the crib feels, how the
// zones sit under two thumbs and how "You've got this." lands are Dan's to
// check on his phone; the whole carry to the window, the falls and Maya's
// line are played by the Godot tests (game/tests/test_anchor.gd).
import { test, expect, MENU } from "./game";

const ANCHOR = "res://scenes/chapters/anchor/anchor.tscn";

const openAnchor = async (game: any) => {
  await game.open();
  await game.tap("Tap to begin");
  await game.tap("The Anchor (rough)");
  await game.waitForScene(MENU, [ANCHOR]);
};

const anchor = (game: any) => game.screen(ANCHOR);

// Holds a zone (0 left, 1 right) for `ms`: a finger on phone sizes, the
// mouse on a laptop. Returns the lean while it was still held.
const holdZone = async (game: any, page: any, which: number, ms: number) => {
  const zone = (await anchor(game)).zones[which];
  const at = await game.toPage({ text: "", disabled: false, x: zone.x, y: zone.y });
  let cdp: any = null;
  if (game.hasTouch) {
    cdp = await page.context().newCDPSession(page);
    await cdp.send("Input.dispatchTouchEvent", { type: "touchStart", touchPoints: [{ x: at.x, y: at.y }] });
  } else {
    await page.mouse.move(at.x, at.y);
    await page.mouse.down();
  }
  await page.waitForTimeout(ms);
  const held = await anchor(game);
  if (cdp) {
    await cdp.send("Input.dispatchTouchEvent", { type: "touchEnd", touchPoints: [] });
    await cdp.detach();
  } else {
    await page.mouse.up();
  }
  return held;
};

test("opens in the calm, no words or buttons, and its sound starts", async ({ game }) => {
  await openAnchor(game);
  expect((await game.state()).buttons, "nothing to press: no labels, no skip").toEqual([]);
  await expect.poll(async () => (await anchor(game))?.time ?? 0).toBeGreaterThan(1);
  const state = await anchor(game);
  expect(state.stage).toBe("STEADY");
  expect(state.subtitle, "no words at the start").toBe("");
  expect(state.falls).toBe(0);
  expect(state.zones.length, "two hold zones").toBe(2);
  expect(state.sound).toBe(true);
  await expect.poll(() => game.audioStates()).toContain("running");
  await game.screenshot("anchor-calm");
});

test("holding a zone leans Leo that way", async ({ game, page }) => {
  test.setTimeout(120_000);
  await openAnchor(game);
  await expect.poll(async () => (await anchor(game))?.time ?? 0).toBeGreaterThan(0.5);
  const left = await holdZone(game, page, 0, 700);
  expect(left.hold, "the left zone is held").toBe(-1);
  expect(left.lean, "leaning left").toBeLessThan(-0.1);
  await game.screenshot("anchor-leaning-left");
  await expect.poll(async () => (await anchor(game)).hold).toBe(0);
  // Let him come back up (or fall and get up) before trying the other side.
  await page.waitForTimeout(4000);
  const right = await holdZone(game, page, 1, 700);
  expect(right.hold, "the right zone is held").toBe(1);
  expect(right.lean, "leaning right").toBeGreaterThan(0.1);
  await expect.poll(async () => (await anchor(game)).hold).toBe(0);
});

test("hiding the tab pauses it until a tap, and never saves", async ({ game, page }) => {
  await openAnchor(game);
  await expect.poll(async () => (await anchor(game))?.time ?? 0).toBeGreaterThan(1);
  const hide = (hidden: boolean) =>
    page.evaluate((hidden: boolean) => {
      Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
      Object.defineProperty(document, "visibilityState", { value: hidden ? "hidden" : "visible", configurable: true });
      document.dispatchEvent(new Event("visibilitychange"));
    }, hidden);
  await hide(true);
  await expect.poll(async () => (await anchor(game)).paused).toBe(true);
  expect((await anchor(game)).sound, "the sound stops").toBe(false);
  const frozen = (await anchor(game)).time;
  await page.waitForTimeout(1500);
  expect((await anchor(game)).time, "the clock stops while hidden").toBeCloseTo(frozen, 3);
  await hide(false);
  await game.tapMiddle();
  await expect.poll(async () => (await anchor(game)).paused).toBe(false);
  await expect.poll(async () => (await anchor(game)).time).toBeGreaterThan(frozen + 0.5);
  expect((await anchor(game)).sound).toBe(true);
  expect((await game.state()).progress.finished, "hiding never saves").toEqual([]);
});
