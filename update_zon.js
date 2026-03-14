const fs = require('fs');

const app_zon = fs.readFileSync('build.zig.zon', 'utf8');
function extractDep(name) {
    const regex = new RegExp(`\\.${name}\\s*=\\s*\\{([\\s\\S]*?)\\},`);
    return app_zon.match(regex)[0];
}

const p1 = extractDep('temporal_rs');
const p2 = extractDep('libtemporal_prebuilt');

const pkg_zon = fs.readFileSync('pkg/temporal-rs/build.zig.zon', 'utf8');
const new_pkg_zon = pkg_zon.replace('    .dependencies = .{', `    .dependencies = .{\n        ${p1}\n        ${p2}`);

fs.writeFileSync('pkg/temporal-rs/build.zig.zon', new_pkg_zon);
