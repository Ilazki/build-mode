function init()
end

--- TODO:  Reevaluate the negative effects of overload mode after spending
--- some time using it.
function update(dt)
   mcontroller.controlModifiers({
		 groundMovementModifier = 0.4,
		 speedModifier = 0.4,
--		 airJumpModifier = 0.8,
   })
end
