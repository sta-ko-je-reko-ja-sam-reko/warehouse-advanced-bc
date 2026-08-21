import { createServer } from "node:http";
import { readFile } from "node:fs/promises";
import { networkInterfaces } from "node:os";
import { extname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const HERE = fileURLToPath(new URL(".", import.meta.url));
const ROOT = resolve(HERE, "..", "..");

const TYPES = {
    ".html": "text/html; charset=utf-8",
    ".js": "text/javascript; charset=utf-8",
    ".mjs": "text/javascript; charset=utf-8",
    ".css": "text/css; charset=utf-8",
    ".json": "application/json; charset=utf-8",
    ".png": "image/png",
    ".svg": "image/svg+xml"
};

const args = process.argv.slice(2);
const port = Number(valueOf("--port") ?? 8730);
const lan = args.includes("--host");
const startPath = "/tools/rf-bench/bench/index.html?controls=1";

function valueOf(flag) {
    const at = args.indexOf(flag);
    return at === -1 ? undefined : args[at + 1];
}

const server = createServer(async (request, response) => {
    const path = decodeURIComponent(new URL(request.url, "http://localhost").pathname);
    const segments = path.split("/").filter((part) => part !== "" && part !== ".." && part !== ".");
    const target = resolve(ROOT, join(...segments));

    if (!target.startsWith(ROOT)) {
        response.writeHead(403).end("Outside the repository");
        return;
    }

    try {
        const body = await readFile(target);
        response.writeHead(200, {
            "Content-Type": TYPES[extname(target).toLowerCase()] ?? "application/octet-stream",
            "Cache-Control": "no-store"
        }).end(body);
    } catch {
        response.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" }).end("Not found: " + path);
    }
});

server.listen(port, lan ? "0.0.0.0" : "127.0.0.1", () => {
    console.log("Serving " + ROOT);
    console.log("  http://localhost:" + port + startPath);
    if (!lan) {
        return;
    }
    for (const addresses of Object.values(networkInterfaces())) {
        for (const address of addresses ?? []) {
            if (address.family === "IPv4" && !address.internal) {
                console.log("  http://" + address.address + ":" + port + startPath);
            }
        }
    }
    console.log("Open one of these on the handheld. Same Wi-Fi, and the firewall must allow the port.");
});
