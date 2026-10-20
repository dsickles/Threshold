// The chapter runner (DAS-75): the menu stands in for the House. Tapping the
// stand-in chapter hides the menu and gives the chapter the screen; finishing
// or leaving brings the menu back. Runs at laptop, phone and sideways-phone sizes.
import { test, expect, MENU } from "./game";

const texts = async (game: any): Promise<string[]> =>
  ((await game.state())?.buttons ?? []).map((b: { text: string }) => b.text);

test.beforeEach(async ({ game }) => {
  await game.open();
  await game.tap("Tap to begin");
});

for (const finish of ["Finish", "Finish: stoic", "Finish: vulnerable"]) {
  test(`stand-in chapter: "${finish}" returns to the menu`, async ({ game }) => {
    await game.tap("Stand-in chapter");
    await game.findButton("Finish: vulnerable");
    // The menu (the House) is hidden while the chapter plays.
    expect(await texts(game)).not.toContain("Smoothness");
    await game.screenshot("stand-in-chapter");
    await game.tap(finish);
    await game.findButton("Smoothness");
    await game.waitForScene(MENU);
    expect(await texts(game)).not.toContain("Finish");
    await game.screenshot("menu-after-chapter");
  });
}

test("stand-in chapter: leaving returns to the menu", async ({ game }) => {
  await game.tap("Stand-in chapter");
  await game.tap("Leave without finishing");
  await game.findButton("Smoothness");
  expect(await texts(game)).not.toContain("Leave without finishing");
  // It can be entered again afterwards.
  await game.tap("Stand-in chapter");
  await game.findButton("Finish");
});
