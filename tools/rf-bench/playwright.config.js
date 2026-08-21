import { defineConfig, devices } from "@playwright/test";

const PORT = 8730;

export default defineConfig({
    testDir: "./tests",
    fullyParallel: true,
    forbidOnly: !!process.env.CI,
    retries: 0,
    reporter: process.env.CI ? [["github"], ["html", { open: "never" }]] : [["list"]],
    use: {
        baseURL: "http://127.0.0.1:" + PORT,
        trace: "retain-on-failure"
    },
    projects: [
        { name: "chromium", use: { ...devices["Desktop Chrome"] } }
    ],
    webServer: {
        command: "node serve.mjs --port " + PORT,
        url: "http://127.0.0.1:" + PORT + "/tools/rf-bench/fixtures/sign-in.json",
        reuseExistingServer: !process.env.CI,
        stdout: "ignore"
    }
});
