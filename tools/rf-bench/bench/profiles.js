"use strict";

export const WEDGES = [
    { id: "fast-enter", label: "Fast, Enter suffix", charDelayMs: 0, suffix: "Enter" },
    { id: "slow-enter", label: "Slow, Enter suffix", charDelayMs: 15, suffix: "Enter" },
    { id: "very-slow-enter", label: "Very slow, Enter suffix", charDelayMs: 45, suffix: "Enter" },
    { id: "tab-suffix", label: "Tab suffix", charDelayMs: 0, suffix: "Tab" },
    { id: "no-suffix", label: "No suffix", charDelayMs: 0, suffix: null }
];

export const SCREENS = [
    { id: "very-narrow", label: "Very narrow (320x568)", width: 320, height: 568, scale: 2 },
    { id: "narrow-rugged", label: "Narrow rugged (480x800)", width: 480, height: 800, scale: 1.5 },
    { id: "mid-touch", label: "Mid touch (720x1280)", width: 720, height: 1280, scale: 2 },
    { id: "desk", label: "Desk browser (1280x800)", width: 1280, height: 800, scale: 1 }
];

export const FIXTURES = [
    "sign-in",
    "get-work",
    "scan-from",
    "scan-unit",
    "scan-to",
    "confirm",
    "short-pick",
    "simulator-scan-from",
    "hostile-text",
    "labels-without-simulator"
];

export function wedge(id) {
    const found = WEDGES.find((w) => w.id === id);
    if (!found) {
        throw new Error("Unknown wedge profile: " + id);
    }
    return found;
}

export function screen(id) {
    const found = SCREENS.find((s) => s.id === id);
    if (!found) {
        throw new Error("Unknown screen profile: " + id);
    }
    return found;
}
