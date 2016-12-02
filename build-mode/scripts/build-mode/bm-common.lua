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
--- Functions to check and return information
---

--- Returns the beamaxe upgrade table [beamaxe.parameters.upgrades] or nil
function mmbm.getBeamaxeUpgrades ()
   local beamaxe = player.essentialItem("beamaxe") or { }
   return beamaxe and
	  beamaxe.parameters and
	  beamaxe.parameters.upgrades
end

--- Returns beamaxe (MM) upgrade level [0-3]
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
   local beamRange = mmbm.beamaxeRange(player)
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
   print(sb.print("Size up!"))
end

--- Request a size decrease and set update trigger for the next tick.
function mmbm.size.decrease ()
      print(sb.print("Size down!"))
end

--- MM update trigger and helpers
mmbm.manipulator = { }

--- manipulator update trigger, called from bm-companions-hook.lua whenever an
--- update has been requested by another part of build mode.
function mmbm.manipulator.update ()
   local prop = mmbm.prop or { }
   local beamaxe = player.essentialItem("beamaxe")
   beamaxe.parameters.tileDamage = mmbm.manipulator.overload(beamaxe.parameters.tileDamage)
   player.giveEssentialItem("beamaxe",beamaxe)
end

--- Overload function used by mmbm.manipulator.update to calculate new MM power.
function mmbm.manipulator.overload(tileDamage)
   local prop = mmbm.prop or { }
   if tileDamage == nil then return nil end	-- Edge case protection
   local level = mmbm.beamaxeRange()
   local power = mmbm.buildMode.level[level].power
   if prop.get("overload") == 1 then
	  status.addEphemeralEffect("buildmode-overload", math.huge)
	  tileDamage = tileDamage * power
   else
	  status.removeEphemeralEffect("buildmode-overload", math.huge)
	  tileDamage = tileDamage / power
   end
   return tileDamage
end


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
--- Miscellaneous

--- Predicate, tests if a table is empty.
function mmbm.util.empty (t)
   return next(t) == nil
end

