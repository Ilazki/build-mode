--------------------------------------------------------------------------------
--- Build Mode tech hook : Captures key bindings for real-time MM adjustment.
--------------------------------------------------------------------------------
---
--- Keypress capture is only(?) possible with techs, and even then only able to
--- capture a small subset of possible keybinds.  This script captures keys for
--- build-mode by hooking into the morph ball techs in a way that preserves
--- their normal operation outside of build mode, and even works correctly with
--- mods that modify those techs.
---
--- Tech scripts cannot access the player table, so this script is unable to
--- directly use captured keypresses in any meaningful way.  As a workaround, it
--- sets status properties intended to be used by bm-companions-hook.lua, which
--- can use the information to reconfigure the matter manipulator. 
---
--------------------------------------------------------------------------------

--- Common functions and data used by all parts of build mode
require "/scripts/build-mode/bm-common.lua"


--- Tests all keypresses in the keys map against the full moves map, returns true
--- if all keys match.
local function testBind (keys, moves)
   for k,v in pairs(keys) do
	  if not (v == moves[k]) then
		 return false
	  end
   end
   return true
end

--- This works but I don't like how I did it, modifying binds.call in separate functions sucks.
--- TODO:  Rewrite this more cleanly later.

--- Checks all binds against moves table, mark non-matches as free to call.
function testBinds (binds,moves)
   local matchedBinds = {}
   for i,v in ipairs(binds) do
	  if testBind(v.keys,moves) then
		 table.insert(matchedBinds,v)
	  else
		 v.call = true		-- Bind is free to call again
	  end
   end
      return matchedBinds
end

--- Execute binds (passing args if given), marking each as uncallable to avoid repeat-calls
function execBinds (binds,args)
   for i,v in ipairs(binds) do
	  if v.call then
		 v.f(args)
		 v.call = false -- Bind is no longer callable until reset.
	  end
   end
   return binds
end

--- Key handler.  Doesn't have to do much, just pass `moves` through testBinds and execBinds
local function keyHandler (moves,args)
   local prop = mmbm.prop or { }
   -- Do nothing if there's been a request to disable hotkey catching.
   if mmbm.prop.get("hotkeys") ~= 0 then
	  return execBinds(testBinds(mmbm.keybinds, moves), args) end
end


--- TODO:  Decide if I really want to use closures for function hooks.  They're
--- safer than using file-scoped locals, but not as commonly understood.  This
--- may hurt readability in the long-term, especially for others.

--- Closure that binds `update` to `updateSuper`, returns a function to be
--- used as the new `update`.
--  This function is constantly called, keep it free of unnecessary crap.
local function _update ()
   local updateSuper = update
   return function (args)
	  if mmbm.statusEffect("buildmode",status) then
		 keyHandler(args.moves)
	  else
		 if updateSuper then updateSuper(args) end
	  end
   end
end

--- Closure that creates a new init function
local function _init ()
   local initSuper = init
   return function ()
	  -- Shadow `update`
	  update = _update()
	  if initSuper then initSuper() end
   end
end
--- Shadow `init`
init = _init()



