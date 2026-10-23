const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../Gunny92/Resource.Server');
const input = process.argv[2];
if (!input) throw Error('Usage: node tools/Sync-ItemIcons.cjs icon-items.json [--apply]');
const items = JSON.parse(fs.readFileSync(input, 'utf8').replace(/^\uFEFF/u, ''));
const output = path.join(path.dirname(path.resolve(input)), 'icon-sync-report.json');
// PathManager.solveGoodsPath and EquipType.TYPES from the actual Flash client.
const types = ['', 'head', 'glass', 'hair', 'eff', 'cloth', 'face', 'arm', 'armlet', 'ring', '', '', '', 'suits', 'necklace'];
function icons(item) {
  const c = item.category, p = item.pic;
  if (!p || !/^[A-Za-z0-9_-]+$/.test(p)) return [];
  if ([7,27,64].includes(c)) return [`image/arm/${p}/1/icon.png`];
  if ([24,11,65,68,69,72,43,73,61,62,37,79,83,82,88,89,90,93,98,107,108,109,111,110,20,53,78,23,30,40,39,84,85,86,91,92,34,35].includes(c)) return [`image/unfrightprop/${p}/icon.png`];
  if (c === 12) return [`image/task/${p}/icon.png`];
  if (c === 16) return [`image/specialprop/chatBall/${p}/icon.png`];
  if (c < 10 || [13,14,28,29].includes(c)) {
    const type = c === 28 ? 'armlet' : c === 29 ? 'ring' : types[c];
    if (!type) return [];
    if ([8,9,14,28,29].includes(c)) return [`image/equip/${type}/${p}/icon.png`];
    return (item.sex === 1 ? ['m'] : item.sex === 2 ? ['f'] : ['m','f']).map(sex => `image/equip/${sex}/${type}/${p}/icon_1.png`);
  }
  if (c === 15) return [`image/equip/wing/${p}/icon.png`];
  if ([17,31].includes(c)) return [`image/equip/offhand/${p}/icon.png`];
  if (c === 25) return [`image/gift/${p}/icon.png`];
  if (c === 26) return [`image/card/${p}/icon.jpg`];
  if ([18,66].includes(c)) return [`image/cardbox/${p}/icon.png`];
  if (c === 19) return [`image/equip/recover/${p}/icon.png`];
  if ([32,36].includes(c)) return [`image/farm/Crops/${p}/seed.png`];
  if (c === 33) return [`image/farm/Fertilizer/${p}/icon.png`];
  if ([50,51,52].includes(c)) return [`image/petequip/${({50:'arm',51:'hat',52:'cloth'})[c]}/${p}/icon.png`];
  if (c === 74) return [`image/rune/${p}.png`];
  if (c === 87) return [`image/farm/prop/${p}.png`];
  if (c === 70) return []; // Dynamic amulet subtype is supplied separately by the client.
  return [`image/prop/${p}/icon.png`];
}
const paths = [...new Set(items.flatMap(icons))];
const missing = paths.filter(name => !fs.existsSync(path.join(root, name)));
const report = {candidates:paths.length, existing:paths.length-missing.length, missing:missing.length, downloaded:[], failed:[], skipped:items.filter(item=>icons(item).length===0).map(item=>item.id)};
if (!process.argv.includes('--apply')) {
  fs.writeFileSync(output, JSON.stringify({...report, paths:missing}, null, 2));
  console.log(JSON.stringify({candidates:report.candidates,existing:report.existing,missing:report.missing,skipped:report.skipped.length}));
} else {
  let cursor=0;
  async function worker() {
    while(cursor<missing.length) {
      const name=missing[cursor++];
      try {
        const response=await fetch('https://gunny.vcdn.vn/'+name,{signal:AbortSignal.timeout(20000)});
        if(!response.ok) throw Error('HTTP '+response.status);
        const bytes=Buffer.from(await response.arrayBuffer());
        if(bytes.length>8*1024*1024 || !(bytes.subarray(0,8).equals(Buffer.from('89504e470d0a1a0a','hex')) || bytes.subarray(0,3).equals(Buffer.from('ffd8ff','hex')))) throw Error('Not a PNG/JPEG image');
        const destination=path.join(root,name); fs.mkdirSync(path.dirname(destination),{recursive:true});
        fs.writeFileSync(destination,bytes,{flag:'wx'}); report.downloaded.push(name);
      } catch(error) {report.failed.push({path:name,error:error.name==='TimeoutError'?'Timeout':error.message});}
      if((report.downloaded.length+report.failed.length)%100===0) console.log(JSON.stringify({processed:report.downloaded.length+report.failed.length,total:missing.length,downloaded:report.downloaded.length,failed:report.failed.length}));
    }
  }
  Promise.all(Array.from({length:8},worker)).then(()=>{
    fs.writeFileSync(output,JSON.stringify(report,null,2));
    console.log(JSON.stringify({downloaded:report.downloaded.length,failed:report.failed.length,report:output}));
  }).catch(error=>{console.error(error);process.exitCode=1;});
}
