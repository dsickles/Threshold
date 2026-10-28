// Shared helpers for the browser tests. The game draws everything on one
// canvas, so the tests read what is on screen from the test probe
// (game/_core/test_probe/web_test_probe.gd), which only runs with "?probe".
import { test as base, expect, Page } from "@playwright/test";

export type ProbeButton = { text: string; x: number; y: number; disabled: boolean };
export type ProbeState = {
  scene: string;
  overlays: string[];
  size: { x: number; y: number };
  buttons: ProbeButton[];
  // probe_state() of screens that report one, by scene path.
  screens: Record<string, any>;
  progress: { finished: { chapter: string; answer: string }[]; saveOk: boolean };
};

export const MENU = "res://scenes/ui/m0_menu.tscn";
export const SMOOTHNESS = "res://scenes/m0_checks/smoothness/smoothness_check.tscn";
export const VIEWPOINTS = "res://scenes/m0_checks/viewpoints_check.tscn";
export const UI_STYLE = "res://scenes/m0_checks/ui_style_check.tscn";
export const RHYTHM = "res://scenes/ui/m0_rhythm_check.tscn";
export const PARTNER = "res://scenes/chapters/partner/partner.tscn";
export const PROTECTOR = "res://scenes/chapters/protector/protector.tscn";
export const HOUSE = "res://scenes/house/house.tscn";

// Every console error or uncaught page error fails the test that caused it.
export const test = base.extend<{ game: Game }>({
  game: async ({ page, hasTouch }, use) => {
    const errors: string[] = [];
    page.on("console", (msg) => {
      if (msg.type() === "error") errors.push(msg.text());
    });
    page.on("pageerror", (err) => errors.push(err.message));
    // Headless Chromium lets sound play before any tap, even when told not
    // to. Phones don't, so this applies the phone rule: audio contexts start
    // paused and only resume once the player has tapped. It also keeps a list
    // of them, so a test can see whether sound is on.
    await page.addInitScript(() => {
      const w = window as any;
      w.__audioContexts = [];
      const Real = w.AudioContext || w.webkitAudioContext;
      if (!Real) return;
      // Tracked here because Playwright's page load already counts as a
      // tap to Chromium (navigator.userActivation).
      let tappedYet = false;
      for (const type of ["pointerdown", "touchend", "click", "keydown"]) {
        window.addEventListener(type, (e) => (tappedYet ||= e.isTrusted), true);
      }
      const tapped = () => tappedYet;
      class PhoneRules extends Real {
        constructor(...args: any[]) {
          super(...args);
          w.__audioContexts.push(this);
          if (!tapped()) Real.prototype.suspend.call(this);
        }
        resume() {
          return tapped() ? super.resume() : Promise.resolve();
        }
      }
      w.AudioContext = PhoneRules;
      w.webkitAudioContext = PhoneRules;
    });
    await use(new Game(page, hasTouch));
    expect(errors, "console errors").toEqual([]);
  },
});
export { expect };

export class Game {
  constructor(
    readonly page: Page,
    readonly hasTouch: boolean,
  ) {}

  /**
   * Opens the game and waits until the engine is running its first scene.
   * `extra` adds to the address, for example "&finish=partner" (see the probe).
   */
  async open(extra = "") {
    await this.page.goto("/index.html?probe" + extra);
    await expect.poll(() => this.state().then((s) => s?.scene), { timeout: 90_000 }).toBe(MENU);
  }

  async state(): Promise<ProbeState | null> {
    const raw = await this.page.evaluate(() => (window as any).thresholdProbe ?? null);
    return raw ? JSON.parse(raw) : null;
  }

  async waitForScene(scene: string, overlays: string[] = []) {
    await expect
      .poll(() => this.state().then((s) => s && { scene: s.scene, overlays: s.overlays }))
      .toEqual({ scene, overlays });
  }

  /** Waits for a visible, enabled button whose text starts with `text`. */
  async findButton(text: string): Promise<ProbeButton> {
    let found: ProbeButton | undefined;
    await expect
      .poll(async () => {
        const s = await this.state();
        found = s?.buttons.find((b) => b.text.startsWith(text) && !b.disabled);
        return found !== undefined;
      }, { message: `button "${text}"` })
      .toBe(true);
    return found!;
  }

  /** Taps a button the way the player would: a touch on phones, a click otherwise. */
  async tap(text: string) {
    await this.tapButton(await this.findButton(text));
  }

  async tapButton(button: ProbeButton) {
    const { x, y } = await this.toPage(button);
    if (this.hasTouch) {
      await this.page.touchscreen.tap(x, y);
    } else {
      await this.page.mouse.click(x, y);
    }
  }

  /** Probe positions are in the game's screen units; the page works in CSS pixels. */
  async toPage(button: ProbeButton) {
    const { size } = (await this.state())!;
    return this.page.evaluate(
      ({ x, y, size }) => {
        const rect = document.querySelector("canvas")!.getBoundingClientRect();
        return {
          x: rect.left + (x * rect.width) / size.x,
          y: rect.top + (y * rect.height) / size.y,
        };
      },
      { x: button.x, y: button.y, size },
    );
  }

  /** What a screen with no buttons reports about itself (its probe_state()). */
  async screen(scene: string): Promise<any> {
    return (await this.state())?.screens?.[scene] ?? null;
  }

  /** Taps the middle of the screen, for screens where the whole screen is the tap target. */
  async tapMiddle() {
    const { size } = (await this.state())!;
    await this.tapButton({ text: "", x: size.x / 2, y: size.y / 2, disabled: false });
  }

  /** Taps a point given as fractions of the screen (0 to 1 across, 0 to 1 down). */
  async tapAt(across: number, down: number) {
    const { size } = (await this.state())!;
    await this.tapButton({ text: "", x: size.x * across, y: size.y * down, disabled: false });
  }

  async audioStates(): Promise<string[]> {
    return this.page.evaluate(() => (window as any).__audioContexts.map((c: AudioContext) => c.state));
  }

  /** Lets the scene draw a few frames, then saves a named screenshot (test-results/ and the report). */
  async screenshot(name: string) {
    await this.page.waitForTimeout(1000);
    const path = test.info().outputPath(`${name}.png`);
    await this.page.screenshot({ path });
    await test.info().attach(name, { path, contentType: "image/png" });
  }
}
