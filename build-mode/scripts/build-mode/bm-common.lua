--------------------------------------------------------------------------------
--- bm-common.lua:  Shared data and functions for build mode components
--------------------------------------------------------------------------------
---
--- Other build mode scripts should only have functions and data that is unique
--- to those files.  Anything that isn't file-specific is put here to make reuse
--- of functions easier.
---
--- NOTE:  Due to the way Starbound isolates scripts from certain tables based
--- on the script's context (tech, companion, UI, etc.), not all functions here
--- will be usable in all scripts.  This is unfortunate but unavoidable.
---
--- As a precaution, functions using external tables will attempt to set a local
--- to that table and fall back to an empty table if unavailable.
---
--- If this file grows too large it will be split into multiple files sorted by
--- purpose.
---
--------------------------------------------------------------------------------

--- Initialise the mmbm table and its sub-tables
mmbm = {
   buildMode = { },
   util      = { },		-- Home of utility functions not directly related to BM
}

--- Values used when build mode is enabled
mmbm.buildMode.level = {
   -- Adds a "0" key to the table.  It isn't counted in pairs() but can be
   -- accessed manually, simplifying code in beamaxeRange(), buildRange(),
   -- and mmbm.lua:init()
   [0] = {				-- no upgrades
	  range = 0,
	  power = 0,
	  size  = 0,
   },
   {					-- upgrade1
	  range = 13,		-- Range increase
	  power =  1,		-- Power increase (multiplier)
	  size  =  1,		-- Dig size bonus (above normal maximum)
   },
   {					-- upgrade2
	  range = 26,
	  power =  2,
	  size  =  2,
   },
   {					-- upgrade3
	  range = 39,
	  power =  4,
	  size  =  3,
   },
}

--- The beamaxe parameters table is empty if no upgrades have been applied yet.
--- This usually isn't a problem because build mode requires one optics upgrade,
--- but I'm providing the base values here for use in edge case tests.
mmbm.base = {
   range = 0,
   power = 1.2,
   size  = 2,
   paint = 3
}

--- Map of keybinds and functions to call.  Functions can be anonymous or named,
--- and can accept arguments, though that's likely to be of limited usefulness.
--- Note that named functions (e.g. `f = foo`) have to exist at parse-time while
--- anonymous functions defer symbol resolution until call time.  This makes the
--- anonymous calls safer.

--- Valid key names:  up, down, left, right, run, jump, primaryFire, altFire,
--- special. Special is a number (0 or 1, possibly more) and refers to the morph
--- ball activation, others all use booleans.  "run" detects use of the "walk /
--  MM precision" key, the rest are obvious.
mmbm.keybinds = {
   {
	  keys = {special = 1, up = true},
	  f = function () mmbm.size.increase() end
   },
   {
	  keys = {special = 1, down = true},
	  f = function () mmbm.size.decrease() end
   },
   {
	  keys = {special = 1, jump = true},
	  f = function () mmbm.overload.toggle() end
   },
   {
	  keys = {special = 1, left = true},
	  f = function () mmbm.zoom.decrease() end
   },
   {
	  keys = {special = 1, right = true},
	  f = function () mmbm.zoom.increase() end
   }

   -- {
   -- 	  keys = {run = false, jump = true},
   -- 	  f = function () print("shift-jump example") end
   -- }
}


--------------------------------------------------------------------------------
--- Functions that need to be declared first for use in this file
---

--- Rudimentary partial application. Only applies one arg; good enough for this.
function mmbm.util.partial (f, a1)
   return function(...)
	  return f(a1, ...)
   end
end
local partial = mmbm.util.partial


--------------------------------------------------------------------------------
--- Status property functions

mmbm.util.properties = { }

--- Return the value saved inside a status property's key.
function mmbm.util.properties.get (property, key)
   local status = status
   if not (status and property and key) then return nil end
   local t = status.statusProperty(property) or { }
   for k,v in pairs(t) do
	  if k == key then
		 return v end
   end
   return nil
end

--- Add a new key/value pair to a status property.
function mmbm.util.properties.set (property, key, value)
   local status = status
   if not (status and property and key and value) then return nil end
   local t = status.statusProperty(property) or { }
   t[key] = value
   status.setStatusProperty(property, t)
end

--- Remove a key from a status property.
function mmbm.util.properties.delete (property, key)
   local status = status
   if not (status and property and key) then return nil end
   local t = status.statusProperty(property) or { }
   local new = { }
   for k,v in pairs(t) do
	  if k ~= key then
		 new[k] = v end
   end
   status.setStatusProperty(property, new)
end

--- Reset status property.
function mmbm.util.properties.reset (property)
   local status = status
   if not (property and status) then return nil end
   status.setStatusProperty(property, nil)
end


--- Pointless wrapper because status doesn't exist during parsing for assignment
function mmbm.util.properties.all (property)
   local status = status
   if not (property and status) then return nil end
   return status.statusProperty(property)
end


--- Partial functions of the above with the property name set to "buildmode"
do
   local p = "buildmode"
   local ns = mmbm.util.properties
   mmbm.prop = {
	  get = partial(ns.get, p),
	  set = partial(ns.set, p),
	  delete = partial(ns.delete, p),
	  reset  = partial(ns.reset,  p),
	  all    = partial(ns.all,    p),
   }
end


--------------------------------------------------------------------------------
--- Functions to check and return information
---

--- Returns the beamaxe upgrade table [beamaxe.parameters.upgrades] or nil
function mmbm.getBeamaxeUpgrades ()
   local beamaxe = player.essentialItem("beamaxe") or { }
   return beamaxe and
	  beamaxe.parameters and
	  beamaxe.parameters.upgrades
end

--- TODO:  Refactor to remove code duplication.
--- I should have a generic function to get upgrade types by name and use that
--- instead.  Once done I can use partial() to provide these functions for
--- compatibility or call the new function directly.

--- Returns beamaxe (MM) range upgrade level [0-3]
function mmbm.beamaxeRange ()
   local bmu = mmbm.getBeamaxeUpgrades()
   local beamRange = 0
   if not bmu then return beamRange end
   for k,v in pairs(bmu) do
	  local upgrade = string.sub(v,1,#v-1)
	  if upgrade == "range" then
		 local ugLevel = tonumber(string.sub(v,#v,#v))
		 if ugLevel > beamRange then beamRange = ugLevel end
	  end
   end
   return beamRange
end


--- Returns beamaxe (MM) size upgrade level [0-3]
function mmbm.beamaxeSize ()
   local bmu = mmbm.getBeamaxeUpgrades()
   local beamSize = 0
   if not bmu then return beamSize end
   for k,v in pairs(bmu) do
	  local upgrade = string.sub(v,1,#v-1)
	  if upgrade == "size" then
		 local ugLevel = tonumber(string.sub(v,#v,#v))
		 if ugLevel > beamSize then beamSize = ugLevel end
	  end
   end
   return beamSize
end

--- Returns beamaxe (MM) size upgrade level [0-3]
function mmbm.beamaxePower ()
   local bmu = mmbm.getBeamaxeUpgrades()
   local beamPower = 0
   if not bmu then return beamPower end
   for k,v in pairs(bmu) do
	  local upgrade = string.sub(v,1,#v-1)
	  if upgrade == "power" then
		 local ugLevel = tonumber(string.sub(v,#v,#v))
		 if ugLevel > beamPower then beamPower = ugLevel end
	  end
   end
   return beamPower
end


--- Returns correct build mode range for beamaxe upgrade level.
function mmbm.buildRange ()
   return mmbm.buildMode.level[mmbm.beamaxeRange(player)].range
end

--- Predicate, returns whether build mode can be enabled as a boolean.
function mmbm.canBuildMode ()
   if mmbm.beamaxeRange() > 0 then
	  return true end
   return false
end

--- Test for a status effect in the status list.
function mmbm.statusEffect (effect)
   local status = status or { }
   local effects = status.activeUniqueStatusEffectSummary()
   for i,v in ipairs(effects) do
	  if v[1] == effect then return true end
   end
   return false
end


--------------------------------------------------------------------------------
--- MM state functions
---

-- Set beamaxe range to Build Mode value, add Build Mode effect
function mmbm.enableBuildMode()
   local player = player or { }
   local status = status or { }
   local newRange = mmbm.buildRange()
   status.addEphemeralEffect("buildmode", math.huge)
   status.setStatusProperty("bonusBeamGunRadius",newRange)
end

-- Set beamaxe range to normal value, remove Build Mode effect
function mmbm.disableBuildMode()
   local player = player or { }
   local status = status or { }
   local json = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
   local beamRange = mmbm.beamaxeRange()
   local newRange
   if beamRange > 0 then
	  -- Loads the mmupgradegui JSON data into `json` and then access the
	  -- json.upgrades.range[1-3].setStatusProperties.bonusBeamGunRadius entry.
	  -- This guarantees that disabling build-mode will use the correct value
	  -- for an upgrade even if another mod changes the bonus values.

	  -- Additionally, a note on the unusual property access: OOP style syntax
	  -- is just sugar over the normal table syntax, making it  possible to
	  -- simplify the code by accessing upgrades.range[1-3] dynamically using
	  -- the upgrades["keyname"] table syntax and string concatenation.

	  beamRange = json.
		 upgrades["range" .. beamRange].
		 setStatusProperties.
		 bonusBeamGunRadius
   end
   if mmbm.statusEffect("buildmode-overload") then
	  mmbm.overload.toggle() end
   status.removeEphemeralEffect("buildmode")
   status.setStatusProperty("bonusBeamGunRadius",beamRange)
end

--- Zoom functions
mmbm.zoom = { }

function mmbm.zoom.increase ()
   local prop = mmbm.prop or { }
   prop.set("zoom",1)
   prop.set("update",1)
end

function mmbm.zoom.decrease ()
   local prop = mmbm.prop or { }
   prop.set("zoom",-1)
   prop.set("update",1)
end


--- Overload functions.
mmbm.overload = { }

--- Toggle overload message state and set an update trigger for the next tick.
function mmbm.overload.toggle ()
   local status = status or { }
   local prop = mmbm.prop or { }
   prop.set("update", 1)		-- Set notification that MM update is needed.
								-- Uses 0/1 because boolean props act strangely.
   if not mmbm.statusEffect("buildmode-overload") then
	  prop.set("overload", 1)	-- on
   else
	  prop.set("overload", 0)	-- off
   end
end

--- Size adjustment functions.
mmbm.size = { }

--- Request a size increase and set update trigger for the next tick.
function mmbm.size.increase ()
   local prop = mmbm.prop or { }
   prop.set("sizeChange",1)
   prop.set("update",1)
end

--- Request a size decrease and set update trigger for the next tick.
function mmbm.size.decrease ()
   local prop = mmbm.prop or { }
   prop.set("sizeChange",-1)
   prop.set("update",1)
end

--- MM update trigger and helpers
mmbm.manipulator = { }

--- manipulator update trigger, called from bm-companions-hook.lua whenever an
--- update has been requested by another part of build mode.

--- Probably better if I pass around the full beamaxe and change it in every
--- function, but this will work for now.
--- TODO:  Refactor later.
function mmbm.manipulator.update ()
   local prop = mmbm.prop or { }
   local beamaxe = player.essentialItem("beamaxe")
   local painttool = player.essentialItem("painttool")

   -- Test and set zoom
   mmbm.manipulator.zoom()

   -- Test and set overload
   beamaxe.parameters.tileDamage = mmbm.manipulator.overload(beamaxe.parameters.tileDamage)

   -- Update the beamaxe size
   local size = mmbm.manipulator.size(beamaxe.parameters.blockRadius)
   beamaxe.parameters.blockRadius = size

   -- Update painttool size and give it to player
   if painttool then
	  painttool.parameters.blockRadius = size
	  player.giveEssentialItem("painttool",painttool)
   end

   -- Give modified beamaxe to player
   player.giveEssentialItem("beamaxe",beamaxe)
end


--- Resets manipulator sizes and turns off overload, essentially reverting the
--- manipulator to its vanilla state.  Used when entering the GUI to prevent
--- conflicts.
--- TODO:  Clean up later.  May want to create helper functions for the
--- painttool and beamaxe handling.
function mmbm.manipulator.reset ()
   local beamaxe = player.essentialItem("beamaxe")
   local painttool = player.essentialItem("painttool")
   beamaxe.parameters.blockRadius = mmbm.getBaseSize()
   player.giveEssentialItem("beamaxe",beamaxe)
	if painttool then
	   painttool.parameters.blockRadius = mmbm.base.paint
	   player.giveEssentialItem("painttool",painttool)
	end
	if mmbm.statusEffect("buildmode-overload") then
	   mmbm.overload.toggle() end
end


function mmbm.getBaseSize ()
   -- Hard-coding the radius when it's invalid (such as nil) is a terrible
   -- solution, but I can't find anything to determine it programmatically,
   -- and the parameters table remains empty until an upgrade is done.
   local baseSize = mmbm.base.size
   local level = mmbm.beamaxeSize()
   if level > 0 then
	  local json = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
	  baseSize = json.
		 upgrades["size" .. level].
		 setItemParameters.
		 blockRadius
   end
   return baseSize
end

--- Checks the requested size change against valid min and max sizes and returns
--- a new beamaxe blockRadius size.
function mmbm.manipulator.size(blockRadius, reset)
   local prop = mmbm.prop or { }
   local baseSize = mmbm.getBaseSize()
   local sizeChange = prop.get("sizeChange")
   if type(sizeChange) ~= "number" then sizeChange = 0 end

   -- No upgrades yet, default to the base size.  Should be impossible but
   -- better to be cautious.
   if type(blockRadius) ~= "number" then
	  blockRadius = baseSize
   end

   local maxSize = baseSize + mmbm.buildMode.level[mmbm.beamaxeRange()].size
   local newSize = blockRadius + sizeChange
   if newSize < 1 then newSize = 1 end
   if newSize > maxSize then newSize = maxSize end

   prop.set("sizeChange",0)
   return newSize
end

--- Overload function used by mmbm.manipulator.update to calculate new MM power.
function mmbm.manipulator.overload(tileDamage)
   local prop = mmbm.prop or { }
   if tileDamage == nil then return nil end	-- Edge case protection
   local level = mmbm.beamaxeRange()
   local power = mmbm.buildMode.level[level].power
   local overload = prop.get("overload")
   if overload == 1 then
	  status.addEphemeralEffect("buildmode-overload", math.huge)
	  tileDamage = tileDamage * power
   elseif overload == 0 then
	  status.removeEphemeralEffect("buildmode-overload", math.huge)
	  tileDamage = tileDamage / power
   end
   prop.delete("overload")		-- Remove property when done.
   return tileDamage
end

--- Change zoom level, respecting values defined in optionsmenu.config
function mmbm.manipulator.zoom ()
   local prop = mmbm.prop or { }

   -- Attempt to get zoom change, break out early if no change requested.
   local zoomChange  = prop.get("zoom")
   if type(zoomChange) ~= "number" then zoom = 0 end
   if zoom == 0 then return end

   -- Get current and valid zoom levels from configs, set min/max/current zooms.
   local json = root.assetJson("/interface/optionsmenu/optionsmenu.config") or { }
   local zoomList = json.zoomList
   table.sort(zoomList)			-- Should already be in order, but just in case
   local minZoom = zoomList[1]					-- First element is minimum zoom
   local maxZoom = zoomList[#zoomList]			-- Last element is maximum zoom
   local curZoom = root.getConfiguration("zoomLevel")

   -- Set desired new zoom, test if valid.
   local newZoom = curZoom + zoomChange
   if newZoom < minZoom then newZoom = minZoom end
   if newZoom > maxZoom then newZoom = maxZoom end

   -- Set new zoom level and reset zoom message.
   root.setConfiguration("zoomLevel",newZoom)
   prop.set("zoom",0)
end


--------------------------------------------------------------------------------
--- Miscellaneous

--- Predicate, tests if a table is empty.
function mmbm.util.empty (t)
   return next(t) == nil
end

