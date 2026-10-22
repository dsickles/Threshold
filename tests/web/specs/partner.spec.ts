// The Partner's rough first playable (DAS-73): it opens from the menu, the
// song starts on the first tap with the browser's audio clock, and hiding the
// tab pauses the song and the chart together until a tap. Headless Chromium
// has no speaker, so whether taps line up with the sound is Dan's to check on
// his phone; the whole song (3:04) is played by the Godot tests instead.
import { test, expect, MENU, PARTNER } from "./game";

const openPartner = async (game: any, query = "") => {
  await game.open(query);
  await game.tap("Tap to begin");
  await game.tap("The Partner (rough)");
  await game.waitForScene(MENU, [PARTNER]);
};

// Each test opens the Partner itself; "the ending" starts part-way in.
test.beforeEach(async ({ game }, info) => {
  if (!info.titlePath.includes("the ending")) await openPartner(game);
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
  // The first lights reach the heart at 4 s; by 6 s the screen shows some.
  await expect.poll(() => songTime(game), { timeout: 30_000 }).toBeGreaterThan(6);
  await game.screenshot("partner-playing");
  // The streak layer plays along from the start, even on a quick first tap.
  expect((await game.screen(PARTNER)).layer, "the song's streak layer is playing").toBe(true);
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
  const tappedAt = Date.now();
  await game.tapMiddle();
  await expect.poll(async () => (await game.screen(PARTNER)).state).toBe("PLAYING");
  await expect.poll(() => songTime(game)).toBeGreaterThan(frozen + 0.5);
  // The song picks up where it paused: it has moved on only by the time
  // since the tap, not by the time it was hidden (over 2.5 s here), so the
  // chart's notes didn't pass while hidden.
  const sinceTap = (Date.now() - tappedAt) / 1000;
  expect(await songTime(game)).toBeLessThanOrEqual(frozen + sinceTap + 0.3);
});

// Dan's tool for making the chart from his own taps (chart_recorder.gd).
test("record my taps: no notes, then Stop shows the taps to copy", async ({ game, page }) => {
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
  await game.tap("Record my taps");
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("PLAYING");
  await expect.poll(() => songTime(game), { timeout: 30_000 }).toBeGreaterThan(1);
  await game.tapMiddle();
  await game.tapMiddle();
  await expect.poll(async () => (await game.screen(PARTNER)).recorded).toBe(2);
  expect((await game.screen(PARTNER)).misses, "no notes to miss").toBe(0);
  await game.screenshot("partner-recording");
  await page.getByRole("button", { name: "Stop" }).click();
  await expect.poll(async () => (await game.screen(PARTNER)).state).toBe("DONE");
  await expect(page.locator("textarea")).toHaveValue(/^partner-taps from=0: \d+,\d+$/);
  await expect(page.getByRole("button", { name: "Copy" })).toBeVisible();
  await game.screenshot("partner-recorded");
});

test.describe("the ending", () => {
  // Starts the song 8 s before its last note (see web_test_probe.gd), so the
  // light fills the screen and the test appears without playing all 3:04.
  // With every streak moment already shown, for the screenshots.
  test.beforeEach(async ({ game }) => openPartner(game, "&partner_from=163&partner_moments=12"));

  test("the test appears, holds, then a tap goes back to the menu", async ({ game }) => {
    // Headless Chromium draws phone sizes at a few frames a second, and Godot
    // counts at most 8/60 s a frame, so the 30 s hold takes longer here.
    test.setTimeout(300_000);
    await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
    await game.tapMiddle();
    await expect.poll(() => songTime(game)).toBeGreaterThan(163);
    await game.screenshot("partner-crescendo");
    expect((await game.screen(PARTNER)).moments, "every streak moment shown").toBe(12);
    await expect
      .poll(async () => (await game.screen(PARTNER)).state, { timeout: 30_000 })
      .toBe("TEST_SHOWN");
    // Dan, 2026-10-20: "honey" from her, a jubilant "yes" from him, then they laugh.
    await expect
      .poll(async () => (await game.screen(PARTNER)).subtitle, { timeout: 60_000 })
      .toBe("Yes!");
    await game.screenshot("partner-ending");
    // Nothing to tap while it holds (Dan, 2026-10-19: at least 30 s).
    await game.tapMiddle();
    await game.page.waitForTimeout(500);
    expect((await game.screen(PARTNER)).state).toBe("TEST_SHOWN");
    await expect
      .poll(async () => (await game.screen(PARTNER)).can_leave, { timeout: 200_000 })
      .toBe(true);
    await game.screenshot("partner-ending-ring");
    await game.tapMiddle();
    await game.waitForScene(MENU);
  });
});
