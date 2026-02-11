import runTest262 from "../temporal-test262-runner/index.mjs";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const wasmPath =
    process.env.TEMPORALZ_WASM ||
    path.resolve(__dirname, "../../zig-out/bin/temporalz.wasm");
const wasmBytes = fs.readFileSync(wasmPath);

const polyfillPath = path.resolve(__dirname, "../test262/polyfill.js");
let polyfillCode = fs.readFileSync(polyfillPath, "utf-8");

const bytesArray = JSON.stringify(Array.from(wasmBytes));
// TextEncoder/TextDecoder need to be manually constructed and passed via context
// Since we can't serialize them, we inject polyfill-compatible shim versions
const injection = `globalThis.__TEMPORALZ_WASM_BYTES__ = new Uint8Array(${bytesArray});
`;
polyfillCode = injection + polyfillCode;

const tempPolyfillPath = path.resolve(__dirname, "../test262/polyfill-injected.js");
fs.writeFileSync(tempPolyfillPath, polyfillCode);

const result = runTest262({
    test262Dir: "test/temporal-test262-runner/test262",
    polyfillCodeFile: tempPolyfillPath,
    testGlobs: process.argv.slice(2),
});

fs.unlinkSync(tempPolyfillPath);

process.exit(result ? 0 : 1);
