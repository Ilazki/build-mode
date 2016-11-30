--- Common functions and data used by all parts of build mode
require "/scripts/build-mode/bm-common.lua"

--- TODO:  See if it's possible to set a hotkey to toggle build mode.

--- Predicate, returns checkbox status as boolean
local function buildMode ()
   return widget.getChecked("rangeCheckbox")
end


--- Test and update build mode state as part of GUI updates.
local function updateBuildMode ()
   local canBuildMode = mmbm.canBuildMode(player)
   widget.setButtonEnabled("rangeCheckbox",canBuildMode)
   widget.setFontColor("rangeLabel", (canBuildMode and "#FFFFFF") or "#888888")
   mmbm.rangeCheckbox()
end

local updateGuiSuper
function mmbm.updateGui ()
   if updateGuiSuper then updateGuiSuper() end
   updateBuildMode()
end

--- Shadow existing init and call it within new init.
local initSuper = init
function init ()
   initSuper()
   updateGuiSuper = updateGui
   updateGui = mmbm.updateGui

   -- Check beam radius and set the initial state of the checkbox appropriately.
   for i,v in ipairs(mmbm.buildMode.level) do
	  if status.statusProperty("bonusBeamGunRadius") == v["range"] then
		 widget.setChecked("rangeCheckbox",true)
	  end
   end
end

--- /gui/rangeCheckbox callback
function mmbm.rangeCheckbox ()
   local beamaxe = player.essentialItem("beamaxe")
   local json
   local newRange
   local canBuildMode = mmbm.canBuildMode(player)
   -- Set beamaxe range to Build Mode value, add Build Mode effect
   if canBuildMode and buildMode() then
	  newRange = mmbm.buildRange(player)
	  status.addEphemeralEffect("buildmode", math.huge)
   -- Set beamaxe range to normal value, remove Build Mode effect
   elseif canBuildMode then
	  -- Loads the mmupgradegui JSON data into `json` and then access the
	  -- json.upgrades.range[1-3].setStatusProperties.bonusBeamGunRadius entry.
	  -- This guarantees that disabling build-mode will use the correct value
	  -- for an upgrade even if another mod changes the bonus values.

	  -- Additionally, a note on the unusual property access: OOP style syntax
	  -- is just sugar over the normal table syntax, making it  possible to
	  -- simplify the code by accessing upgrades.range[1-3] dynamically using
	  -- the upgrades["keyname"] table syntax and string concatenation.
	  json = root.assetJson("/interface/scripted/mmupgrade/mmupgradegui.config")
	  newRange = json.
		 upgrades["range" .. mmbm.beamaxeRange(player)].
		 setStatusProperties.
		 bonusBeamGunRadius
	  status.removeEphemeralEffect("buildmode")
   -- Build Mode isn't available.  Set range to 0, remove effect, and uncheck box.
   else
	  newRange = 0
	  status.removeEphemeralEffect("buildmode")
	  widget.setChecked("rangeCheckbox",false)
   end
   -- Apply change to beamaxe range.
   status.setStatusProperty("bonusBeamGunRadius",newRange)
end
