--[[
#########################################
#  IWinPaladin Discord Agamemnoth#5566  #
#########################################
]]--

---- For Paladins ----
if UnitClass("player") ~= "Paladin" then return end

---- Loading ----
IWin = CreateFrame("frame",nil,UIParent)
IWin.t = CreateFrame("GameTooltip", "IWin_T", UIParent, "GameTooltipTemplate")
--local IWin_Settings = {}
local IWin_CombatVar = {
	["gcd"] = 0,
	["weaponAttackSpeed"] = 0,
}
local Cast = CastSpellByName

---- Event Register ----
IWin:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
IWin:RegisterEvent("ADDON_LOADED")
IWin:RegisterEvent("UNIT_INVENTORY_CHANGED")
IWin:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 == "IWinPaladin" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff IWinPaladin system loaded.|r")
		if iwinpaladinjudgementtank == nil then iwinpaladinjudgementtank = "wisdom" end
		if iwinpaladinjudgementdps == nil then iwinpaladinjudgementdps = "wisdom" end
		if iwinpaladinjudgementpull == nil then iwinpaladinjudgementpull = "wisdom" end
		if iwinpaladinsoc == nil then iwinpaladinsoc = "auto" end
		IWin_CombatVar["weaponAttackSpeed"] = UnitAttackSpeed("player")
		IWin.hasSuperwow = SetAutoloot and true or false
		IWin:UnregisterEvent("ADDON_LOADED")
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" and arg1 == nil then
		IWin_CombatVar["gcd"] = GetTime()
	elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" and not IWin:IsBuffActive("player","Zeal") then
		IWin_CombatVar["weaponAttackSpeed"] = UnitAttackSpeed("player")
	end
end)

---- Spell data ----
IWin_Taunt = {
	"Taunt",
	"Mocking Blow",
	"Challenging Shout",
	"Growl",
	"Challenging Roar",
	"Hand of Reckoning",
}

---- Functions ----
function IWin:GetBuffIndex(unit, spell)
	if unit == "player" then
		if not IWin.hasSuperwow then
	    	DEFAULT_CHAT_FRAME:AddMessage("|cFF00FFFFbalakethelock's SuperWoW|r required:")
	        DEFAULT_CHAT_FRAME:AddMessage("https://github.com/balakethelock/SuperWoW")
	    	return 0
		end
	    local index = 0
	    while true do
	        spellID = GetPlayerBuffID(index)
	        if not spellID then break end
	        if spell == SpellInfo(spellID) then
	        	return index
	        end
	        index = index + 1
	    end
	else
		local index = 1
		while UnitBuff(unit, index) do
			IWin_T:SetOwner(WorldFrame, "ANCHOR_NONE")
			IWin_T:ClearLines()
			IWin_T:SetUnitBuff(unit, index)
			local buffName = IWin_TTextLeft1:GetText()
			if buffName == spell then
				return index
			end
			index = index + 1
		end
	end
	return nil
end

function IWin:GetDebuffIndex(unit, spell)
	index = 1
	while UnitDebuff(unit, index) do
		IWin_T:SetOwner(WorldFrame, "ANCHOR_NONE")
		IWin_T:ClearLines()
		IWin_T:SetUnitDebuff(unit, index)
		local buffName = IWin_TTextLeft1:GetText()
		if buffName == spell then 
			return index
		end
		index = index + 1
	end	
	return nil
end

function IWin:GetBuffStack(unit, spell)
	local index = IWin:GetBuffIndex(unit, spell)
	if index then
		local _, stack = UnitBuff(unit, index)
		return stack
	end
	local index = IWin:GetDebuffIndex(unit, spell)
	if index then
		local _, stack = UnitDebuff(unit, index)
		return stack
	end
	return 0
end

function IWin:IsBuffStack(unit, spell, stack)
	return IWin:GetBuffStack(unit, spell) == stack
end

function IWin:IsBuffActive(unit, spell)
	return IWin:GetBuffStack(unit, spell) ~= 0
end

function IWin:GetBuffRemaining(unit, spell)
	if unit == "player" then
		local index = IWin:GetBuffIndex(unit, spell)
		if index then
			return GetPlayerBuffTimeLeft(index)
		end
		local index = IWin:GetDebuffIndex(unit, spell)
		if index then
			return GetPlayerBuffTimeLeft(index)
		end
	elseif unit == "target" then
		local libdebuff = pfUI and pfUI.api and pfUI.api.libdebuff or ShaguTweaks and ShaguTweaks.libdebuff
		if not libdebuff then
	    	DEFAULT_CHAT_FRAME:AddMessage("Either pfUI or ShaguTweaks required")
	    	return 0
		end
		local index = IWin:GetDebuffIndex(unit, spell)
		if index then
			local _, _, _, _, _, _, timeleft = libdebuff:UnitDebuff("target", index)
			return timeleft
		end
	end
	return 0
end

function IWin:GetCooldownRemaining(spell)
	local spellID = 1
	local bookspell = GetSpellName(spellID, "BOOKTYPE_SPELL")
	while bookspell do	
		if spell == bookspell then
			local start, duration = GetSpellCooldown(spellID, "BOOKTYPE_SPELL")
			if start ~= 0 and duration ~= 1.5 then
				return duration - (GetTime() - start)
			else
				return 0
			end
		end
		spellID = spellID + 1
		bookspell = GetSpellName(spellID, "BOOKTYPE_SPELL")
	end
	return false
end

function IWin:IsOnCooldown(spell)
	return IWin:GetCooldownRemaining(spell) ~= 0
end

function IWin:IsSpellLearnt(spell)
	local spellID = 1
	local bookspell = GetSpellName(spellID, "BOOKTYPE_SPELL")
	while bookspell do
		if bookspell == spell then
			return true
		end
		spellID = spellID + 1
		bookspell = GetSpellName(spellID, "BOOKTYPE_SPELL")
	end
	return false
end

function IWin:IsGCDActive()
	return GetTime() - IWin_CombatVar["gcd"] < 1.5
end

function IWin:IsStanceActive(stance)
	local forms = GetNumShapeshiftForms()
	for index = 1, forms do
		local _, name, active = GetShapeshiftFormInfo(index)
		if name == stance then
			return active == 1
		end
	end
	return false
end

function IWin:GetHealthPercent(unit)
	return UnitHealth(unit) / UnitHealthMax(unit) * 100
end

function IWin:IsExecutePhase()
	return IWin:GetHealthPercent("target") <= 20
end

function IWin:GetManaPercent(unit)
	return UnitMana(unit) / UnitManaMax(unit) * 100
end

function IWin:IsManaAvailable(spell)
	return UnitMana("player") >= IWin_ManaCost[spell]
end

function IWin:IsInMeleeRange()
	return CheckInteractDistance("target", 3) ~= nil
end

function IWin:IsTanking()
	return UnitIsUnit("targettarget", "player")
end

function IWin:GetItemID(itemLink)
	for itemID in string.gfind(itemLink, "|c%x+|Hitem:(%d+):%d+:%d+:%d+|h%[(.-)%]|h|r$") do
		return itemID
	end
end

function IWin:IsShieldEquipped()
	local offHandLink = GetInventoryItemLink("player", 17)
	if offHandLink then
		local _, _, _, _, _, itemSubType = GetItemInfo(tonumber(IWin:GetItemID(offHandLink)))
		return itemSubType == "Shields"
	end
	return false
end

IWin_UnitClassification = {
	["worldboss"] = true,
	["rareelite"] = true,
	["elite"] = true,
	["rare"] = false,
	["normal"] = false,
	["trivial"] = false,
}

function IWin:IsElite()
	local classification = UnitClassification("target")
	return IWin_UnitClassification[classification]
end

function IWin:IsTaunted()
	local index = 1
	while IWin_Taunt[index] do
		local taunt = IWin:IsBuffActive("target", IWin_Taunt[index])
		if taunt then
			return true
		end
		index = index + 1
	end
	return false
end

function IWin:IsSealActive()
	return IWin:IsBuffActive("player","Seal of Righteousness")
		or IWin:IsBuffActive("player","Seal of Wisdom")
		or IWin:IsBuffActive("player","Seal of Light")
		or IWin:IsBuffActive("player","Seal of Justice")
		or IWin:IsBuffActive("player","Seal of the Crusader")
		or IWin:IsBuffActive("player","Seal of Command")
end

function IWin:IsJudgementOverwrite(judgement, seal)
	return IWin:IsBuffActive("target",judgement) and IWin:IsBuffActive("player",seal)
end

function IWin:IsBlessingActive()
	return IWin:IsBuffActive("player","Blessing of Sanctuary")
		or IWin:IsBuffActive("player","Blessing of Might")
		or IWin:IsBuffActive("player","Blessing of Wisdom")
		or IWin:IsBuffActive("player","Blessing of Light")
		or IWin:IsBuffActive("player","Blessing of Kings")
		or IWin:IsBuffActive("player","Blessing of Salvation")
end

---- Actions ----
function IWin:TargetEnemy()
	if not UnitExists("target") or UnitIsDead("target") or UnitIsFriend("target", "player") then
		TargetNearestEnemy()
	end
end

function IWin:StartAttack()
	local attackActionFound = false
	for action = 1, 172 do
		if IsAttackAction(action) then
			attackActionFound = true
			if not IsCurrentAction(action) then
				UseAction(action)
			end
		end
	end
	if not attackActionFound and not PlayerFrame.inCombat then
		AttackTarget()
	end
end

function IWin:MarkSkull()
	if GetRaidTargetIndex("target") ~= 8
		and not UnitIsFriend("player", "target")
		and not UnitInRaid("player") then
			SetRaidTarget("target", 8)
	end
end

function IWin:BlessingOfKings()
	if IWin:IsSpellLearnt("Blessing of Kings")
		and not IWin:IsBuffActive("player","Blessing of Kings") then
			Cast("Blessing of Kings")
	end
end

function IWin:BlessingOfMight()
	if IWin:IsSpellLearnt("Blessing of Might")
		and not IWin:IsBlessingActive() then
			Cast("Blessing of Might")
	end
end

function IWin:BlessingOfSanctuary()
	if IWin:IsSpellLearnt("Blessing of Sanctuary")
		and not IWin:IsBuffActive("player","Blessing of Sanctuary") then
			Cast("Blessing of Sanctuary")
	end
end

function IWin:BlessingOfWisdom()
	if IWin:IsSpellLearnt("Blessing of Wisdom")
		and not IWin:IsBlessingActive() then
			Cast("Blessing of Wisdom")
	end
end

function IWin:Cleanse()
	if IWin:IsSpellLearnt("Cleanse")
		and not IWin:IsOnCooldown("Cleanse")
		and not HasFullControl() then
			Cast("Cleanse")
	end
end

function IWin:Consecration()
	if IWin:IsSpellLearnt("Consecration")
		and not IWin:IsOnCooldown("Consecration") then
			Cast("Consecration")
	end
end

function IWin:CrusaderStrike()
	if IWin:IsSpellLearnt("Crusader Strike")
		and not IWin:IsOnCooldown("Crusader Strike")
		and IWin:GetBuffRemaining("player","Zeal") < 13 then
			Cast("Crusader Strike")
	end
end

function IWin:DivineShield()
	if IWin:IsSpellLearnt("Divine Shield")
		and not IWin:IsOnCooldown("Divine Shield")
		and UnitAffectingCombat("player") then
			Cast("Divine Shield")
	end
end

function IWin:Exorcism()
	if IWin:IsSpellLearnt("Exorcism")
		and not IWin:IsOnCooldown("Exorcism")
		and (
				UnitCreatureType("target") == "undead"
				or UnitCreatureType("target") == "demon"
			) then
			Cast("Exorcism")
	end
end

function IWin:ExorcismRanged()
	if IWin:IsSpellLearnt("Exorcism")
		and not IWin:IsOnCooldown("Exorcism")
		and (
				UnitCreatureType("target") == "undead"
				or UnitCreatureType("target") == "demon"
			)
		and not IWin:IsInMeleeRange() then
			Cast("Exorcism")
	end
end

function IWin:HammerOfJustice()
	if IWin:IsSpellLearnt("Hammer of Justice")
		and not IWin:IsOnCooldown("Hammer of Justice") then
			Cast("Hammer of Justice")
	end
end

function IWin:HammerOfWrath()
	if IWin:IsSpellLearnt("Hammer of Wrath")
		and not IWin:IsOnCooldown("Hammer of Wrath")
		and IWin:IsExecutePhase() then
			Cast("Hammer of Wrath")
	end
end

function IWin:HandOfFreedom()
	if IWin:IsSpellLearnt("Hand of Freedom")
		and not IWin:IsOnCooldown("Hand of Freedom")
		and not HasFullControl() then
			Cast("Hand of Freedom")
	end
end

function IWin:HandOfReckoning()
	if IWin:IsSpellLearnt("Hand of Reckoning")
		and not IWin:IsTanking()
		and not IWin:IsOnCooldown("Hand of Reckoning")
		and not IWin:IsTaunted() then
			Cast("Hand of Reckoning")
	end
end

function IWin:Hearthstone()
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemName = GetContainerItemLink(bag, slot)
			if itemName and strfind(itemName,"Hearthstone") then
				UseContainerItem(bag, slot)
			end
		end
	end
end

function IWin:HolyShield()
	if IWin:IsSpellLearnt("Holy Shield")
		and not IWin:IsOnCooldown("Holy Shield")
		and IWin:IsShieldEquipped()
		and (
				not UnitAffectingCombat("target")
				or IWin:IsTanking()
			) then
			Cast("Holy Shield")
	end
end

function IWin:HolyStrike()
	if IWin:IsSpellLearnt("Holy Strike")
		and not IWin:IsOnCooldown("Holy Strike") then
			Cast("Holy Strike")
	end
end

function IWin:HolyWrath()
	if IWin:IsSpellLearnt("Holy Wrath")
		and not IWin:IsOnCooldown("Holy Wrath")
		and not IWin:IsTanking()
		and (
				UnitCreatureType("target") == "undead"
				or UnitCreatureType("target") == "demon"
			) then
			Cast("Holy Wrath")
	end
end

function IWin:Judgement()
	if IWin:IsSpellLearnt("Judgement")
		and not IWin:IsOnCooldown("Judgement")
		and IWin:IsSealActive()
		and not IWin:IsJudgementOverwrite("Judgement of Wisdom","Seal of Wisdom")
		and not IWin:IsJudgementOverwrite("Judgement of Light","Seal of Light")
		and not IWin:IsJudgementOverwrite("Judgement of the Crusader","Seal of the Crusader")
		and not IWin:IsJudgementOverwrite("Judgement of Justice","Seal of Justice")
		and not IWin:IsGCDActive() then
			Cast("Judgement")
	end
end

function IWin:JudgementReact()
	if IWin:IsSpellLearnt("Judgement")
		and not IWin:IsOnCooldown("Judgement")
		and IWin:IsSealActive() then
			Cast("Judgement")
	end
end

function IWin:JudgementRanged()
	if IWin:IsSpellLearnt("Judgement")
		and not IWin:IsOnCooldown("Judgement")
		and IWin:IsSealActive()
		and not IWin:IsJudgementOverwrite("Judgement of Wisdom","Seal of Wisdom")
		and not IWin:IsJudgementOverwrite("Judgement of Light","Seal of Light")
		and not IWin:IsJudgementOverwrite("Judgement of the Crusader","Seal of the Crusader")
		and not IWin:IsJudgementOverwrite("Judgement of Justice","Seal of Justice")
		and not IWin:IsGCDActive()
		and not IWin:IsInMeleeRange() then
			Cast("Judgement")
	end
end

function IWin:Purify()
	if IWin:IsSpellLearnt("Purify")
		and not IWin:IsOnCooldown("Purify")
		and not HasFullControl() then
			Cast("Purify")
	end
end

function IWin:Repentance()
	if IWin:IsSpellLearnt("Repentance")
		and not IWin:IsOnCooldown("Repentance") then
			Cast("Repentance")
	end
end

function IWin:RepentanceRaid()
	if IWin:IsSpellLearnt("Repentance")
		and not IWin:IsOnCooldown("Repentance")
		and UnitInRaid("player") then
			Cast("Repentance")
	end
end

function IWin:SealOfCommand()
	if IWin:IsSpellLearnt("Seal of Command")
		and (
				(
					IWin_CombatVar["weaponAttackSpeed"] > 3.49
					and iwinpaladinsoc == "auto"
				)
				or iwinpaladinsoc == "on"
			)
		and (
				not IWin:IsSealActive()
				or IWin:GetManaPercent("player") > 95
			) then 
			Cast("Seal of Command")
	end
end

function IWin:SealOfJustice()
	if IWin:IsSpellLearnt("Seal of Justice")
		and not IWin:IsBuffActive("target", "Judgement of Justice")
		and not IWin:IsBuffActive("player", "Seal of Justice") then 
			Cast("Seal of Justice")
	end
end

function IWin:SealOfLightElite()
	if IWin:IsSpellLearnt("Seal of Light")
		and not IWin:IsBuffActive("player","Seal of Light")
		and not IWin:IsBuffActive("target","Judgement of Light")
		and (
				IWin:IsElite()
				or (
						UnitInRaid("player")
						and not UnitExists("target")
					)
			)
		and ((
				not UnitAffectingCombat("player")
				and iwinpaladinjudgementpull == "light"
			) or (
				IWin:IsTanking()
				and iwinpaladinjudgementtank == "light"
			) or (
				not IWin:IsTanking()
				and iwinpaladinjudgementdps == "light"
			)) then
				Cast("Seal of Light")
	end
end

function IWin:SealOfRighteousness()
	if IWin:IsSpellLearnt("Seal of Righteousness")
		and (
				not IWin:IsSealActive()
				or (
						IWin:GetManaPercent("player") > 95
						and not IWin:IsBuffActive("player","Seal of Righteousness")
					)
			) then 
			Cast("Seal of Righteousness")
	end
end

function IWin:SealOfTheCrusaderElite()
	if IWin:IsSpellLearnt("Seal of the Crusader")
		and not IWin:IsBuffActive("player","Seal of the Crusader")
		and not IWin:IsBuffActive("target","Judgement of the Crusader")
		and (
				IWin:IsElite()
				or (
						UnitInRaid("player")
						and not UnitExists("target")
					)
			)
		and ((
				not UnitAffectingCombat("player")
				and iwinpaladinjudgementpull == "crusader"
			) or (
				IWin:IsTanking()
				and iwinpaladinjudgementtank == "crusader"
			) or (
				not IWin:IsTanking()
				and iwinpaladinjudgementdps == "crusader"
			)) then
				Cast("Seal of the Crusader")
	end
end

function IWin:SealOfWisdom()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and not IWin:IsBuffActive("player","Seal of Wisdom") then 
			Cast("Seal of Wisdom")
	end
end

function IWin:SealOfWisdomMana()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and not IWin:IsSealActive()
		and (
				IWin:GetManaPercent("player") < 40
				or (
						GetNumPartyMembers() == 0
						and not UnitAffectingCombat("player")
					)
			) then 
			Cast("Seal of Wisdom")
	end
end

function IWin:SealOfWisdomElite()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and not IWin:IsBuffActive("player","Seal of Wisdom")
		and not IWin:IsBuffActive("target","Judgement of Wisdom")
		and (
				IWin:IsElite()
				or (
						UnitInRaid("player")
						and not UnitExists("target")
					)
			)
		and ((
				not UnitAffectingCombat("player")
				and iwinpaladinjudgementpull == "wisdom"
			) or (
				IWin:IsTanking()
				and iwinpaladinjudgementtank == "wisdom"
			) or (
				not IWin:IsTanking()
				and iwinpaladinjudgementdps == "wisdom"
			)) then
				Cast("Seal of Wisdom")
	end
end

---- idebug button ----
SLASH_IDEBUG1 = '/idebug'
function SlashCmdList.IDEBUG()
	DEFAULT_CHAT_FRAME:AddMessage(IWin:GetBuffRemaining("player","Zeal"))
	
end

---- Judgement management ----
SLASH_IWINPALADIN1 = "/iwinpaladin"
function SlashCmdList.IWINPALADIN(command)
	if not command then return end
	local arguments = {}
	for token in string.gfind(command, "%S+") do
		table.insert(arguments, token)
	end
	if arguments[1] == "judgement" or "judgementtank" or "judgementdps" or "judgementpull" then
		if arguments[2] ~= "wisdom"
			and arguments[2] ~= "light"
			and arguments[2] ~= "crusader"
			and arguments[2] ~= nil then
				DEFAULT_CHAT_FRAME:AddMessage("Unkown judgement. Possible values: wisdom, light, crusader.")
				return
		end
	elseif arguments[1] == "soc" then
		if arguments[2] ~= "auto"
			and arguments[2] ~= "on"
			and arguments[2] ~= "off"
			and arguments[2] ~= nil then
				DEFAULT_CHAT_FRAME:AddMessage("Unkown parameter. Possible values: auto, on, off.")
				return
		end
	end
    if arguments[1] == "judgement" then
        iwinpaladinjudgementtank = arguments[2]
        iwinpaladinjudgementdps = arguments[2]
        iwinpaladinjudgementpull = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Judgement all roles: " .. iwinpaladinjudgementtank)
	elseif arguments[1] == "judgementtank" then
	    iwinpaladinjudgementtank = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Judgement tank: " .. iwinpaladinjudgementtank)
    elseif arguments[1] == "judgementdps" then
	    iwinpaladinjudgementdps = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Judgement dps: " .. iwinpaladinjudgementdps)
	elseif arguments[1] == "judgementpull" then
	    iwinpaladinjudgementpull = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Judgement pull: " .. iwinpaladinjudgementpull)
	elseif arguments[1] == "soc" then
	    iwinpaladinsoc = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Seal of Command: " .. iwinpaladinsoc)
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage:")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwinpaladin : Current setup")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwinpaladin judgement <judgementName> : Setup for all roles")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwinpaladin judgementtank [" .. iwinpaladinjudgementtank .. "] : Setup for tank roles")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwinpaladin judgementdps [" .. iwinpaladinjudgementdps .. "] : Setup for dps/offtank roles")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwinpaladin judgementpull [" .. iwinpaladinjudgementpull .. "] : Setup for prepull cast")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwinpaladin soc [" .. iwinpaladinsoc .. "] : Setup for Seal of Command")
    end
end

---- idps button ----
SLASH_IDPS1 = '/idps'
function SlashCmdList.IDPS()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	--IWin:BlessingOfKings()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:SealOfWisdomMana()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand()
	IWin:SealOfRighteousness()
	IWin:HammerOfWrath()
	IWin:ExorcismRanged()
	IWin:JudgementRanged()
	IWin:CrusaderStrike()
	IWin:HolyStrike()
	IWin:Exorcism()
	IWin:Judgement()
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- icleave button ----
SLASH_ICLEAVE1 = '/icleave'
function SlashCmdList.ICLEAVE()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	--IWin:BlessingOfKings()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:HolyShield()
	IWin:SealOfWisdomMana()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand()
	IWin:SealOfRighteousness()
	IWin:Consecration()
	IWin:HammerOfWrath()
	IWin:HolyWrath()
	IWin:JudgementRanged()
	IWin:CrusaderStrike()
	IWin:HolyStrike()
	IWin:Judgement()
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- ichase button ----
SLASH_ICHASE1 = '/ichase'
function SlashCmdList.ICHASE()
	IWin:TargetEnemy()
	IWin:HandOfFreedom()
	IWin:SealOfJustice()
	IWin:JudgementReact()
	IWin:Cleanse()
	IWin:Purify()
	IWin:StartAttack()
end

---- istun button ----
SLASH_ISTUN1 = '/istun'
function SlashCmdList.ISTUN()
	IWin:TargetEnemy()
	IWin:HammerOfJustice()
	IWin:StartAttack()
	IWin:Repentance()
end

---- itaunt button ----
SLASH_ITAUNT1 = '/itaunt'
function SlashCmdList.ITAUNT()
	IWin:TargetEnemy()
	IWin:HandOfReckoning()
	IWin:StartAttack()
end

---- ibubblehearth button ----
SLASH_IBUBBLEHEARTH1 = '/ibubblehearth'
function SlashCmdList.IBUBBLEHEARTH()
	IWin:DivineShield()
	IWin:Hearthstone()
end