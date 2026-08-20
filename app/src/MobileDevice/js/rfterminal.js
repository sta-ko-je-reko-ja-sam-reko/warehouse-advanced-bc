"use strict";

var WHARFTerminal = (function () {
    var root = null;
    var el = {};
    var state = null;

    function raise(name, args) {
        Microsoft.Dynamics.NAV.InvokeExtensibilityMethod(name, args || []);
    }

    function build() {
        root = document.getElementById("controlAddIn");
        if (!root) {
            return false;
        }

        root.innerHTML = "";
        root.className = "wha-rf";

        var shell = document.createElement("div");
        shell.className = "wha-rf-shell";

        var screen = document.createElement("div");
        screen.className = "wha-rf-screen";

        var status = document.createElement("div");
        status.className = "wha-rf-status";
        status.innerHTML =
            '<span>DEV <strong data-el="device">—</strong></span>' +
            '<span>LOC <strong data-el="location">—</strong></span>' +
            '<span data-el="step"></span>';

        var instruction = document.createElement("p");
        instruction.className = "wha-rf-instruction";
        instruction.setAttribute("data-el", "instruction");
        instruction.setAttribute("aria-live", "assertive");

        var job = document.createElement("div");
        job.className = "wha-rf-job";
        job.setAttribute("data-el", "job");

        var scanBox = document.createElement("div");
        scanBox.className = "wha-rf-scanbox";
        scanBox.setAttribute("data-el", "scanbox");
        scanBox.innerHTML =
            '<label class="wha-rf-label" for="whaRfScan">Scan</label>' +
            '<input id="whaRfScan" class="wha-rf-scan" autocomplete="off" spellcheck="false" autocapitalize="characters">' +
            '<div class="wha-rf-labels" data-el="labels"></div>';

        var keys = document.createElement("div");
        keys.className = "wha-rf-keys";
        keys.innerHTML =
            '<button type="button" class="wha-rf-key wha-rf-key-primary" data-el="primary"></button>' +
            '<button type="button" class="wha-rf-key" data-el="short">Report short</button>' +
            '<button type="button" class="wha-rf-key" data-el="handback">Hand back</button>';

        screen.appendChild(status);
        screen.appendChild(instruction);
        screen.appendChild(job);
        screen.appendChild(scanBox);
        screen.appendChild(keys);
        shell.appendChild(screen);
        root.appendChild(shell);

        el.root = root;
        el.shell = shell;
        el.device = root.querySelector('[data-el="device"]');
        el.location = root.querySelector('[data-el="location"]');
        el.step = root.querySelector('[data-el="step"]');
        el.instruction = root.querySelector('[data-el="instruction"]');
        el.job = root.querySelector('[data-el="job"]');
        el.scanbox = root.querySelector('[data-el="scanbox"]');
        el.scan = root.querySelector("#whaRfScan");
        el.labels = root.querySelector('[data-el="labels"]');
        el.primary = root.querySelector('[data-el="primary"]');
        el.short = root.querySelector('[data-el="short"]');
        el.handback = root.querySelector('[data-el="handback"]');

        wire();
        return true;
    }

    function wire() {
        el.scan.addEventListener("keydown", function (e) {
            if (e.key === "Enter" || e.keyCode === 13) {
                e.preventDefault();
                submitScan();
            }
        });

        el.scan.addEventListener("blur", function () {
            window.setTimeout(function () {
                if (state && state.wantsScan && document.activeElement !== el.scan) {
                    el.scan.focus();
                }
            }, 60);
        });

        el.primary.addEventListener("click", function () {
            if (!state) {
                return;
            }
            if (state.step === "WHASignIn") {
                submitScan();
                return;
            }
            if (state.step === "WHAGetWork") {
                raise("NextTaskRequested");
                return;
            }
            raise("ConfirmRequested");
        });

        el.short.addEventListener("click", function () { raise("ShortPickRequested"); });
        el.handback.addEventListener("click", function () { raise("HandBackRequested"); });
    }

    function submitScan() {
        var value = el.scan.value;
        if (!value) {
            return;
        }
        el.scan.value = "";
        raise("Scanned", [value]);
    }

    function renderJob(job) {
        if (!job || !job.hasJob) {
            el.job.className = "wha-rf-job wha-rf-hidden";
            el.job.innerHTML = "";
            return;
        }

        el.job.className = "wha-rf-job";
        el.job.innerHTML =
            '<div class="wha-rf-job-head">' +
                '<span class="wha-rf-job-no"></span>' +
                '<span class="wha-rf-job-type"></span>' +
            '</div>' +
            '<dl class="wha-rf-job-rows">' +
                row("Item", job.item) +
                row("Quantity", job.quantity ? job.quantity + " " + (job.unitOfMeasure || "") : "—") +
                row("From", job.fromBin) +
                row("To", job.toBin) +
                row("Unit", job.handlingUnit) +
            "</dl>";

        el.job.querySelector(".wha-rf-job-no").textContent = job.number || "";
        el.job.querySelector(".wha-rf-job-type").textContent = job.type || "";
        highlightTarget();
    }

    function row(name, value) {
        return '<div class="wha-rf-job-row" data-name="' + name + '">' +
            "<dt>" + name + "</dt><dd>" + escapeHtml(value || "—") + "</dd></div>";
    }

    function escapeHtml(value) {
        return String(value).replace(/[&<>"']/g, function (c) {
            return { "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" }[c];
        });
    }

    function highlightTarget() {
        if (!state || !state.target) {
            return;
        }
        var rows = el.job.querySelectorAll(".wha-rf-job-row dd");
        var i;
        for (i = 0; i < rows.length; i += 1) {
            if (rows[i].textContent === state.target) {
                rows[i].className = "wha-rf-target";
            }
        }
    }

    function renderLabels(labels) {
        el.labels.innerHTML = "";
        if (!labels || !labels.length) {
            el.labels.className = "wha-rf-labels wha-rf-hidden";
            return;
        }

        el.labels.className = "wha-rf-labels";
        labels.forEach(function (code) {
            var button = document.createElement("button");
            button.type = "button";
            button.className = "wha-rf-barcode";
            button.textContent = code;
            button.addEventListener("click", function () {
                raise("Scanned", [code]);
            });
            el.labels.appendChild(button);
        });
    }

    return {
        render: function (stateJson) {
            if (!root && !build()) {
                return;
            }

            try {
                state = JSON.parse(stateJson);
            } catch (e) {
                return;
            }

            el.shell.className = state.simulator ? "wha-rf-shell wha-rf-simulator" : "wha-rf-shell";
            el.device.textContent = (state.device && state.device.code) || "—";
            el.location.textContent = (state.device && state.device.location) || "—";
            el.step.textContent = state.stepLabel || "";
            el.instruction.textContent = state.instruction || "";

            renderJob(state.job);

            el.scanbox.className = state.wantsScan ? "wha-rf-scanbox" : "wha-rf-scanbox wha-rf-hidden";
            renderLabels(state.simulator ? state.labels : null);

            el.primary.textContent = state.primaryKey || "";
            el.primary.disabled = state.primaryEnabled === false;
            el.short.disabled = !state.shortEnabled;
            el.handback.disabled = !state.handBackEnabled;

            if (state.wantsScan) {
                el.scan.focus();
            }
        },

        focusScan: function () {
            if (el.scan) {
                el.scan.focus();
            }
        },

        start: function () {
            if (build()) {
                raise("Ready");
            }
        }
    };
}());

function Render(stateJson) {
    WHARFTerminal.render(stateJson);
}

function FocusScan() {
    WHARFTerminal.focusScan();
}
