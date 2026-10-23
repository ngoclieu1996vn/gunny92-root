const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const URL = require('url').URL;
function sanitizeUrl(raw) {
  try {
    const url = new URL(raw); url.username = ''; url.password = '';
    Array.from(new Set(Array.from(url.searchParams.keys()))).forEach(key => url.searchParams.set(key, '[redacted]'));
    url.hash = ''; return url.toString();
  } catch (_) { return '[invalid-url]'; }
}
function isMetadataUrl(raw) {
  try { const url = new URL(raw); return /^https?:$/.test(url.protocol) && /\/(?:templatealllist\d*\.(?:xml|ashx)|shopitem(?:all)?list\.(?:xml|ashx)|config\.xml)$/i.test(url.pathname); }
  catch (_) { return false; }
}
function command(debuggerApi, method, params) {
  return new Promise((resolve, reject) => {
    let settled = false;
    const timer = setTimeout(() => finish(new Error('Debugger command timed out')), 5000);
    function finish(error, result) {
      if(settled) return; settled = true; clearTimeout(timer);
      if(error) reject(error); else resolve(result);
    }
    try {
      const pending = debuggerApi.sendCommand(method, params);
      if(pending && typeof pending.then === 'function') pending.then(result => finish(null,result), finish);
      else debuggerApi.sendCommand(method, params, finish); // Older Electron uses a callback; both commands are read-only.
    } catch(error) { finish(error); }
  });
}
function attachMetadataCapture(contents, output, log) {
  const directory = path.join(output, 'metadata');
  if (!fs.existsSync(directory)) fs.mkdirSync(directory);
  const pending = new Map(); const debuggerApi = contents.debugger;
  debuggerApi.on('message', (_, method, params) => {
    if (method === 'Network.responseReceived' && params.response && isMetadataUrl(params.response.url) && params.response.status >= 200 && params.response.status < 300) {
      pending.set(params.requestId, params.response);
    } else if (method === 'Network.loadingFailed') {
      pending.delete(params.requestId);
    } else if (method === 'Network.loadingFinished' && pending.has(params.requestId)) {
      const response = pending.get(params.requestId); pending.delete(params.requestId);
      command(debuggerApi,'Network.getResponseBody', {requestId:params.requestId}).then(result => {
        if (!result || typeof result.body !== 'string') { log({type:'metadata-error',url:sanitizeUrl(response.url),message:'Response body unavailable'}); return; }
        const bytes = Buffer.from(result.body, result.base64Encoded ? 'base64' : 'utf8');
        if (!bytes.length || bytes.length > 64 * 1024 * 1024) { log({type:'metadata-error',url:sanitizeUrl(response.url),message:'Empty or oversized table'}); return; }
        const url = new URL(response.url);
        const digest = crypto.createHash('sha256').update(url.origin + url.pathname).update(bytes).digest('hex');
        const name = (url.hostname + '-' + path.basename(url.pathname)).replace(/[^A-Za-z0-9._-]/g,'_') + '-' + digest + '.bin';
        try {
          fs.writeFileSync(path.join(directory,name),bytes);
          const record = {time:new Date().toISOString(),url:sanitizeUrl(response.url),file:name,bytes:bytes.length,mimeType:response.mimeType || ''};
          fs.appendFileSync(path.join(directory,'captures.jsonl'),JSON.stringify(record)+'\n');
          log({type:'metadata-saved',url:record.url,file:name,bytes:bytes.length});
        } catch (_) { log({type:'metadata-error',message:'Could not save captured table'}); }
      }).catch(() => log({type:'metadata-error',url:sanitizeUrl(response.url),message:'Response body unavailable'}));
    }
  });
  try { debuggerApi.attach('1.1'); }
  catch (_) { log({type:'metadata-error',message:'Could not attach network capture'}); return Promise.resolve(false); }
  return command(debuggerApi,'Network.enable', {}).then(() => {
    log({type:'metadata-ready',message:'Capturing item tables and config responses only'}); return true;
  }).catch(() => { log({type:'metadata-error',message:'Network capture unavailable'}); return false; });
}
module.exports = {sanitizeUrl,isMetadataUrl,attachMetadataCapture};
