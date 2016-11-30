--- Common functions for build mode


--- Initialise the mmbm table, set range values (level) for build mode
mmbm = {
   buildMode = {
	  level = {
		 {	-- upgrade1
			range = 13,		-- Range increase
			power =  1,		-- Power increase (multiplier)
			size  =  1,		-- Dig size bonus (above normal maximum)
		 },
		 {	-- upgrade2
			range = 26,
			power =  2,
			size  =  2,
		 },
		 {	-- upgrade3
			range = 39,
			power =  3,
			size  =  3,
		 },
	  },
   },
}

--- Adds a 0th element to the array.  Doesn't get counted in pairs() but can be
--- accessed manually, which simplifies beamaxeRange(), buildRange(), and init()
mmbm.buildMode.level[0] = {
   range = 0,
   power = 0,
   size  = 0,
}

--- Returns the beamaxe upgrade table [beamaxe.parameters.upgrades] or nil
function mmbm.getBeamaxeUpgrades ()
   local beamaxe = player.essentialItem("beamaxe")
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
   return mmbm.buildMode.level[mmbm.beamaxeRange()].range
end

--- Predicate, returns whether build mode can be enabled as a boolean.
function mmbm.canBuildMode ()
   if mmbm.beamaxeRange() > 0 then return true end
   return false
end


--return bmc
