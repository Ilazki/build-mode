function init()
end

--- TODO:  Determine if these settings are good or if further adjustment is
--- needed to keep build mode feeling fair despite its benefits.
function update(dt)
   mcontroller.controlModifiers({
		 groundMovementModifier = 0.4,
		 speedModifier = 0.4,
--		 airJumpModifier = 0.8,
   })
end
