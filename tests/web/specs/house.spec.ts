// The gray-box House (DAS-93): it opens from the test menu, starts on the
// porch, and tapping rings glides from view to view. Runs at laptop, phone
// and sideways-phone sizes; every console error fails the test.
import { test, expect, HOUSE, Game } from "./game";

type Ring = { target: string; x: number; y: number };
type HouseState = { view: string; gliding: boolean; rings: Ring[] };

const house = async (game: Game): Promise<HouseState> => game.screen(HOUSE);

// Taps the ring that leads to `target`, then waits for the glide to end there.
async function goTo(game: Game, target: string) {
  let ring: Ring | undefined;
  await expect
    .poll(async () => {
      const s = await house(game);
      ring = s && !s.gliding ? s.rings.find((r) => r.target === target) : undefined;
      return ring !== undefined;
    }, { message: `ring to ${target}` })
    .toBe(true);
  await game.tapButton({ text: "", x: ring!.x, y: ring!.y, disabled: false });
  // Software WebGL draws the 3D House slowly at phone pixel densities (a
  // frame can take seconds), so arriving gets longer than other waits.
  await expect
    .poll(async () => {
      const s = await house(game);
      return s && s.view === target && !s.gliding;
    }, { message: `arrive at ${target}`, timeout: 120_000 })
    .toBe(true);
}

test.beforeEach(async ({ game }) => {
  await game.open();
  await game.tap("Tap to begin");
});

// Every size: the House opens on the porch, and tapping the front door's
// ring (a touch on phones) glides into the entry.
test("the House opens on the porch and the front door leads in", async ({ game }) => {
  test.setTimeout(300_000);
  await game.tap("House: moving day");
  await game.waitForScene(HOUSE);
  await expect.poll(async () => (await house(game))?.view).toBe("P");
  const start = await house(game);
  expect(start.rings.map((r) => r.target)).toEqual(["E1"]);
  await game.screenshot("house-porch");
  await goTo(game, "E1");
  await game.screenshot("house-entry");
});

// The walk runs at laptop size only. In CI's software WebGL a single glide
// at phone pixel densities takes most of a minute, so seven of them at two
// phone sizes don't fit in the job's time. On the phone this walk is Dan's
// device test (porch to bedroom and back); the headless tests cover every
// ring and reachability at every size.
test("moving day blocks the hall; with it open, the bedroom and back", async ({ game }, testInfo) => {
  test.skip(testInfo.project.name !== "laptop", "laptop only: see the note above");
  test.setTimeout(300_000);
  await game.tap("House: moving day");
  await game.waitForScene(HOUSE);
  for (const view of ["E1", "L1"]) {
    await goTo(game, view);
  }
  // On moving day the back hall is blocked by boxes: no ring to it.
  expect((await house(game)).rings.map((r) => r.target)).not.toContain("H1");
  await game.screenshot("house-living-room-moving-day");
  await game.open();
  await game.tap("Tap to begin");
  await game.tap("House: hall open");
  await game.waitForScene(HOUSE);
  for (const view of ["E1", "L1", "H1", "B1", "B2"]) {
    await goTo(game, view);
  }
  await game.screenshot("house-bedroom");
  for (const view of ["H1", "L1"]) {
    await goTo(game, view);
  }
  await game.screenshot("house-back-in-the-living-room");
});
