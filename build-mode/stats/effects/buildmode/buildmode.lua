--- TODO:  Determine if these settings are good or if further adjustment is
--- needed to keep build mode feeling fair despite its benefits.

--- If more adjustments are needed and this file gets more complicated, I'll
--- have to revise how I'm handling it to avoid repetition.  It's just a couple
--- things right now, so it's not worth the effort just yet.


--- Effects and their defaults
local mods = { speedMod   = 1,
			   jumpMod    = 1,
			   combatMod  = 1,
			   defenseMod = 1,
}

--- Update table m with data from statuseffect file and return it
local function getModifiers (m)
   local m = m or { }
   for key,default in pairs(m) do
	  m[key] = config.getParameter(key, default)
   end
   return m
end

--- Set combat penalties
function init ()
   mods = getModifiers(mods)
   effect.addStatModifierGroup({
   		 { stat = "powerMultiplier",
		   effectiveMultiplier = mods.combatMod
   		 }
   })
   effect.addStatModifierGroup({
		 { stat = "protection",
		   effectiveMultiplier = mods.defenseMod
		 }
   })

end

--- Set movement penalties
function update (dt)
   mcontroller.controlModifiers({
		 groundMovementModifier = mods.speedMod,
		 speedModifier = mods.speedMod,
		 airJumpModifier = mods.jumpMod,
   })
end
