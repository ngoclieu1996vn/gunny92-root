const fs = require('node:fs');
const zlib = require('node:zlib');
const [mode, input, output] = process.argv.slice(2);
if (!['pack', 'unpack'].includes(mode) || !input || !output) throw Error('Usage: item-catalog-zlib.cjs pack|unpack input output');
const bytes = fs.readFileSync(input);
let result;
if (mode === 'pack') {
  result = zlib.deflateSync(bytes);
  if (!zlib.inflateSync(result).equals(bytes)) throw Error('Zlib round trip failed');
} else {
  try { result = zlib.inflateSync(bytes); }
  catch (error) {
    if (!/^\s*\uFEFF?\s*</u.test(bytes.toString('utf8'))) throw error;
    result = bytes;
  }
}
fs.writeFileSync(output, result);
