#!/usr/bin/lua

--- Edit these if needed
metadata = "_metadata"					-- mod metadata file
vdf      = "build-mode.vdf"				-- Steam workshop vdf file
packName = "build-mode.pak"				-- name of the packed file
distPath = "./_dist/"					-- where to put the packed file
modPath  = "./build-mode/"				-- location of mod
binDir   = "../bin/"					-- location of asset_packer

env = os.getenv
run = os.execute

--- This is all lazy, hacky code but I don't care. It's just a quick-n-dirty
--- packaging script.

local function getLetter ()
   return string.sub(io.read('*line'),1,1)
end


local function getAnswer (defaultYes)
   local s = getLetter()
   local answer
   if defaultYes then 
	  return s == "Y" or s == "y" or string.byte(s) == 10
   else
	  return s == "Y" or s == "y" -- or string.byte(s) == 10
   end
end

editor = env("VISUAL") or env("EDITOR") or "vi"
pwd = env("PWD") .. "/"


--- Offer to update metadata
io.write(string.format("Edit %s? [y/N]  ", metadata))
if getAnswer() then run(string.format("%s %s%s", editor, modPath, metadata)) end

--- Offer to update vdf
io.write(string.format("Edit %s? [y/N]  ", vdf))
if getAnswer() then run(string.format("%s %s", editor, vdf)) end

--- Pack the mod up, drop it into _dist
run(string.format("%s %s %s", binDir .. "asset_packer", modPath, distPath .. packName))

print("File packed and saved to " .. distPath .. packName .. ".")
print("To upload, enter this into a steamcmd session:  \n")
print(string.format("workshop_build_item %s", pwd .. vdf))
print("")



