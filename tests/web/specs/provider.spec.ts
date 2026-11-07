// The Provider's desk (DAS-134): it opens from the menu (until the bills on
// the office desk in the House can start it), with no console errors, at
// laptop, phone and sideways-phone sizes; a bill can be read in large type
// and stamped; and hiding the tab pauses the Due Date.
// The whole desk (every bill, the Due Date running out, the bill for the
// night of the Loss) is played by the Godot tests instead
// (game/tests/test_provider.gd). How the bills read and the stamps feel on
// a phone are Dan's to check.
import { test, expect, MENU, PROVIDER } from "./game";

const openDesk = async (game: any) => {
  await game.open();
  await game.tap("Tap to begin");
  await game.tap("The Provider (rough)");
  await game.waitForScene(MENU, [PROVIDER]);
};

const desk = (game: any) => game.screen(PROVIDER);

test("opens on the first bill with the Due Date and Bank Account", async ({ game }) => {
  await openDesk(game);
  await expect.poll(async () => (await desk(game))?.act).toBe("The Invoices");
  const state = await desk(game);
  expect(state.bill, "the first bill").toBe(0);
  expect(state.due, "Due Date").toMatch(/^\d+ days$/);
  expect(state.bank, "Bank Account").toMatch(/^\$[\d,]+$/);
  await game.findButton("APPROVE");
  await game.findButton("DENY");
  await game.screenshot("provider-desk");
});

test("a bill opens in large type, goes back, and takes a stamp", async ({ game }) => {
  await openDesk(game);
  await expect.poll(async () => (await desk(game))?.paper?.visible).toBe(true);
  const paper = (await desk(game)).paper;
  await game.tapButton({ text: "", x: paper.x, y: paper.y, disabled: false });
  await expect.poll(async () => (await desk(game)).reading).toBe(true);
  await game.screenshot("provider-large-type");
  await game.tap("Back to desk");
  await expect.poll(async () => (await desk(game)).reading).toBe(false);
  await game.tap("APPROVE");
  await expect.poll(async () => (await desk(game)).mark).toBe("APPROVED");
  await game.screenshot("provider-stamped");
  await expect.poll(async () => (await desk(game)).bill, { timeout: 30_000 }).toBe(1);
});

test("hiding the tab pauses the Due Date", async ({ game, page }) => {
  await openDesk(game);
  await expect.poll(async () => (await desk(game))?.time ?? 0).toBeGreaterThan(0.5);
  const hide = (hidden: boolean) =>
    page.evaluate((hidden: boolean) => {
      Object.defineProperty(document, "hidden", { value: hidden, configurable: true });
      Object.defineProperty(document, "visibilityState", {
        value: hidden ? "hidden" : "visible",
        configurable: true,
      });
      document.dispatchEvent(new Event("visibilitychange"));
    }, hidden);
  await hide(true);
  await expect.poll(async () => (await desk(game)).paused).toBe(true);
  const at = (await desk(game)).time;
  await page.waitForTimeout(1500);
  expect((await desk(game)).time, "the desk's clock waits").toBe(at);
  await hide(false);
  await expect.poll(async () => (await desk(game)).time).toBeGreaterThan(at);
});
