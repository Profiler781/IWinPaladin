# IWinPaladin v1.3

Smart macros for Turtle Paladins v1.18.0. Make macros with commands. Put them on your action bars. Enjoy!

## Commands

    /idps           Single target rotation
    /icleave        Multi target rotation
    /ichase         Stick to your target with Judgement of Justice and Hand of Freedom
    /istun          Stun with Hammer of Justice or Repentance
    /itaunt         Hand of Reckoning if the target is not under another taunt effect
    /ibubblehearth  Divine Shield and Hearthstone. Shame!

## Setup commands

The feature is designed to manage judgement assignements on elites and worldbosses.

    /iwinpaladin                                    Current setup
    /iwinpaladin judgement <judgementName>          Setup for all roles
    /iwinpaladin judgementtank <judgementName>      Setup for tank roles
    /iwinpaladin judgementdps <judgementName>       Setup for dps/offtank roles
    /iwinpaladin judgementpull <judgementName>      Setup for prepull cast
    /iwinpaladin soc <socOption>                    Setup for Seal of Command

judgementName possible values: wisdom, light, crusader.
socOption possible values: auto, on, off.

Example: /iwinpaladin judgement wisdom
=> Will setup wisdom as the default judgement for all roles.

## Required Mods & Addons

Mandatory Mods:
* [SuperWoW](https://github.com/balakethelock/SuperWoW/), A mod made for fixing client bugs and expanding the lua-based API used by user interface addons.

You need one of the following addons:
* [pfUI](https://shagu.org/pfUI/), A full UI replacement.
* [ShaguTweaks](https://shagu.org/ShaguTweaks/), A non-intrusive quality of life addon.