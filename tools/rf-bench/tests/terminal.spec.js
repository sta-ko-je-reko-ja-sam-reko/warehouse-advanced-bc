import { expect, test } from "@playwright/test";
import { FIXTURES, SCREENS, WEDGES } from "../bench/profiles.js";

const SCAN = "#whaRfScan";

async function open(page, fixture) {
    const failures = [];
    page.on("pageerror", (error) => failures.push(String(error)));
    await page.goto("/tools/rf-bench/bench/index.html?fixture=" + fixture);
    await page.waitForFunction(() => window.whaBenchReady === true);
    await page.evaluate(() => window.whaBench.clear());
    return failures;
}

const events = (page) => page.evaluate(() => window.whaBench.events());
const names = async (page) => (await events(page)).map((e) => e.name);

test.describe("drawing", () => {
    for (const fixture of FIXTURES) {
        test("draws the " + fixture + " state without erroring", async ({ page }) => {
            const failures = await open(page, fixture);
            await expect(page.locator(".wha-rf-instruction")).not.toBeEmpty();
            await expect(page.locator(".wha-rf-key-primary")).not.toBeEmpty();
            expect(failures).toEqual([]);
        });
    }

    test("raises Ready once the add-in has drawn itself", async ({ page }) => {
        await page.goto("/tools/rf-bench/bench/index.html?fixture=sign-in");
        await page.waitForFunction(() => window.whaBenchReady === true);
        expect((await events(page)).map((e) => e.name)).toContain("Ready");
    });

    test("shows the job and picks out the line to act on", async ({ page }) => {
        await open(page, "scan-from");
        await expect(page.locator('.wha-rf-job-row[data-name="From"] dd')).toHaveClass("wha-rf-target");
        await expect(page.locator('.wha-rf-job-row[data-name="To"] dd')).not.toHaveClass("wha-rf-target");
        await expect(page.locator(".wha-rf-job-no")).toHaveText("WT000042");
    });

    test("hides the scan box when no scan is wanted", async ({ page }) => {
        await open(page, "get-work");
        await expect(page.locator(".wha-rf-scanbox")).toHaveClass(/wha-rf-hidden/);
    });
});

test.describe("the wedge", () => {
    for (const profile of WEDGES) {
        test("a " + profile.label + " wedge is read as " + (profile.suffix === "Enter" ? "a scan" : "nothing"),
            async ({ page }) => {
                await open(page, "scan-from");
                await page.locator(SCAN).focus();
                await page.keyboard.type("B-01-0001", { delay: profile.charDelayMs });
                if (profile.suffix) {
                    await page.keyboard.press(profile.suffix);
                }
                await page.waitForTimeout(120);

                const raised = await events(page);
                if (profile.suffix === "Enter") {
                    expect(raised).toEqual([{ name: "Scanned", args: ["B-01-0001"] }]);
                    await expect(page.locator(SCAN)).toHaveValue("");
                } else {
                    expect(raised).toEqual([]);
                    await expect(page.locator(SCAN)).toHaveValue("B-01-0001");
                }
            });
    }

    test("a scan arrives whole even when the characters arrive fastest", async ({ page }) => {
        await open(page, "scan-unit");
        await page.locator(SCAN).focus();
        await page.keyboard.type("HU000042", { delay: 0 });
        await page.keyboard.press("Enter");
        expect(await events(page)).toEqual([{ name: "Scanned", args: ["HU000042"] }]);
    });

    test("an empty Enter raises nothing", async ({ page }) => {
        await open(page, "scan-from");
        await page.locator(SCAN).focus();
        await page.keyboard.press("Enter");
        expect(await events(page)).toEqual([]);
    });
});

test.describe("focus", () => {
    test("the scan box has the focus as soon as a scan is wanted", async ({ page }) => {
        await open(page, "scan-from");
        await expect(page.locator(SCAN)).toBeFocused();
    });

    test("focus comes back when something takes it away", async ({ page }) => {
        await open(page, "scan-from");
        await page.locator(".wha-rf-key-primary").focus();
        await expect(page.locator(SCAN)).toBeFocused({ timeout: 2000 });
    });

    test("focus is left alone when no scan is wanted", async ({ page }) => {
        await open(page, "get-work");
        await page.locator(".wha-rf-key-primary").focus();
        await page.waitForTimeout(300);
        await expect(page.locator(".wha-rf-key-primary")).toBeFocused();
    });

    test("the scan box does not ask for an on-screen keyboard", async ({ page }) => {
        await open(page, "scan-from");
        await expect(page.locator(SCAN)).toHaveAttribute("inputmode", "none");
    });
});

test.describe("the keys", () => {
    test("the primary key signs in with what was typed", async ({ page }) => {
        await open(page, "sign-in");
        await page.locator(SCAN).fill("RF-01");
        await page.locator(".wha-rf-key-primary").click();
        expect(await events(page)).toEqual([{ name: "Scanned", args: ["RF-01"] }]);
    });

    test("the primary key asks for work at the get-work step", async ({ page }) => {
        await open(page, "get-work");
        await page.locator(".wha-rf-key-primary").click();
        expect(await names(page)).toEqual(["NextTaskRequested"]);
    });

    test("the primary key confirms while a job is held", async ({ page }) => {
        await open(page, "confirm");
        await page.locator(".wha-rf-key-primary").click();
        expect(await names(page)).toEqual(["ConfirmRequested"]);
    });

    test("report short and hand back raise their own events", async ({ page }) => {
        await open(page, "scan-from");
        await page.locator('[data-el="short"]').click();
        await page.locator('[data-el="handback"]').click();
        expect(await names(page)).toEqual(["ShortPickRequested", "HandBackRequested"]);
    });

    test("nothing can be handed back or reported short without a job", async ({ page }) => {
        await open(page, "get-work");
        await expect(page.locator('[data-el="short"]')).toBeDisabled();
        await expect(page.locator('[data-el="handback"]')).toBeDisabled();
    });

    test("the primary key is dead while the short form is open", async ({ page }) => {
        await open(page, "short-pick");
        await expect(page.locator(".wha-rf-key-primary")).toBeDisabled();
        await expect(page.locator('[data-el="short"]')).toBeDisabled();
        await expect(page.locator('[data-el="handback"]')).toBeEnabled();
    });
});

test.describe("labels", () => {
    test("the simulator offers the labels within reach, wanted one not first", async ({ page }) => {
        await open(page, "simulator-scan-from");
        const buttons = page.locator(".wha-rf-barcode");
        await expect(buttons).toHaveCount(4);
        await expect(buttons.first()).not.toHaveText("B-01-0001");
        await buttons.nth(1).click();
        expect(await events(page)).toEqual([{ name: "Scanned", args: ["B-01-0001"] }]);
    });

    test("no labels are drawn off the simulator, even when the document carries them", async ({ page }) => {
        await open(page, "labels-without-simulator");
        await expect(page.locator(".wha-rf-barcode")).toHaveCount(0);
        await expect(page.locator(".wha-rf-labels")).toHaveClass(/wha-rf-hidden/);
    });
});

test.describe("hostile text", () => {
    test("markup in a state document is shown, not run", async ({ page }) => {
        await open(page, "hostile-text");
        expect(await page.evaluate(() => window.whaPwned)).toBeUndefined();
        await expect(page.locator("#controlAddIn img")).toHaveCount(0);
        await expect(page.locator("#controlAddIn script")).toHaveCount(0);
        await expect(page.locator('.wha-rf-job-row[data-name="Item"] dd'))
            .toHaveText("<script>window.whaPwned=1</script>");
    });
});

test.describe("screens", () => {
    for (const profile of SCREENS) {
        test("fits a " + profile.label + " screen", async ({ page }) => {
            await page.setViewportSize({ width: profile.width, height: profile.height });
            await open(page, "scan-from");

            const overflow = await page.evaluate(() =>
                document.documentElement.scrollWidth - document.documentElement.clientWidth);
            expect(overflow).toBeLessThanOrEqual(1);

            const key = await page.locator(".wha-rf-key-primary").boundingBox();
            expect(key.height).toBeGreaterThanOrEqual(44);

            const instruction = await page.evaluate(() =>
                parseFloat(getComputedStyle(document.querySelector(".wha-rf-instruction")).fontSize));
            expect(instruction).toBeGreaterThanOrEqual(18);
        });
    }
});
