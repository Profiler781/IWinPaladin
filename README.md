# IWinPaladin v1.3

## IWinPaladin has been integrated into IWinEnhanced. Only IWinEnhanced will receive updates.

[IWinEnhanced](https://github.com/Profiler781/IWinEnhanced/)

Smart macros for Turtle Paladins v1.18.0. Make macros with commands. Put them on your action bars. Enjoy!

Author: Agamemnoth (discord)

## Commands

    /idps           Single target DPS rotation
    /icleave        Multi target DPS rotation
    /itank          Single target Prot rotation
    /ihodor         Multi target Prot rotation
    /ieco           Mana regeneration rotation
    /ijudge         Seal and Judgement only
    /istun          Stun with Hammer of Justice or Repentance
    /itaunt         Hand of Reckoning if the target is not under another taunt effect
    /ibubblehearth  Divine Shield and Hearthstone. Shame!
    /ihydrate       Use conjured or vendor water

## Setup commands

    /iwin                                   Current setup
    /iwin judgement <judgementName>         Setup for Judgement on elites and worldbosses
    /iwin wisdom <classification>           Setup for Seal of Wisdom target classification
    /iwin crusader <classification>         Setup for Seal of the Crusader target classification
    /iwin light <classification>            Setup for Seal of Light target classification
    /iwin justice <classification>          Setup for Seal of Justice target classification
    /iwin soc <socOption>                   Setup for Seal of Command

judgementName possible values: wisdom, light, crusader, justice, off.

socOption possible values: auto, on, off.

classification possible values: elite, boss.

Example: /iwin judgement wisdom
=> Will setup wisdom as the default judgement.

## Required Mods & Addons

Mandatory Mods:
* [SuperWoW](https://github.com/balakethelock/SuperWoW/), A mod made for fixing client bugs and expanding the lua-based API used by user interface addons. Used for debuff tracking.
* [Nampower](https://github.com/pepopo978/nampower/), A mod made to dramatically increase cast efficiency on the 1.12.1 client. Used for range checks.

You need one of the following addons, used for debuff tracking:
* [SuperCleveRoidMacros](https://github.com/jrc13245/SuperCleveRoidMacros/), Recommanded, Advanced macro conditions and syntax.
* [pfUI](https://github.com/shagu/pfUI/), A full UI replacement.
* [ShaguTweaks](https://github.com/shagu/ShaguTweaks/), A non-intrusive quality of life addon.

Optionnal Addons:
* [PallyPowerTW](https://github.com/ivanovlk/PallyPowerTW/), An addon for paladin blessings, auras and judgements assignements.
* [LibramSwap](https://github.com/Profiler781/Libramswap), An addon to automatically swap librams based on cast.