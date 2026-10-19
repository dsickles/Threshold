// The Partner's rough first playable (DAS-73): it opens from the menu, the
// song starts on the first tap with the browser's audio clock, and hiding the
// tab pauses the song and the chart together until a tap. Headless Chromium
// has no speaker, so whether taps line up with the sound is Dan's to check on
// his phone; the whole song (3:28) is played by the Godot tests instead.
import { test, expect, MENU, PARTNER } from "./game";

test.beforeEach(async ({ game }) => {
  await game.open();
  await game.tap("Tap to begin");
  await game.tap("The Partner (rough)");
  await game.waitForScene(MENU, [PARTNER]);
});

const songTime = async (game: any) => (await game.screen(PARTNER))?.song_time ?? -1;

test("opens and waits for a tap, with the song loaded", async ({ game }) => {
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
  const partner = await game.screen(PARTNER);
  expect(partner.prompt).toBe("Tap to begin");
  expect(partner.clock, "the web build uses the browser's audio clock").toBe("browser");
  await game.screenshot("partner-waiting");
});

test("the first tap starts the song and the lights come in", async ({ game }) => {
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
  await game.tapMiddle();
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("PLAYING");
  await expect.poll(() => game.audioStates()).toContain("running");
  // The first lights reach the ring at 4 s; by 6 s the screen shows some.
  await expect.poll(() => songTime(game), { timeout: 30_000 }).toBeGreaterThan(6);
  await game.screenshot("partner-playing");
  // Untapped notes become misses; the song keeps going.
  await expect.poll(async () => (await game.screen(PARTNER)).misses).toBeGreaterThan(0);
  expect((await game.screen(PARTNER)).state).toBe("PLAYING");
});

test("hiding the tab pauses the song until a tap", async ({ game, page }) => {
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
  await game.tapMiddle();
  await expect.poll(() => songTime(game), { timeout: 30_000 }).toBeGreaterThan(2);
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
  await expect.poll(async () => (await game.screen(PARTNER)).state).toBe("PAUSED");
  const frozen = await songTime(game);
  await page.waitForTimeout(1500);
  expect(await songTime(game), "the song's clock stops while hidden").toBeCloseTo(frozen, 1);
  await setHidden(false);
  expect((await game.screen(PARTNER)).prompt).toBe("Tap to continue");
  await game.screenshot("partner-paused");
  const missesBefore = (await game.screen(PARTNER)).misses;
  await game.tapMiddle();
  await expect.poll(async () => (await game.screen(PARTNER)).state).toBe("PLAYING");
  await expect.poll(() => songTime(game)).toBeGreaterThan(frozen + 0.5);
  // Coming back doesn't count the notes that would have passed while hidden.
  expect((await game.screen(PARTNER)).misses).toBeLessThanOrEqual(missesBefore + 1);
});
