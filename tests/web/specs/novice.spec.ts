// The Novice (DAS-133): it opens from the menu (until the medication box in
// the House can start it), starts quiet with no shout and no buttons, the
// Injection's two answers are buttons, a tap plays a micro-game, hiding the
// tab pauses it until a tap, and the positive test hands back to the menu
// with the chapter finished. Runs at laptop, phone and sideways-phone sizes.
// The whole six months (every game, no taps and every game won) are played
// by the Godot tests on the chapter's own clock (game/tests/test_novice.gd);
// feel is Dan's to check on his phone.
import { test, expect, MENU, NOVICE } from "./game";

const openNovice = async (game: any, query = "") => {
  await game.open(query);
  await game.tap("Tap to begin");
  await game.tap("The Novice (rough)");
  await game.waitForScene(MENU, [NOVICE]);
};

const novice = (game: any) => game.screen(NOVICE);

// Phone sizes draw a few frames a second here, so waits are long.
const SLOW = { timeout: 120_000 };

test("starts quiet, then Maya asks and Leo answers with a button", async ({ game }) => {
  test.setTimeout(240_000);
  await openNovice(game);
  const start = await novice(game);
  expect(start.beat).toBe("QUIET");
  expect(start.shout, "no shout yet").toBe("");
  expect((await game.state()).buttons, "nothing to press at first").toEqual([]);
  await game.screenshot("novice-quiet");
  await expect.poll(async () => (await novice(game)).beat, SLOW).toBe("TALK");
  await game.screenshot("novice-maya-asks");
  // Tapping moves her lines on, then the two answers come up.
  await expect.poll(async () => {
    const s = await novice(game);
    if (s.beat === "TALK") await game.tapMiddle();
    return s.beat;
  }, SLOW).toBe("CHOICE");
  await game.screenshot("novice-choice");
  await game.tap("I'm scared");
  await expect.poll(async () => (await novice(game)).answer, SLOW).toBe("vulnerable");
  await expect.poll(async () => (await novice(game)).beat, SLOW).toBe("GAMES");
});

test("a tap plays a micro-game, and hiding the tab pauses it", async ({ game, page }) => {
  test.setTimeout(240_000);
  await openNovice(game, "&novice_at=games");
  await expect.poll(async () => (await novice(game)).stage, SLOW).toBe("PLAY");
  const first = await novice(game);
  expect(first.shout).toBe("INJECT THE BUTT!");
  await game.screenshot("novice-inject");
  // The first game moves on whether or not the needle goes in; wait for the
  // box and open it with a tap.
  await expect.poll(async () => {
    const s = await novice(game);
    return s.game === "BOX" && s.stage === "PLAY";
  }, SLOW).toBe(true);
  await game.screenshot("novice-box");
  await game.tapMiddle();
  await expect.poll(async () => (await novice(game)).results[1], SLOW).toBe("won");
  // Hiding the tab pauses the chapter until the next tap.
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", { value: true, configurable: true });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await expect.poll(async () => (await novice(game)).paused, SLOW).toBe(true);
  const time = (await novice(game)).time;
  await page.waitForTimeout(1500);
  expect((await novice(game)).time, "the clock stops").toBe(time);
  await page.evaluate(() => {
    Object.defineProperty(document, "hidden", { value: false, configurable: true });
    document.dispatchEvent(new Event("visibilitychange"));
  });
  await game.tapMiddle();
  await expect.poll(async () => (await novice(game)).paused, SLOW).toBe(false);
  expect((await game.state()).progress.finished, "nothing saved mid-chapter").toEqual([]);
});

test("the positive test holds, then a tap goes back with the chapter finished", async ({ game }) => {
  test.setTimeout(240_000);
  await openNovice(game, "&finish=partner&finish=protector&novice_at=result");
  await expect.poll(async () => (await novice(game))?.beat, SLOW).toBe("RESULT");
  await game.screenshot("novice-test");
  await expect.poll(async () => (await novice(game)).canGoBack, SLOW).toBe(true);
  await game.tapMiddle();
  await game.waitForScene(MENU);
  await expect
    .poll(async () => (await game.state()).progress.finished.map((f: any) => f.chapter))
    .toEqual(["partner", "protector", "novice"]);
});
