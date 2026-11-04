// Pausing a chapter while playing (DAS-130): every chapter the runner starts
// gets a pause button in the top-right corner; it opens a panel with Resume,
// taps anywhere else do nothing, and Resume carries on where the player left
// off. In the Partner the song (the browser's own audio clock) is held and
// picks up from the same point. Whether the sound really stops and comes back
// in step on an iPhone is Dan's to check on his phone.
import { test, expect, MENU, PARTNER, ProbeButton } from "./game";

const STAND_IN = "res://scenes/chapters/stand_in/stand_in_chapter.tscn";

const pauseButton = async (game: any): Promise<ProbeButton> => {
  let found: ProbeButton | undefined;
  await expect
    .poll(async () => {
      found = ((await game.state())?.buttons ?? []).find((b: any) => b.name === "PauseButton");
      return found !== undefined;
    }, { message: "the pause button" })
    .toBe(true);
  return found!;
};

const paused = async (game: any) => (await game.state())?.paused ?? false;

test.beforeEach(async ({ game }) => {
  await game.open();
  await game.tap("Tap to begin");
});

test("the menu (the House) has no pause button", async ({ game }) => {
  await game.findButton("Stand-in chapter");
  const names = ((await game.state())!.buttons as any[]).map((b) => b.name);
  expect(names).not.toContain("PauseButton");
});

test("stand-in chapter: pause, taps off the panel do nothing, Resume carries on", async ({ game }) => {
  await game.tap("Stand-in chapter");
  await game.waitForScene(MENU, [STAND_IN]);
  const button = await pauseButton(game);
  const { size } = (await game.state())!;
  expect(button.x, "in the right half").toBeGreaterThan(size.x / 2);
  expect(button.y, "at the top").toBeLessThan(size.y / 4);
  await game.tapButton(button);
  await expect.poll(() => paused(game)).toBe(true);
  await game.findButton("Resume");
  await game.screenshot("chapter-paused");
  // The chapter's own buttons are under the scrim and do nothing.
  await game.tap("Finish");
  await game.tapAt(0.1, 0.9);
  await game.page.waitForTimeout(500);
  expect(await paused(game), "still paused").toBe(true);
  await game.waitForScene(MENU, [STAND_IN]);
  await game.tap("Resume");
  await expect.poll(() => paused(game)).toBe(false);
  await pauseButton(game);
  // And the chapter works again.
  await game.tap("Finish");
  await game.findButton("Smoothness");
  await game.waitForScene(MENU);
});

test("the Partner: the song holds while paused and picks up where it was", async ({ game, page }) => {
  await game.tap("The Partner (rough)");
  await game.waitForScene(MENU, [PARTNER]);
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
  await game.tapMiddle();
  const songTime = () => page.evaluate(() => (window as any).partnerConductor.songTime());
  await expect.poll(songTime, { timeout: 30_000 }).toBeGreaterThan(3);
  await game.tapButton(await pauseButton(game));
  await expect.poll(() => paused(game)).toBe(true);
  await expect.poll(() => page.evaluate(() => (window as any).partnerConductor.paused())).toBe(true);
  const held = await songTime();
  const judged = async () => {
    const p = await game.screen(PARTNER);
    return p.hits + p.misses;
  };
  const before = await judged();
  // Off the panel (Resume sits in the middle).
  await game.tapAt(0.5, 0.9);
  await page.waitForTimeout(2000);
  expect(await songTime(), "the song's clock stops while paused").toBeCloseTo(held, 2);
  expect(await judged(), "a tap while paused judges nothing").toBe(before);
  await game.screenshot("partner-paused-panel");
  const tappedAt = Date.now();
  await game.tap("Resume");
  await expect.poll(() => paused(game)).toBe(false);
  await expect.poll(async () => (await game.screen(PARTNER)).state).toBe("PLAYING");
  await expect.poll(songTime).toBeGreaterThan(held + 0.5);
  // Picks up from where it was held: it moved on only by the time since
  // Resume, not by the 2 s it was paused.
  const sinceTap = (Date.now() - tappedAt) / 1000;
  expect(await songTime()).toBeLessThanOrEqual(held + sinceTap + 0.3);
  expect(await songTime()).toBeGreaterThanOrEqual(held - 0.3);
  expect((await game.screen(PARTNER)).layer, "the streak layer is back too").toBe(true);
});
