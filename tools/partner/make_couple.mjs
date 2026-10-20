// Renders the PLACEHOLDER couple silhouette (placeholder_couple.svg) to
// game/assets/images/partner/placeholder_couple.png with the browser tests'
// Chromium. Dev-only; the game uses the PNG.
//
//     cd tests/web && node ../../tools/partner/make_couple.mjs
import { createRequire } from "node:module";
import { readFileSync, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";

// Playwright is installed in tests/web, so load it from there.
const { chromium } = createRequire(path.join(process.cwd(), "package.json"))("@playwright/test");
const here = path.dirname(fileURLToPath(import.meta.url));
const svg = readFileSync(path.join(here, "placeholder_couple.svg"), "utf8");
const out = path.join(here, "../../game/assets/images/partner/placeholder_couple.png");
mkdirSync(path.dirname(out), { recursive: true });
const browser = await chromium.launch();
const page = await browser.newPage({ viewport: { width: 1000, height: 1000 } });
await page.setContent(`<body style="margin:0;background:transparent">${svg}</body>`);
await page.locator("svg").screenshot({ path: out, omitBackground: true });
await browser.close();
console.log("Wrote", out);
