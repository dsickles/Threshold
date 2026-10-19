// Progress and saves (DAS-74, ADR-0007): a finished chapter is saved in the
// browser and is still there after the page is reloaded. The probe's
// "&finish=" records a chapter as finished, so no chapter has to be played.
// Runs at laptop, phone and sideways-phone sizes.
import { test, expect, Game } from "./game";

/**
 * The save file as Godot stored it in the browser's lasting storage
 * (IndexedDB), or null if it isn't there yet.
 */
async function storedSave(game: Game): Promise<string | null> {
  return game.page.evaluate(async () => {
    const ask = <T>(req: IDBRequest<T>) =>
      new Promise<T>((ok, fail) => {
        req.onsuccess = () => ok(req.result);
        req.onerror = () => fail(req.error);
      });
    for (const { name } of await indexedDB.databases()) {
      if (!name) continue;
      const db = await ask(indexedDB.open(name));
      try {
        for (const store of Array.from(db.objectStoreNames)) {
          const files = db.transaction(store).objectStore(store);
          const key = (await ask(files.getAllKeys())).find((k) => String(k).endsWith("/save.json"));
          if (key === undefined) continue;
          const file: any = await ask(files.get(key));
          return file?.contents ? new TextDecoder().decode(file.contents) : null;
        }
      } finally {
        db.close();
      }
    }
    return null;
  });
}

async function finished(game: Game) {
  return (await game.state())?.progress.finished;
}

test("a new player starts with nothing finished", async ({ game }) => {
  await game.open();
  expect(await finished(game)).toEqual([]);
  expect(await storedSave(game)).toBeNull();
});

test("a finished chapter survives a page reload", async ({ game }) => {
  await game.open("&finish=partner:vulnerable");
  await expect.poll(() => finished(game)).toEqual([{ chapter: "partner", answer: "vulnerable" }]);
  expect((await game.state())?.progress.saveOk).toBe(true);
  // Godot copies user:// into IndexedDB a moment after writing.
  await expect.poll(() => storedSave(game), { message: "save stored in IndexedDB" }).toContain('"partner"');

  await game.open();
  await expect.poll(() => finished(game)).toEqual([{ chapter: "partner", answer: "vulnerable" }]);
  await game.findButton("Tap to begin");
  await game.screenshot("after-reload");
});

test("the next chapter is added after the saved ones", async ({ game }) => {
  await game.open("&finish=partner");
  await expect.poll(() => storedSave(game)).toContain('"partner"');
  await game.open("&finish=protector");
  await expect.poll(() => finished(game)).toEqual([
    { chapter: "partner", answer: "" },
    { chapter: "protector", answer: "" },
  ]);
  await expect.poll(() => storedSave(game)).toContain('"protector"');
  await game.open();
  await expect.poll(() => finished(game)).toEqual([
    { chapter: "partner", answer: "" },
    { chapter: "protector", answer: "" },
  ]);
});
