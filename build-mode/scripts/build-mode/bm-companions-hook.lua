--------------------------------------------------------------------------------
--- Build Mode companions hook : Used to modify manipulator settings
--------------------------------------------------------------------------------
---
--- Access to the player table is blocked in many scripts, techs being one. As a
--- workaround, this script receives messages about build mode through status
--- properties and uses them to reconfigure the matter manipulator.
---
--------------------------------------------------------------------------------

--- Common functions and data used by all parts of build mode
require "/scripts/build-mode/bm-common.lua"

--- Shadow the companions update function.
--- This function runs constantly, keep it small and do no more than necessary
--- in an iteration.
local function _update ()
   local updateSuper = update
   return function (dt)
	  local prop = mmbm.prop
	  if prop.get("update") == 1 then
		 mmbm.manipulator.update()
		 prop.set("update", 0)
	  end
	  -- TODO:  Remove me before release.  Testing values here
	  local bp = player.essentialItem("beamaxe").parameters
	  print("::> " .. sb.print(bp.tileDamage))
	  if updateSuper then updateSuper(dt) end
   end
end

--- Shadow the companions init function and initialise new update function.
local function _init ()
   local initSuper = init
   return function ()
	  if initSuper then initSuper() end
	  update = _update()
   end
end
init = _init()
