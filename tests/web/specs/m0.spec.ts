// The M0 build: it loads, sound waits for the first tap, and each M0 check
// opens and returns to the menu. Runs at laptop, phone and sideways-phone sizes.
import { test, expect, MENU, SMOOTHNESS, VIEWPOINTS, RHYTHM } from "./game";

test.beforeEach(async ({ game }) => {
  await game.open();
});

test("loads to Tap to begin", async ({ game }) => {
  await game.findButton("Tap to begin");
  await game.screenshot("tap-to-begin");
});

test("sound starts only after the first tap", async ({ game }) => {
  await expect.poll(() => game.audioStates()).not.toEqual([]);
  expect(await game.audioStates()).not.toContain("running");
  await game.tap("Tap to begin");
  await expect.poll(() => game.audioStates()).toContain("running");
  await game.findButton("Smoothness");
  await game.screenshot("menu");
});

test("Smoothness opens and goes back to the menu", async ({ game }) => {
  await game.tap("Tap to begin");
  await game.tap("Smoothness");
  await game.waitForScene(SMOOTHNESS);
  await game.findButton("Heavy: off");
  await game.screenshot("smoothness");
  await game.tap("Back to menu");
  await game.waitForScene(MENU);
});

test("Rhythm timing opens, plays the click and goes back", async ({ game }) => {
  await game.tap("Tap to begin");
  await game.tap("Rhythm timing");
  await game.waitForScene(MENU, [RHYTHM]);
  await game.tap("Start click");
  await game.findButton("Stop click");
  await game.tap("Tap here");
  await game.screenshot("rhythm-timing");
  await game.tap("Stop click");
  await game.tap("Back");
  await game.waitForScene(MENU);
  await game.findButton("Smoothness");
});

test("Viewpoints opens, glides to a view and goes back", async ({ game }) => {
  await game.tap("Tap to begin");
  await game.tap("Viewpoints");
  await game.waitForScene(VIEWPOINTS);
  await game.screenshot("viewpoints-start");
  // The rings on things have no text (or just an edge arrow).
  const rings = async () =>
    (await game.state())!.buttons.filter((b) => ["", "‹", "›"].includes(b.text));
  const before = await rings();
  expect(before, "a ring on each thing").toHaveLength(4);
  await game.tapButton(before[0]);
  // The ring for the view you are at hides.
  await expect.poll(async () => (await rings()).length).toBe(3);
  await game.screenshot("viewpoints-after-glide");
  await game.tap("Back to menu");
  await game.waitForScene(MENU);
});
