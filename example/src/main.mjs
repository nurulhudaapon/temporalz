import { readFile } from 'fs/promises';

let memory = null;

const buffer = await readFile('zig-out/bin/temporalz.wasm');
const temporalz = await WebAssembly.instantiate(buffer, {
    env: {
        console(ptr, len) {
            const bytes = new Uint8Array(memory.buffer, ptr, len);
            const message = new TextDecoder().decode(bytes);
            console.log(message);
        },
    },
});

memory = temporalz.instance.exports.memory;
temporalz.instance.exports._start();
