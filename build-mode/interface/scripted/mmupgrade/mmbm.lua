--------------------------------------------------------------------------------
--- MM Upgrade UI hook : UI components for Build Mode
--------------------------------------------------------------------------------
---
--- This script draws the build mode label and checkbox and handles some basic
--- edge cases with redrawing the UI elements when upgrades are performed, so
--- that the checkbox becomes usable after upgrading optics without reloading
--- the interface.
---
--------------------------------------------------------------------------------


--- Common functions and data used by all parts of build mode
require "/scripts/build-mode/bm-common.lua"


--- Predicate, returns checkbox status as boolean
local function buildModeChecked ()
   return widget.getChecked("rangeCheckbox")
end

--- Test and update build mode state as part of GUI updates.
local function updateBuildMode ()
   local canBuildMode = mmbm.canBuildMode(player)
   widget.setButtonEnabled("rangeCheckbox",canBuildMode)
   widget.setFontColor("rangeLabel", (canBuildMode and "#FFFFFF") or "#888888")
   mmbm.rangeCheckbox()
end

--- Closure that creates a function replacement for `updateGui`
local function _updateGui ()
   local updateGuiSuper = updateGui
   return function ()
	  if updateGuiSuper then updateGuiSuper() end
	  updateBuildMode()
   end
end

--- Closure that creates a replacement for `init`
local function _init ()
   local initSuper = init
   return function ()
	  -- Call the hooked init
	  if initSuper then initSuper() end

	  -- Switch off overload and trigger a reset as precaution against unwanted
	  -- interaction between build mode and Matter Manipulator Manipulator.
	  -- So far this seems to work okay, but if it becomes too much trouble I'll
	  -- go for the nuclear option:  grey out and disable all the MMM UI parts
	  -- when build mode is active to avoid using both simultaneously.

	  -- Leaving it enabled already causes one problem with beam power because
	  -- MMM adjusts beam power in relation to its beam size.  The increased
	  -- power ends up stacking on top of the overload bonus since I'm using
	  -- a multiplier instead of predefined values.

	  -- In practice, this should not be a problem because the overload mode is
	  -- already nearly instant for most block types.  If people want to use
	  -- this for faster brainsblock looting, so be it.
	  if mmbm.statusEffect("buildmode-overload") then
		 mmbm.overload.toggle() end
	  mmbm.prop.set("hotkeys",0)

	  -- Shadow `updateGui` with new function
	  updateGui = _updateGui()
	  -- Check beam radius and set the initial state of the checkbox appropriately.
	  for i,v in ipairs(mmbm.buildMode.level) do
		 if status.statusProperty("bonusBeamGunRadius") == v["range"] then
			widget.setChecked("rangeCheckbox",true)
		 end
	  end
	  -- Trigger UI update to apply the above change.
	  updateGui()
   end
end

-- Shadow `init` with new function
init = _init()

--- Uninit hook to re-enable hotkeys after UI is closed.
local function _uninit ()
   local uninitSuper = uninit
   return function ()
	  if uninitSuper then uninitSuper() end
	  mmbm.prop.set("hotkeys",1)
   end
end
uninit = _uninit()


--- /gui/rangeCheckbox callback
function mmbm.rangeCheckbox ()
   local canBuildMode = mmbm.canBuildMode()
   if canBuildMode and buildModeChecked() then
	  mmbm.enableBuildMode()
	  --- Testing disabling MMM parts.
   else
	  if not canBuildMode then
		 widget.setChecked("rangeCheckbox",false) end
	  mmbm.disableBuildMode()
   end
end
