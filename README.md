# orbSellAndRepair

World of Warcraft addon, updated for **World of Warcraft: Forever** (interface 16001, Mainline API).

Automatically sell your gray items and repair your equipment when you visit a merchant.

Configuration :

* enable / disable auto sale
* enable / disable auto repair
    * enable / disable guild auto repair
    * reputation limit for auto repair

## Installation

Copy the `orbSellAndRepair` folder into the `Interface/AddOns/` folder of your WoW Forever installation.

Options: Esc > Options > AddOns > orbSellAndRepair.

## Updating the interface version

When a new game patch is released, the addon may be flagged as "out of date". To update it:

1. In game, run the following command in the chat to get the current interface number:

   ```
   /dump select(4, GetBuildInfo())
   ```

2. Replace the value of the `## Interface:` line in `orbSellAndRepair.toc` with the number returned (e.g. `## Interface: 16001`).
3. Restart the game client (changes to the `.toc` file are not picked up by `/reload`).
