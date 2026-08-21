"use strict";

window.whaBenchEvents = [];

window.Microsoft = window.Microsoft || {};
window.Microsoft.Dynamics = window.Microsoft.Dynamics || {};
window.Microsoft.Dynamics.NAV = window.Microsoft.Dynamics.NAV || {
    InvokeExtensibilityMethod: function (name, args) {
        window.whaBenchEvents.push({ name: name, args: (args || []).slice() });
        window.dispatchEvent(new CustomEvent("wha-bench-event", { detail: { name: name, args: args || [] } }));
    }
};
