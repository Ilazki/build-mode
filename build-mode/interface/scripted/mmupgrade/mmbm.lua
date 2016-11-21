--- TODO:  See if it's possible to set a hotkey to toggle build mode.

--- Initialise the mmbm table, set range values (level) for build mode
mmbm = {
   buildMode = {
	  level = {
		 13,	-- upgrade1
		 26,	-- upgrade2
		 39,	-- upgrade3
	  },
   }
}

--- Adds a 0th element to the array.  Doesn't get counted in pairs() but can be
--- accessed manually, which simplifies beamaxeRange(), buildRange(), and init()
mmbm.buildMode.level[0] = 0

--- Returns the beamaxe upgrade table [beamaxe.parameters.upgrades] or nil
local function getBeamaxeUpgrades ()
   local beamaxe = player.essentialItem("beamaxe")
   return beamaxe and
	  beamaxe.parameters and
	  beamaxe.parameters.upgrades
end

--- Predicate, returns checkbox status as boolean
local function buildMode ()
   return widget.getChecked("rangeCheckbox")
end

--- Returns beamaxe (MM) upgrade level [0-3]
local function beamaxeRange ()
   local bmu = getBeamaxeUpgrades()
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
local function buildRange ()
   return mmbm.buildMode.level[beamaxeRange()]
end

--- Predicate, returns whether build mode can be enabled as a boolean.
local function canBuildMode ()
   if beamaxeRange() > 0 then return true end
   return false
end

--- Test and update build mode state as part of GUI updates.
local function updateBuildMode ()
   local canBuildMode = canBuildMode()
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
	  if status.statusProperty("bonusBeamGunRadius") == v then
		 widget.setChecked("rangeCheckbox",true)
	  end
   end
end

--- /gui/rangeCheckbox callback
function mmbm.rangeCheckbox ()
   local beamaxe = player.essentialItem("beamaxe")
   local json
   local newRange
   local canBuildMode = canBuildMode()
   -- Set beamaxe range to Build Mode value, add Build Mode effect
   if canBuildMode and buildMode() then
	  newRange = buildRange()
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
		 upgrades["range" .. beamaxeRange()].
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
