const assert=require('node:assert/strict');
const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const {EventEmitter}=require('node:events');
const output=fs.mkdtempSync(path.resolve(__dirname,'../../scratch/probe-metadata-test-'));
const timers=[], timeouts=[], appEvents={}; let ready, window, screenshotCalls=0;
class Debugger extends EventEmitter {
 constructor(owner){super();this.owner=owner;}
 attach(version){this.attached=true;}
 sendCommand(method,params){if(method==='Network.enable'&&this.owner.loaded)assert.equal(this.owner.loaded,'about:blank','Warm up the main renderer before waiting for capture');return Promise.resolve(method==='Network.getResponseBody'?this.body:{});}
}
class Window {
 constructor(){window=this;this.webContents=new EventEmitter();this.webContents.debugger=new Debugger(this);this.webContents.executeJavaScript=async()=>[];this.webContents.capturePage=async()=>{screenshotCalls++;return {toPNG:()=>Buffer.from('unused')}};}
 async loadURL(url){assert.ok(timeouts.some(timer=>timer.ms>=30000),'Duration limit must exist even if loading never resolves');this.loaded=url;}
}
const electron={app:{setPath(){},commandLine:{appendSwitch(){}},on(event,callback){appEvents[event]=callback;if(event==='ready')ready=callback;},exit(){}},BrowserWindow:Window,session:{defaultSession:{async clearCache(){},webRequest:{onBeforeRequest(){},onCompleted(){},onErrorOccurred(){}}}}};
const env={GUNNY_PROBE_METADATA:'1',GUNNY_PROBE_URL:'https://www.gnddt.com/',GUNNY_PROBE_SHOW:'1'};
const context={require:name=>name==='electron'?electron:require(name),__dirname:path.join(output,'resources/app'),process:{env},URL,Buffer,console,setInterval:(callback,ms)=>timers.push({callback,ms}),setTimeout:(callback,ms)=>timeouts.push({callback,ms})};
vm.runInNewContext(fs.readFileSync(path.join(__dirname,'index.js'),'utf8'),context);
(async()=>{
 await ready();
 assert.equal(window.webContents.debugger.attached,true,'Metadata mode must enable response capture before loading the game');
 assert.equal(window.loaded,'https://www.gnddt.com/');
 assert.ok(timeouts.some(timer=>timer.ms>=30000),'Duration limit must be installed during startup');
 let prevented=false;
 window.webContents.emit('new-window',{preventDefault(){prevented=true;}},'https://play.gnddt.com/RedircetPlayGame.aspx?user=secret');
 assert.equal(prevented,false,'Keep Electron native popup navigation, opener, referrer and form semantics');
 const parent=window;const child=new Window();
 appEvents['browser-window-created']({},child);
 await new Promise(resolve=>setImmediate(resolve));
 assert.equal(child.webContents.debugger.attached,true,'Capture metadata in native game popup windows too');
 window=parent;
 assert.match(fs.readFileSync(path.join(output,'latest.jsonl'),'utf8'),/metadata-ready/,'Metadata initialization must complete successfully');
 for(const timer of timers)if(timer.ms>=8000)await timer.callback();
 assert.equal(screenshotCalls,0,'Metadata mode must not record login/game screenshots');
 const {isMetadataUrl,sanitizeUrl}=require('./metadata-capture');
 assert.equal(isMetadataUrl('https://req.gnddt.com/Request/TemplateAllList.xml?rnd=1'),true);
 assert.equal(isMetadataUrl('https://req.gnddt.com/Request/config.xml'),true);
 assert.equal(isMetadataUrl('https://www.gnddt.com/login?file=TemplateAllList.xml'),false);
 assert.equal(isMetadataUrl('https://www.gnddt.com/api/login.ashx'),false);
 const safe=sanitizeUrl('https://user:password@play.gnddt.com/game?key=secret&token=secret2&account=private');
 assert.ok(!safe.includes('secret')&&!safe.includes('password')&&!safe.includes('private'));
 const bytes=require('node:zlib').deflateSync(Buffer.from('<Result><Item TemplateID="8220" Name="test"/></Result>'));
 window.webContents.debugger.body={body:bytes.toString('base64'),base64Encoded:true};
 window.webContents.debugger.emit('message',{},'Network.responseReceived',{requestId:'template-1',response:{url:'https://req.gnddt.com/Request/TemplateAllList.xml?key=secret',status:200,mimeType:'application/octet-stream'}});
 window.webContents.debugger.emit('message',{},'Network.loadingFinished',{requestId:'template-1'});
 await new Promise(resolve=>setImmediate(resolve));
 const directory=path.join(output,'metadata');const files=fs.readdirSync(directory).filter(name=>name.endsWith('.bin'));
 assert.equal(files.length,1);assert.deepEqual(fs.readFileSync(path.join(directory,files[0])),bytes,'Capture must preserve compressed bytes exactly');
 const manifest=fs.readFileSync(path.join(directory,'captures.jsonl'),'utf8');assert.ok(!manifest.includes('secret'));assert.match(manifest,/TemplateAllList/);
 const otherBytes=Buffer.from('<Result version="2"/>');
 window.webContents.debugger.body={body:otherBytes.toString('base64'),base64Encoded:true};
 window.webContents.debugger.emit('message',{},'Network.responseReceived',{requestId:'template-2',response:{url:'https://req.gnddt.com/Request/TemplateAllList.xml?key=secret',status:200}});
 window.webContents.debugger.emit('message',{},'Network.loadingFinished',{requestId:'template-2'});
 await new Promise(resolve=>setImmediate(resolve));
 const records=fs.readFileSync(path.join(directory,'captures.jsonl'),'utf8').trim().split('\n').map(JSON.parse);
 assert.notEqual(records[0].file,records[1].file,'Different response bodies must never overwrite earlier captures');
 assert.deepEqual(fs.readFileSync(path.join(directory,records[0].file)),bytes);
 assert.deepEqual(fs.readFileSync(path.join(directory,records[1].file)),otherBytes);
 const before=2;
 window.webContents.debugger.body={body:'x\ufffd\ufffdcorrupted-compressed-text',base64Encoded:false};
 window.webContents.debugger.emit('message',{},'Network.responseReceived',{requestId:'bad-text',response:{url:'https://req.gnddt.com/Request/TemplateAllList.xml',status:200}});
 window.webContents.debugger.emit('message',{},'Network.loadingFinished',{requestId:'bad-text'});
 await new Promise(resolve=>setImmediate(resolve));
 assert.equal(fs.readdirSync(directory).filter(name=>name.endsWith('.bin')).length,before,'Do not save compressed bytes damaged by debugger text decoding');
 window.webContents.debugger.emit('message',{},'Network.responseReceived',{requestId:'login-1',response:{url:'https://www.gnddt.com/api/login.ashx?password=secret',status:200}});
 window.webContents.debugger.emit('message',{},'Network.loadingFinished',{requestId:'login-1'});
 assert.equal(fs.readdirSync(directory).filter(name=>name.endsWith('.bin')).length,before,'Never capture login response bodies');
 const legacyDirectory=path.join(output,'legacy-api');fs.mkdirSync(legacyDirectory);
 const legacyDebugger=new EventEmitter();legacyDebugger.attach=()=>{};
 legacyDebugger.sendCommand=(method,params,callback)=>{if(callback)callback(null,method==='Network.getResponseBody'?{body:bytes.toString('base64'),base64Encoded:true}:{});};
 const legacyReady=await require('./metadata-capture').attachMetadataCapture({debugger:legacyDebugger},legacyDirectory,()=>{});
 assert.equal(legacyReady,true,'Capture must also support callback-style Electron debugger APIs');
 legacyDebugger.emit('message',{},'Network.responseReceived',{requestId:'legacy-template',response:{url:'https://req.gnddt.com/Request/TemplateAllList.xml',status:200}});
 legacyDebugger.emit('message',{},'Network.loadingFinished',{requestId:'legacy-template'});
 await new Promise(resolve=>setImmediate(resolve));
 assert.equal(fs.readdirSync(path.join(legacyDirectory,'metadata')).filter(name=>name.endsWith('.bin')).length,1);
 console.log('PASS: metadata probe attaches before loading, captures only table/config bodies without changing bytes, redacts URL values and skips screenshots/login responses.');
})().catch(error=>{console.error(error);process.exitCode=1;});
