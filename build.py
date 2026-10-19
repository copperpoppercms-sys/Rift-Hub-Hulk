"""Build the standalone entrypoint and full editable copy page from canonical modules."""
from pathlib import Path
import html
root=Path(__file__).parent
pose=(root/'src/Pose.lua').read_text()
leap=(root/'src/HulkLeap.lua').read_text()
brand=(root/'src/Brand.lua').read_text()
effects=(root/'src/Effects.lua').read_text()
motion=(root/'src/HulkMotion.lua').read_text()
catalog=(root/'src/AnimationCatalog.lua').read_text()
source='''-- Rift Hub / Hulk / 3.0 | Rift Gamma original Hulk motion
-- Original motion and controller code are embedded. Catalog playback is optional.
local env = type(getgenv) == "function" and getgenv() or _G
local existing = env.RiftHulkCharacter
if type(existing) == "table" and type(existing.Unload) == "function" then pcall(existing.Unload) end
local player = game:GetService("Players").LocalPlayer
assert(player, "Run Rift Hulk from a Roblox client")
local Utils = { GetCharacter = function(plr) return (plr or player).Character end }
local Kit = { INK=Color3.fromRGB(239,240,247), SUB=Color3.fromRGB(171,175,191) }
function Kit.face(name, weight)
 local ok,font=pcall(Font.fromName,name,weight or Enum.FontWeight.Regular,Enum.FontStyle.Normal)
 return ok and font or Font.fromEnum(Enum.Font.Gotham)
end
function Kit.create(class,props,parent)
 local obj=Instance.new(class)
 for key,value in pairs(props) do obj[key]=value end
 if parent then obj.Parent=parent end
 return obj
end
local HulkMotion=(function()
'''+motion+'''\nend)()
local CatalogCtor=(function()
'''+catalog+'''\nend)()
local PoseModule=(function()
'''+pose+'''\nend)()
local function PoseCtor(char) return PoseModule(char,HulkMotion) end
local BrandCtor=(function()
'''+brand+'''\nend)()
local EffectsCtor=(function()
'''+effects+'''\nend)()
local LeapCtor=(function()
'''+leap+'''\nend)()
local brand=BrandCtor("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/assets/rift_logo.jpg")
local api=LeapCtor(Utils,Kit,PoseCtor,brand,EffectsCtor,CatalogCtor)
api.Game="Hulk"
api.Version="3.0"
local stop=api.Stop
function api.Unload()
 stop()
 if env.RiftHulkCharacter==api then env.RiftHulkCharacter=nil end
end
api.OnClose=api.Unload
local ok,err=api.SetEnabled(true)
if not ok then api.Unload();error("Rift Hulk could not open: " .. tostring(err)) end
env.RiftHulkCharacter=api
return api
'''
(root/'main.lua').write_text(source)
(root/'execute.lua').write_text('loadstring(game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua?cb=" .. tostring(os.time())))()\n')
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Rift Hulk — editable full script</title><style>
:root{color-scheme:dark;font-family:system-ui;background:#0e1711;color:#e5efe7}body{max-width:1000px;margin:auto;padding:20px}h1{font-size:24px}p{color:#afc7b5;line-height:1.5}.tools{display:flex;flex-wrap:wrap;gap:10px;margin:18px 0}button{background:#28643b;color:white;border:1px solid #428a54;border-radius:8px;padding:12px 18px;font:600 14px system-ui}textarea{box-sizing:border-box;width:100%;height:65vh;min-height:320px;padding:14px;background:#111e16;color:#e3efe6;border:1px solid #355540;border-radius:10px;font:13px/1.6 ui-monospace,monospace;tab-size:4;white-space:pre}#status{min-height:28px;color:#a8eaba}</style></head><body>
<h1>Rift Gamma / Hulk · 3.0</h1><p>Original Hulk motion: breathing stance, heavy walk/run, deep charge, takeoff, tucked leap, meteor dive, two-fist landing and Gamma Roar. Hold POWER LEAP, then release. BOUND jumps quickly; METEOR dives; GAMMA ROAR plays a grounded pose. Keys: Z / X / C / R. Original mode needs no animation asset access. Optional Catalog mode resolves items from a researched Hulk pack and falls back to original motion.</p>
<div class="tools"><button id="copy">Copy all code</button><button id="select">Select all</button><button id="download">Download .lua</button></div><div id="status" role="status" aria-live="polite">The full script below is editable.</div><textarea id="source" aria-label="Full editable Luau script" spellcheck="false" autocapitalize="off" autocomplete="off" autocorrect="off" wrap="off">'''+html.escape(source)+'''</textarea><script>
const source=document.getElementById('source'),status=document.getElementById('status');
function selectAll(){source.focus();source.select();source.setSelectionRange(0,source.value.length)}
document.getElementById('select').onclick=()=>{selectAll();status.textContent='All code selected. Use Copy on your device.'};
document.getElementById('copy').onclick=async()=>{try{if(!navigator.clipboard)throw Error();await navigator.clipboard.writeText(source.value);status.textContent='All code copied.'}catch(e){selectAll();let ok=false;try{ok=document.execCommand('copy')}catch(e){}status.textContent=ok?'All code copied.':'Code selected. Press and hold and choose Copy.'}};
document.getElementById('download').onclick=()=>{const url=URL.createObjectURL(new Blob([source.value],{type:'text/plain;charset=utf-8'}));const link=document.createElement('a');link.href=url;link.download='Rift_Hulk.lua';document.body.appendChild(link);link.click();link.remove();setTimeout(()=>URL.revokeObjectURL(url),1000)};
source.oninput=()=>{status.textContent='Edited. Copy and Download use your current code.'};
</script></body></html>'''
(root/'docs/Hulk_Editor.html').write_text(page)
print('Built standalone Lua and editable HTML:',len(source),'characters')
