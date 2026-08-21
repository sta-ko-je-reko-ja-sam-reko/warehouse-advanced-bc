import { readdir, readFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(HERE, "..", "..");
const SOURCE = join(ROOT, "app", "src", "MobileDevice", "codeunits", "RFTerminalState.Codeunit.al");
const FIXTURES = join(HERE, "fixtures");

const OBJECTS = [
    { holder: "StateObject", path: [] },
    { holder: "DeviceObjectValue", path: ["device"] },
    { holder: "JobObjectValue", path: ["job"] }
];

function keysAddedTo(source, holder) {
    const opener = holder + ".Add('";
    const found = [];
    let from = source.indexOf(opener);
    while (from !== -1) {
        const keyStart = from + opener.length;
        const keyEnd = source.indexOf("'", keyStart);
        if (keyEnd !== -1) {
            found.push(source.slice(keyStart, keyEnd));
        }
        from = source.indexOf(opener, keyStart);
    }
    return found;
}

function at(document_, path) {
    return path.reduce((node, key) => (node ?? {})[key], document_);
}

const source = await readFile(SOURCE, "utf-8");
const expected = OBJECTS.map((object) => ({ ...object, keys: keysAddedTo(source, object.holder) }));

if (expected.some((object) => object.keys.length === 0)) {
    console.error("Could not read the state document shape out of " + SOURCE);
    console.error("The AL changed shape in a way this check does not understand. Fix the check, do not skip it.");
    process.exit(2);
}

const names = (await readdir(FIXTURES)).filter((name) => name.endsWith(".json"));
const problems = [];

for (const name of names) {
    const document_ = JSON.parse(await readFile(join(FIXTURES, name), "utf-8"));
    for (const object of expected) {
        const node = at(document_, object.path);
        const where = object.path.length ? object.path.join(".") : "(root)";
        if (node === undefined || node === null) {
            problems.push(name + ": " + where + " is missing entirely");
            continue;
        }
        const present = Object.keys(node);
        for (const key of object.keys) {
            if (!present.includes(key)) {
                problems.push(name + ": " + where + " has no '" + key + "', but the AL adds one");
            }
        }
        for (const key of present) {
            if (!object.keys.includes(key)) {
                problems.push(name + ": " + where + " has '" + key + "', which the AL does not add");
            }
        }
    }
}

if (problems.length) {
    console.error("The fixtures no longer match WHA RF Terminal State:");
    problems.forEach((problem) => console.error("  " + problem));
    console.error("");
    console.error("Regenerate them from the AL before trusting anything this bench says.");
    process.exit(1);
}

console.log("Fixtures match the shape built by WHA RF Terminal State (" + names.length + " documents).");
