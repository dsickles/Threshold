// The playtest overlay (game/_core/test_probe/playtest_overlay.gd): frame
// rate and clocks in the corner of review builds and "?overlay" addresses
// only (CLAUDE.md, "Rough chapters"). Players never see it.
import { test, expect } from "./game";

const overlayOn = (page: any) => page.evaluate(() => (window as any).thresholdOverlayOn === true);

test("the playtest overlay is off for players", async ({ game, page }) => {
  await game.open();
  await game.findButton("Tap to begin");
  expect(await overlayOn(page)).toBe(false);
});

test("the playtest overlay shows with ?overlay", async ({ game, page }) => {
  await game.open("&overlay");
  await game.findButton("Tap to begin");
  await expect.poll(() => overlayOn(page)).toBe(true);
  await game.screenshot("playtest-overlay");
});
