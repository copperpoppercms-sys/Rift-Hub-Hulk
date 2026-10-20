-- Hulk is a separate script; this loader is never used by main startup.
local source=game:HttpGet("https://raw.githubusercontent.com/copperpoppercms-sys/Rift-Hub-Hulk/main/main.lua?cb="..tostring(os.time()))
local header="-- RiftHub-Entry: hulk-character"
assert(type(source)=="string" and source:sub(1,#header)==header,"Wrong Hulk script response; reopen Rift and retry")
local chunk,err=loadstring(source,"=RiftHubHulk/main.lua")
assert(chunk,err)
local app=chunk()
assert(type(app)=="table" and app.Game=="Hulk" and app.Gui and app.Gui.Parent,"Hulk did not finish opening")
return app
