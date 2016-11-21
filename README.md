# Build Mode

Build Mode adds a new setting to the Matter Manipulator that greatly increases its range.  It's intended to improve the building experience without affecting normal gameplay.  When enabled, build mode allows the player to focus on building by removing the need to constantly move around during construction.  It also has a secondary purpose of attempting to make the manipulator's optics upgrades more appealing.

This mod was made to allow more convenient use of a graphics tablet for building; if you have one, give it a try.

## How it works

A new checkbox labeled 'Build Mode' can be found in the Matter Manipulator upgrade pane beneath the Optics section.  It remains greyed out until you have unlocked at least one optics upgrade.  Once unlocked, it can be enabled without restriction, and while active it will do the following things:

* The matter manipulator's **range is greatly increased** in build mode.  This range increase is affected by your optics upgrades:  higher optics gives greater range increases.
* A build mode status effect provides **visual feedback**.  It appears under the hunger bar like any other status effect.
* Movement speed is **greatly reduced** while build mode is active.  This is primarily to discourage leaving build mode enabled all the time.  The speed decrease is similar to that of the 'Walk / MM Precision' key binding.


## Compatibility

* Should work with other MM mods.  Build Mode adds very little:  two GUI elements, a script, and a status effect.  Ranges are pulled from the mmupgradegui.config, so it should even work with addons that change these values, such as the Overpowered Matter Manipulator mod.
* Exception:  build mode **will not work with Enhanced Matter Manipulator**.  EMM completely changes the GUI and upgrade scheme.  I won't be supporting this, sorry.
* Tested to work with Matter Manipulator Manipulator and Manipulated UI.

## Notes and Warnings

If you decide to uninstall this mod, **TURN OFF BUILD MODE FIRST on any characters using it**.  Since build mode uses a custom status effect, any character with the effect still active after removal will disappear from the selection screen until the mod is reinstalled.

## Miscellaneous

More adjustments and improvements to build mode may be made later.  Range values may need adjustment and I might add a power boost as well.
