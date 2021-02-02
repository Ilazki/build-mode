# Build Mode

Build Mode adds a new setting to the Matter Manipulator that greatly increases its range and adds hotkey control over its size and power.  Unobtrusive when disabled, it's intended to improve the building experience without affecting normal gameplay.  When enabled, build mode allows the player to focus on building by adding extra manipulator controls and reducing the need to move the player while building.  It also has a secondary goal of attempting to make the manipulator's optics upgrades more appealing.

This mod was made to allow more convenient use of a graphics tablet for building; if you have one, give it a try.

**Build Mode now works with Starbound 1.4.4**

## What it Does

* Adds a checkbox to the Matter Manipulator upgrade screen to toggle build mode.
* The matter manipulator's **range is greatly increased** in build mode.  This range increase is affected by your optics upgrades:  higher optics gives greater range increases.
* If the character has a head tech (one of the four sphere techs), **manipulator settings can be controlled by hotkeys**.
* With fully upgraded optics and matter proc unit, **dig and paint size can be adjusted from 1x1 to 8x8**.
* Adds an **overload mode** toggle that increases the manipulator's tile damage when activated.
* ~~Adds **camera zoom hotkeys**.~~  [**Removed**.  No longer possible due to a Starbound API change.)
* A build mode status effect provides visual feedback.  It appears under the hunger bar like any other status effect.

With the benefits it provides, it's tempting to leave build mode active all the time.  To discourage this and add a measure of risk to using it in the wild, build mode also adds a few negative effects:

* **Movement speed is reduced**.  The speed decrease is similar to that of the 'Walk / MM Precision' key binding.
* **Damage is reduced to 10%**.
* **Defense is halved**.

Further adjustment may be required, but the idea is that it's supposed to be build mode, not dig mode:  use at your own risk when spelunking.

## How to Use Build Mode
A new checkbox labeled 'Build Mode' can be found in the Matter Manipulator upgrade pane beneath the Optics section.  It remains greyed out until you have unlocked at least one optics upgrade.  Once unlocked, it can be enabled without restriction.  When enabled, the effects listed above become active for the duration of its use.  

Its most basic feature, the range increase, needs no further interaction and has no special requirements.  To use the more advanced features, you have to have a head tech (one of the spheres) equipped to enable the hotkey handling.  This is a limitation of the game, unfortunately, rather than a design decision.

Once build mode is enabled and a head tech is equipped, the following key combinations are usable:  

* **activate head tech** + **up**:  Increase dig and paint radius.
* **activate head tech** + **down**:  Decrease dig and paint radius.
* **activate head tech** + **jump**:  Toggle overload mode.  Dig power is greatly increased when enabled.

## Compatibility

* Should work with other MM mods.  Build Mode restores the manipulator's settings to those defined in the game's files when the MM Upgrade interface is opened, so anything patching in new values (such as Overpowered Matter Manipulator) should be unaffected.
* Exception:  build mode **will not work with Enhanced Matter Manipulator**.  EMM completely changes the GUI and upgrade scheme.  I won't be supporting this, sorry.
* I use and explicitly tested against Matter Manipulator Manipulator and Quickbar Mini.  Others should work but haven't necessarily been tested.
* It should be noted that build mode disables one minor feature of the Matter Manipulator Manipulator mod:  lowering the manipulator's size with MMM's spinners will no longer provide a power increase.  Use the overload toggle instead.
* For technical reasons, build mode adds hooks into certain tech and crew/pet scripts.  This should cause no problems with other mods but is listed for completeness.  For example, I use Improved Techs and have no problems.
* Mods that replace any of the four head techs should still work as expected.
* Mods that add additional techs will work, but build mode's hotkeys will only work when using one of the four vanilla techs.

## Notes and Warnings

If you decide to uninstall this mod, **TURN OFF BUILD MODE FIRST on any characters using it**.  Since build mode uses a custom status effect, any character with the effect still active after removal will disappear from the selection screen until the mod is reinstalled.

## Miscellaneous

More adjustments and improvements to build mode may be made later.  Range values may need adjustment, I'm still looking for a way to dynamically change the size of block placement from the 2x2 default, and I have a few ideas for other features as well.

For details about implementation, refer to **Implementation.md**
