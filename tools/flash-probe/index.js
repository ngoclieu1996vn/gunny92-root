const { app, BrowserWindow, session } = require('electron');
const fs = require('fs');
const path = require('path');
const output = path.resolve(__dirname, '../..');
const metadataMode = process.env.GUNNY_PROBE_METADATA === '1';
const {sanitizeUrl,isMetadataUrl,attachMetadataCapture} = require('./metadata-capture');
const run = 'autocheck-' + Date.now();
app.setPath('userData', path.join(output, 'profile-' + run));
app.commandLine.appendSwitch('ppapi-flash-path', process.env.GUNNY_PROBE_FLASH);
app.commandLine.appendSwitch('disable-renderer-backgrounding');
fs.writeFileSync(path.join(output, 'latest-run.txt'), run);
fs.writeFileSync(path.join(output, 'latest.jsonl'), '');
const log = data => {
  if(data.url && metadataMode) data.url = sanitizeUrl(data.url);
  else if(data.url) { const url = new URL(data.url); for(const key of ['key','session','password']) if(url.searchParams.has(key)) url.searchParams.set(key,'[redacted]'); data.url=url.toString(); }
  const line = JSON.stringify({time:new Date().toISOString(),...data}) + '\n';
  fs.appendFileSync(path.join(output, run + '.jsonl'), line);
  fs.appendFileSync(path.join(output, 'latest.jsonl'), line);
};
app.on('ready', async () => {
  setTimeout(() => {log({type:'finished'});app.exit(0);}, Math.max(30, Number(process.env.GUNNY_PROBE_DURATION) || 120) * 1000);
  log({type:'runtime',versions:process.versions || {}});
  await session.defaultSession.clearCache();
  const win = new BrowserWindow({show:process.env.GUNNY_PROBE_SHOW === '1', width:1200, height:850, webPreferences:{plugins:true, backgroundThrottling:false}});
  if(metadataMode) {
    await win.loadURL('about:blank');
    await attachMetadataCapture(win.webContents, output, log);
    // Let Electron create popups normally so referrer, opener and form data survive.
    // Attach to each child without delaying its normal navigation.
    app.on('browser-window-created', (_, child) => {
      attachMetadataCapture(child.webContents, output, log);
    });
  }
  if(process.env.GUNNY_PROBE_DIAGNOSTIC === '1') {
    session.defaultSession.webRequest.onBeforeRequest({urls:['http://127.0.0.1:8888/flash/2.png*']}, (details, callback) => {
      const target = new URL(details.url); target.pathname = '/flash/2.diagnostic.png';
      callback({redirectURL:target.toString()});
    });
  }
  session.defaultSession.webRequest.onCompleted(d => { if(metadataMode && !isMetadataUrl(d.url)) return; log({type:'response', url:d.url, status:d.statusCode, cached:d.fromCache}); });
  session.defaultSession.webRequest.onErrorOccurred(d => { if(metadataMode && !isMetadataUrl(d.url)) return; log({type:'error', url:d.url, error:d.error}); });
  if(!metadataMode) win.webContents.on('console-message', (_, level, message) => log({type:'console', level, message}));
  win.webContents.on('plugin-crashed', (_, name) => log({type:'plugin-crashed', name}));
  await win.loadURL(process.env.GUNNY_PROBE_URL || 'http://127.0.0.1:8888/play2.aspx?user=admin123');
  if(metadataMode) log({type:'page-loaded',url:process.env.GUNNY_PROBE_URL});
  log({type:'plugins', plugins:await win.webContents.executeJavaScript('Array.from(navigator.plugins).map(p=>({name:p.name,filename:p.filename}))')});
  let capturing = false;
  const capture = async () => {
    if(capturing) return;
    capturing = true;
    try {
      const shot = await win.webContents.capturePage();
      fs.writeFileSync(path.join(output,run + '.png'),shot.toPNG());
      fs.writeFileSync(path.join(output,'latest.png'),shot.toPNG());
      log({type:'screenshot',file:'latest.png'});
    } catch(e) {log({type:'capture-error',message:e.message});}
    capturing = false;
  };
  if(!metadataMode) setInterval(capture, Math.max(500, Number(process.env.GUNNY_PROBE_CAPTURE_MS) || 8000));
  setInterval(async () => {
    const commands = path.join(output,'commands.json');
    if(!fs.existsSync(commands)) return;
    try {
      const actions = JSON.parse(fs.readFileSync(commands,'utf8').replace(/^\uFEFF/,''));
      fs.unlinkSync(commands);
      for(const action of actions) {
        if(action.type === 'navigate') {
          const target = new URL(action.url);
          if(!['http:','https:'].includes(target.protocol) || (target.hostname !== '127.0.0.1' && target.hostname !== 'localhost')) throw new Error('Probe navigation must stay on localhost HTTP(S).');
          await win.loadURL(target.toString());
        } else if(action.type === 'focus') {
          win.show(); win.focus(); win.webContents.focus();
        } else win.webContents.sendInputEvent(action);
        await new Promise(resolve => setTimeout(resolve, 75));
      }
    } catch(e) {log({type:'input-error',message:e.message});}
  }, 500);
});
