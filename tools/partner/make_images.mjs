// Renders the Partner's PLACEHOLDER pictures (tools/partner/placeholder_*.svg;
// the couple and the moments come from make_silhouettes.py) to PNGs in
// game/assets/images/partner/ with the browser tests' Chromium.
// Dev-only; the game uses the PNGs.
//
//     cd tests/web && node ../../tools/partner/make_images.mjs
import { createRequire } from "node:module";
import { readFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

// Playwright is installed in tests/web, so load it from there.
const { chromium } = createRequire(path.join(process.cwd(), "package.json"))("@playwright/test");
const here = path.dirname(fileURLToPath(import.meta.url));
const outDir = path.join(here, "../../game/assets/images/partner");
mkdirSync(outDir, { recursive: true });
const browser = await chromium.launch();
const pictures = [["couple", 800, 880], ["test", 1000, 240]];
for (let k = 1; k <= 12; k++) pictures.push([`moment_${String(k).padStart(2, "0")}`, 800, 720]);
for (const [name, width, height] of pictures) {
  const svg = readFileSync(path.join(here, `placeholder_${name}.svg`), "utf8");
  const page = await browser.newPage({ viewport: { width, height } });
  await page.setContent(`<body style="margin:0;background:transparent">${svg}</body>`);
  const out = path.join(outDir, `placeholder_${name}.png`);
  await page.locator("svg").screenshot({ path: out, omitBackground: true });
  await page.close();
  console.log("Wrote", out);
}
await browser.close();
