# Implementation Details

#### Mod Structure
`bm-common.lua` contains most of the code and is imported by other scripts.  Code inside other files should be specific to that file with no chance of reusability, such as UI code in `mmbm.lua`.  `buildmode.lua`, `buildmode-overload.lua`, and their patch files control the status effects.  The UI changes are defined and controlled by `mmbm.lua` and `mmupgradegui.config.patch`.  Hotkeys are captured in `build-mode-tech.lua` and on-the-fly manipulator changes are handled by `bm-companions-hook.lua`.

#### Basic Features
The basic range feature is fairly standard, just a checkbox in the manipulator upgrade UI that toggles the range and a status effect that is used to apply the speed, power, and defense reductions.  Where it gets weird is tooltip creation, because it's undocumented, and hotkey handling as a consequence of how Starbound restricts access to certain functions and information depending on the script's context.

#### Hotkey Handling: Techs
Keypress information, for example, is only available to the `update` function of scripts used by head, leg, and chest techs, and is further limited to only a subset of possible keys:  *up*, *down*, *left*, *right*, *run*, *jump*, *primaryFire*, *altFire*, and *special*.  So, to get access to these to change manipulator size and power, a hook into the head techs was required.   `build-mode-tech.lua` hooks the `update` function and intercepts keypresses when build mode is active, otherwise passing it on to the normal update function to preserve normal behaviour.  Other mods that change or replace the hooked techs (should) be unaffected.  Even other mods attempting to intercept hotkeys should work, since this one only blocks further execution when the build mode status effect is active.

#### Hotkey Handling:  Companions
Unfortunately, this creates a new problem:  tech scripts are restricted from accessing the `player` table, which is needed to get access to the equipped manipulator and make changes to it.  `player` access is tightly controlled and only accessible in a few contexts such as interface panes (the manipulator upgrade GUI), quests, and companions (pets and crewmembers).  Of these, the only one that is always present is the companion context.

With that in mind, the `bm-companions-hook.lua` script is added to the list of companion scripts to run with a `player.config.patch` and hooks into the `update` function so that a hotkey handler can run every tick.  So, now there's a way to catch hotkeys in one script and a way to manipulate the matter manipulator based on keypress in another.  Most of the necessary parts are in place.

#### Hotkey Handling:  Message Passing
The final piece to the hotkey puzzle is getting data from `build-mode-tech.lua`, which can receive keypresses, to `bm-companions-hook.lua`, which can act on them.  Attempts to set tables up and share them between contexts failed, so it came down to finding a way to implement some form or message passing instead.  Thanks to the `status` table, which is more widely available to scripts, this turned out to be pretty easy.  The relevant part of `status` was a getter/setter function pair, `status.statusProperty(name)` and `status.setStatusProperty(name,data)`.

Status properties are JSON entries that are tied to a name and stored as part of the player's status, so that if you call `setStatusProperty("foo",{bar = 10, baz = 20})`, you can later call `statusProperty("foo") to get the table back again.  A beneficial (and likely unintentional) side effect of this design is that one can dedicate a status property to the task of passing messages between scripts that normally can't share data, which is how Build Mode's hotkey handling became possible.

In `bm-common.lua` there is a set of functions, in `mmbm.util.properties`, dedicated to managing properties.  The functions are as follows:

* `get (property, key)` : retrieve the value of `key` from the `property` status property.
* `set (property, key, value)` : sets `value` to `key` inside the `properety` status property.
* `delete (property, key)` : removes `key` from the status property named `property`.
* `reset (property)` : wipes the status property, removing all key/value pairs.
* `all (property)` : returns the entire `property` status property.  `all` is little more than a wrapper function that does `return status.stautsProperty(property)`, but is necessary because the `status` table doesn't exist at file read time, which can cause issues.

In order to avoid some repetition, I also added a basic, single-argument form of partial application, `mmbm.util.partial`, and used it to create functions with the `property` argument already filled with "bulidmode", like this:  `get = partial(mmbm.util.properties.get, "buildmode")`.  With that done, the message passing system was ready.  

#### Hotkey Handling:  All Together

With everything in place, the process works like this:

* `build-mode-tech.lua` checks for a valid key combination from the `mmbm.keybinds` table, and if detected, calls the appropriate function
* The called function sets up the request message.  `mmbm.size.increase`, for example, calls `prop.set("sizeChange",1)` to request the operation to perform, and also calls `prop.set("update",1)` to indicate that there's a new request waiting.
* Since the `update` function in `bm-companions-hook.lua` runs every game tick, it attempts to save cycles by checking the update property (`mmbm.prop.get("update")`) first, to determine if there's any work to do, and bails out early if not.
* If an update was marked, it runs the `mmbm.manipulator.update` function, which then checks the different keys to see which actions are requested for that update.
* Each requested update is performend.
* Finally, `prop.set("update",0)` is called to stop further command execution until another event changes its state again.

#### Manipulator Upgrade GUI Tooltip
While working on adding hotkey support, I realised I needed a way to help mod users discover the new feature since hotkeys, especially chorded ones like I used, aren't very intuitive..  Showing some sort of first-run popup panel, or adding a "manipulator's manual" item to the player's inventory on first run were the first ideas, but they ran afoul of the goal to keep the mod as unobtrusive as psosible when not actively being used.  Some kind of UI tooltip tied to the "Build Mode" label seemed like a good idea, but led to the problem of *how* to add a tooltip.  

Other than item tooltips, the game is pretty limited on its use of them, and searching online gave no useful results.  However, the Collections interface shows tooltips on completed items, so there had to be some way to do it.  A glance at `/interface/scripted/collections/collectionsgui.lua` showed that it defines a function, `createTooltip (screenPosition)`, but never calls it.  A search through all of the files in the game's assets revealed that the function is never used anywhere else, but it clearly works, so it must be being called by the game engine.

The way `createTooltip` works is, the engine calls it and provides a `screenPosition` argument that is a two element array with the current x and y position of the cursor, and expects `createTooltip` to return a tooltip back.  If the return argument is a table describing a valid tooltip, that tooltip is drawn, and if the function `return`s without any arguments, no tooltip is drawn.

Figuring out what's considered a valid tooltip can mostly be done by checking the game assets' `collectionsgui.config`, with more inferred from the `createTooltip` definition in `collectionsgui.lua`.  Better still, dumping the tooltip's table to the log right before the `return tooltip` gives a view of the entire structure.  Using that as a reference, I modified the `mmupgradegui.config.patch` file to create a new `tooltips` section in the `mmupgradegui.config` and load that from `mmbm.lua` when I need to display a tooltip.

Working out how to do this also turned up a convenient, but undocumented, `widget` function:  `widget.inMember(widgetName, screenPosition)`.  It determines whether the cursor is placed over the `widgetName` UI element, allowing actions to trigger on hover without requiring a click.  With that, it was easy to create a small `createTooltip` function in the manipulator GUI script (`mmbm.lua`) to pop up a brief explanation of build mode when the player hovers over the `[?]` next to the Build Mode label.

(I'm not aware of anyone else doing this, but in an attempt to be friendly to other mods that might provide their own tooltips, my `createTooltip` function tries to hook into an existing tooltip function, if one exists, and runs that first.)

