import { defineConfig, devices } from "@playwright/test";

// Runs the exported web build (build/web/, made by tools/publish.sh) in
// Chromium at a laptop size and a phone size. See README.md.
export default defineConfig({
  testDir: "./specs",
  // One game at a time: each test boots the whole engine in software WebGL.
  workers: 1,
  timeout: 120_000,
  expect: { timeout: 30_000 },
  retries: 0,
  reporter: [["list"], ["html", { open: "never" }]],
  use: {
    baseURL: "http://localhost:8060",
    screenshot: "on",
    trace: "retain-on-failure",
    launchOptions: {
      args: [
        // Like a phone: no sound until the player taps.
        "--autoplay-policy=user-gesture-required",
        // Software WebGL, so the tests run on machines with no graphics card.
        "--use-angle=swiftshader",
        "--enable-unsafe-swiftshader",
      ],
    },
  },
  projects: [
    { name: "laptop", use: { ...devices["Desktop Chrome"], viewport: { width: 1280, height: 720 } } },
    // iPhone-sized screen with touch, in Chromium (Safari's engine is not
    // tested here; Dan's iPhone stays the real test).
    {
      name: "phone",
      use: {
        viewport: { width: 393, height: 852 },
        deviceScaleFactor: 3,
        isMobile: true,
        hasTouch: true,
      },
    },
    {
      name: "phone-sideways",
      use: {
        viewport: { width: 852, height: 393 },
        deviceScaleFactor: 3,
        isMobile: true,
        hasTouch: true,
      },
    },
  ],
  webServer: {
    command: "node serve.mjs",
    url: "http://localhost:8060/index.html",
    reuseExistingServer: !process.env.CI,
  },
});
