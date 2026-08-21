"use strict";

import { WEDGES, FIXTURES, wedge } from "./profiles.js";

const params = new URLSearchParams(window.location.search);
const scanBox = () => document.getElementById("whaRfScan");

async function load(name) {
    const response = await fetch("/tools/rf-bench/fixtures/" + name + ".json", { cache: "no-store" });
    if (!response.ok) {
        throw new Error("No such state document: " + name);
    }
    const document_ = await response.text();
    window.Render(document_);
    return JSON.parse(document_);
}

function type(text, options) {
    const profile = typeof options === "string" ? wedge(options) : options || wedge("fast-enter");
    const box = scanBox();
    if (!box) {
        throw new Error("The add-in has not drawn a scan box");
    }

    box.focus();
    const characters = String(text).split("");
    let index = 0;

    return new Promise((resolve) => {
        const next = () => {
            if (index < characters.length) {
                box.value += characters[index];
                index += 1;
                window.setTimeout(next, profile.charDelayMs);
                return;
            }
            if (profile.suffix) {
                box.dispatchEvent(new KeyboardEvent("keydown", {
                    key: profile.suffix,
                    keyCode: profile.suffix === "Enter" ? 13 : 9,
                    bubbles: true,
                    cancelable: true
                }));
            }
            resolve();
        };
        next();
    });
}

window.whaBench = {
    load,
    type,
    events: () => window.whaBenchEvents.slice(),
    clear: () => { window.whaBenchEvents.length = 0; },
    focusScan: () => window.FocusScan()
};

function fillSelect(select, values) {
    values.forEach((value) => {
        const option = document.createElement("option");
        option.value = typeof value === "string" ? value : value.id;
        option.textContent = typeof value === "string" ? value : value.label;
        select.appendChild(option);
    });
}

function wireControls() {
    const controls = document.getElementById("benchControls");
    controls.hidden = false;

    const fixtures = document.getElementById("benchFixture");
    const wedges = document.getElementById("benchWedge");
    const log = document.getElementById("benchLog");

    fillSelect(fixtures, FIXTURES);
    fillSelect(wedges, WEDGES);

    fixtures.value = params.get("fixture") || "sign-in";
    fixtures.addEventListener("change", () => load(fixtures.value));

    document.getElementById("benchSend").addEventListener("click", () => {
        type(document.getElementById("benchWedgeText").value, wedge(wedges.value));
    });
    document.getElementById("benchFocus").addEventListener("click", () => window.FocusScan());
    document.getElementById("benchClear").addEventListener("click", () => {
        window.whaBenchEvents.length = 0;
        log.innerHTML = "";
    });

    window.addEventListener("wha-bench-event", (e) => {
        const entry = document.createElement("li");
        entry.textContent = e.detail.name + (e.detail.args.length ? " " + JSON.stringify(e.detail.args) : "");
        log.appendChild(entry);
        log.scrollTop = log.scrollHeight;
    });
}

if (params.get("controls") === "1") {
    wireControls();
}

load(params.get("fixture") || "sign-in").then(() => {
    window.whaBenchReady = true;
});
