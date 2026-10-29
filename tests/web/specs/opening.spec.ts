// The opening flow (DAS-95): the game opens on "Tap to begin", with no sound
// before that first tap, then the porch. An upright phone gets the "Turn your
// phone sideways" screen. The opening beat plays at the living room and opens
// the hall; the record player's close-up, then a tap, starts the Partner.
// The M0 test menu is still there for tests ("?probe&menu"). Runs at laptop, phone
// and sideways-phone sizes; every console error fails the test.
import { test, expect, MENU, HOUSE, PARTNER, houseState, houseUntil, goTo, useObject } from "./game";

test("the game loads to Tap to begin, sound starts only after the first tap, then the porch", async ({ game }) => {
  test.setTimeout(240_000);
  await game.openGame();
  if (game.upright()) {
    // A phone held upright: the game waits behind the screen.
    await expect.poll(async () => (await game.state())?.turnSideways).toBe(true);
    await game.screenshot("turn-your-phone-sideways");
    await game.turnSideways();
  }
  await expect.poll(async () => (await game.state())?.turnSideways).toBe(false);
  await game.findButton("Tap to begin");
  await game.screenshot("game-tap-to-begin");
  await expect.poll(() => game.audioStates()).not.toEqual([]);
  expect(await game.audioStates(), "no sound before the first tap").not.toContain("running");
  expect(await game.resumesBeforeTap(), "nothing tries to start sound before the first tap").toBe(0);
  await game.tap("Tap to begin");
  await game.waitForScene(HOUSE);
  await expect.poll(() => game.audioStates()).toContain("running");
  await houseUntil(game, (s) => s.view === "P", "on the porch");
  expect((await houseState(game)).point).toBe("start");
  await game.screenshot("game-porch");
});

test("turning an upright phone sideways carries on where it was", async ({ game }) => {
  test.setTimeout(240_000);
  await game.begin();
  await houseUntil(game, (s) => s.view === "P", "on the porch");
  const { width, height } = game.page.viewportSize()!;
  // Held upright (any touch screen size), then sideways again.
  await game.page.setViewportSize({ width: Math.min(width, height), height: Math.max(width, height) });
  const touch = await game.page.evaluate(() => "ontouchstart" in window || navigator.maxTouchPoints > 0);
  await expect.poll(async () => (await game.state())?.turnSideways).toBe(touch);
  await game.page.setViewportSize({ width: Math.max(width, height), height: Math.min(width, height) });
  await expect.poll(async () => (await game.state())?.turnSideways).toBe(false);
  await game.waitForScene(HOUSE);
  await houseUntil(game, (s) => s.view === "P", "still on the porch");
});

test("the test menu is still reachable for tests", async ({ game }) => {
  await game.open();
  await game.tap("Tap to begin");
  await game.findButton("Smoothness");
  await game.waitForScene(MENU);
  expect((await game.state())?.turnSideways, "the menu is never covered").toBe(false);
});

test("the opening beat plays in the living room and the hall opens", async ({ game }) => {
  test.setTimeout(400_000);
  // Phone sizes draw the House a few frames a second here, so the lines play
  // faster ("&beat_speed=6"); how long each stays is checked headless.
  await game.begin("&glide=0.2&beat_speed=6");
  await goTo(game, "E1");
  await goTo(game, "L1");
  await houseUntil(game, (s) => s.beat?.choosing === true, "Leo's line to choose");
  expect((await houseState(game)).beat?.said, "Maya's first two lines").toEqual([
    "Maya: Did you lock the front door?",
    "Maya: Leo… are we really doing this? The house. All of it.",
  ]);
  await game.screenshot("opening-beat-choice");
  await game.tap("Honestly? I'm a little scared. The good kind.");
  await houseUntil(game, (s) => s.point === "after_opening", "the House after the opening beat");
  expect((await houseState(game)).rings.map((r) => r.target), "a ring into the hall").toContain("H1");
  expect((await game.state())?.progress.finished, "nothing saved yet").toEqual([]);
  await game.screenshot("opening-beat-hall-open");
});

// Also the Partner under the "Turn your phone sideways" screen ("&touch"
// shows it at the laptop size too): a tap on that screen must not start the
// song again, and once the phone is sideways a tap carries on from the same
// place in the song. Read from the song's own clock in the page.
test("the record player's close-up, then a tap, starts the Partner, which holds still while upright", async ({ game }) => {
  test.setTimeout(400_000);
  await game.begin("&opening=stoic&glide=0.2&touch");
  await houseUntil(game, (s) => s.view === "L1" && s.point === "after_opening", "in the living room");
  for (const view of ["H1", "B1", "B3"]) {
    await goTo(game, view);
  }
  await useObject(game, "record_player");
  await game.waitForScene(HOUSE, [PARTNER]);
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("WAITING");
  await game.screenshot("partner-from-the-record-player");

  const song = () => game.page.evaluate(() => (window as any).partnerConductor.songTime() as number);
  const paused = () => game.page.evaluate(() => (window as any).partnerConductor.paused() as boolean);
  await game.tapMiddle();
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("PLAYING");
  await expect.poll(song, { timeout: 60_000 }).toBeGreaterThan(2);
  const { width, height } = game.page.viewportSize()!;
  await game.holdUpright();
  await expect.poll(async () => (await game.state())?.turnSideways).toBe(true);
  expect(await paused(), "the song pauses under the screen").toBe(true);
  const frozen = await song();
  await game.tapMiddle();
  await game.page.waitForTimeout(1500);
  expect(await paused(), "a tap on the screen doesn't start it again").toBe(true);
  expect(await song(), "the song's clock stays still").toBeCloseTo(frozen, 1);
  await game.page.setViewportSize({ width: Math.max(width, height), height: Math.min(width, height) });
  await expect.poll(async () => (await game.state())?.turnSideways).toBe(false);
  expect(await paused(), "sideways again, it waits for a tap").toBe(true);
  const tappedAt = Date.now();
  await game.tapMiddle();
  await expect.poll(async () => (await game.screen(PARTNER))?.state).toBe("PLAYING");
  await expect.poll(song).toBeGreaterThan(frozen + 0.2);
  // It carries on from where it paused: on only by the time since the tap.
  const sinceTap = (Date.now() - tappedAt) / 1000;
  expect(await song()).toBeLessThanOrEqual(frozen + sinceTap + 0.3);
});
