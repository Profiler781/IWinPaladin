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
}
local Cast = CastSpellByName

---- Event Register ----
IWin:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
IWin:RegisterEvent("ADDON_LOADED")
IWin:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 == "IWinPaladin" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff IWinPaladin system loaded.|r")
		IWin:UnregisterEvent("ADDON_LOADED")
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" and arg1 == nil then
		IWin_CombatVar["gcd"] = GetTime()
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
			return GetPlayerBuffTimeLeft(index - 2)
		end
		local index = IWin:GetDebuffIndex(unit, spell)
		if index then
			return GetPlayerBuffTimeLeft(index - 2)
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

function IWin:IsJudgementActive()
	return IWin:IsBuffActive("target","Judgement of Wisdom")
		or IWin:IsBuffActive("target","Judgement of Light")
		or IWin:IsBuffActive("target","Judgement of Justice")
		or IWin:IsBuffActive("target","Judgement of the Crusader")
end

function IWin:IsJudgementOverwrite()
	return IWin:IsJudgementActive()
		and not IWin:IsBuffActive("player","Seal of Righteousness")
		and not IWin:IsBuffActive("player","Seal of Command")
end

function IWin:IsBlessingActive()
	return IWin:IsBuffActive("player","Blessing of Sanctuary")
		or IWin:IsBuffActive("player","Blessing of Power")
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

function IWin:BlessingOfPower()
	if IWin:IsSpellLearnt("Blessing of Power")
		and not IWin:IsBlessingActive() then
			Cast("Blessing of Power")
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
		and not IWin:IsJudgementOverwrite()
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
		and not IWin:IsJudgementOverwrite()
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

function IWin:SealOfCommand()
	if IWin:IsSpellLearnt("Seal of Command")
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

function IWin:SealOfLightWorldboss()
	if IWin:IsSpellLearnt("Seal of Light")
		and not IWin:IsSealActive()
		and not IWin:IsBuffActive("target","Judgement of Light")
		and UnitClassification("target") == "worldboss" then 
			Cast("Seal of Light")
	end
end

function IWin:SealOfRighteousness()
	if IWin:IsSpellLearnt("Seal of Righteousness")
		and (
				not IWin:IsSealActive()
				or IWin:GetManaPercent("player") > 95
			) then 
			Cast("Seal of Righteousness")
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
				or not UnitAffectingCombat("player")
			) then 
			Cast("Seal of Wisdom")
	end
end

function IWin:SealOfWisdomElite()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and not IWin:IsBuffActive("player","Seal of Wisdom")
		and not IWin:IsBuffActive("target","Judgement of Wisdom")
		and IWin:IsElite() then 
			Cast("Seal of Wisdom")
	end
end

---- idebug button ----
SLASH_IDEBUG1 = '/idebug'
function SlashCmdList.IDEBUG()
	DEFAULT_CHAT_FRAME:AddMessage(IWin:GetBuffRemaining("player","Zeal"))
	
end

---- idps button ----
SLASH_IDPS1 = '/idps'
function SlashCmdList.IDPS()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfKings()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfPower()
	IWin:SealOfWisdomMana()
	IWin:SealOfWisdomElite()
	--IWin:SealOfLightWorldboss()
	IWin:SealOfCommand()
	IWin:SealOfRighteousness()
	IWin:ExorcismRanged()
	IWin:JudgementRanged()
	IWin:CrusaderStrike()
	IWin:HolyStrike()
	IWin:Exorcism()
	IWin:Judgement()
	IWin:StartAttack()
end

---- icleave button ----
SLASH_ICLEAVE1 = '/icleave'
function SlashCmdList.ICLEAVE()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfKings()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfPower()
	IWin:HolyShield()
	IWin:Consecration()
	IWin:SealOfWisdom()
	IWin:HolyWrath()
	IWin:JudgementRanged()
	IWin:CrusaderStrike()
	IWin:HolyStrike()
	IWin:Judgement()
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
	IWin:Repentance()
	IWin:StartAttack()
end

---- itaunt button ----
SLASH_ITAUNT1 = '/itaunt'
function SlashCmdList.ITAUNT()
	IWin:TargetEnemy()
	IWin:HandOfReckoning()
	IWin:StartAttack()
end