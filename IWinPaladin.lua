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
IWin_CombatVar = {
	["gcd"] = 0,
	["weaponAttackSpeed"] = 0,
}
local Cast = CastSpellByName
IWin.hasPallyPower = PallyPower_SealAssignments and true or false

---- Event Register ----
IWin:RegisterEvent("ACTIONBAR_UPDATE_COOLDOWN")
IWin:RegisterEvent("ADDON_LOADED")
IWin:RegisterEvent("UNIT_INVENTORY_CHANGED")
IWin:SetScript("OnEvent", function()
	if event == "ADDON_LOADED" and arg1 == "IWinPaladin" then
		DEFAULT_CHAT_FRAME:AddMessage("|cff0066ff IWinPaladin system loaded.|r")
		if IWin_Settings == nil then
			IWin_Settings = {
				["judgement"] = "wisdom",
				["soc"] = "auto",
				["outOfRaidCombatLength"] = 25,
				["playerToNPCHealthRatio"] = 0.75,
			}
		end
		IWin_CombatVar["weaponAttackSpeed"] = UnitAttackSpeed("player")
		IWin.hasSuperwow = SetAutoloot and true or false
		--IWin:UnregisterEvent("ADDON_LOADED")
	elseif event == "ADDON_LOADED" and arg1 == "PallyPowerTW" then
		IWin.hasPallyPower = PallyPower_SealAssignments and true or false
	elseif event == "ACTIONBAR_UPDATE_COOLDOWN" and arg1 == nil then
		IWin_CombatVar["gcd"] = GetTime()
	elseif event == "UNIT_INVENTORY_CHANGED" and arg1 == "player" then
		IWin_CombatVar["weaponAttackSpeed"] = UnitAttackSpeed("player") * (1 + IWin:GetBuffStack("player","Zeal") * 0.05)
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
		return stack or 0
	end
	local index = IWin:GetDebuffIndex(unit, spell)
	if index then
		local _, stack = UnitDebuff(unit, index)
		return stack or 0
	end
	return 0
end

function IWin:IsBuffStack(unit, spell, stack)
	return IWin:GetBuffStack(unit, spell) == stack
end

function IWin:IsBuffActive(unit, spell)
	return IWin:GetBuffRemaining(unit, spell) ~= 0
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

function IWin:GetTimeToDie()
	local ttd = 0
	if UnitInRaid("player") then
		ttd = 999
	elseif GetNumPartyMembers ~= 0 then
		ttd = UnitHealth("target") / UnitHealthMax("player") * IWin_Settings["playerToNPCHealthRatio"] * IWin_Settings["outOfRaidCombatLength"] / GetNumPartyMembers() * 2
	else
		ttd = UnitHealth("target") / UnitHealthMax("player") * IWin_Settings["playerToNPCHealthRatio"] * IWin_Settings["outOfRaidCombatLength"]
	end
	return ttd
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

function IWin:IsInRange(spell)
	if not IsSpellInRange then
        return CheckInteractDistance("target", 3) ~= nil
	else
		return IsSpellInRange(spell, "target") == 1
	end
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

---- General Actions ----
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
	if not attackActionFound
		and not PlayerFrame.inCombat then
			AttackTarget()
	end
end

function IWin:MarkSkull()
	if GetRaidTargetIndex("target") ~= 8
		and not UnitIsFriend("player", "target")
		and not UnitInRaid("player")
		and GetNumPartyMembers() ~= 0 then
			SetRaidTarget("target", 8)
	end
end

---- Class Actions ----
function IWin:BlessingOfKings()
	if IWin:IsSpellLearnt("Blessing of Kings")
		and not IWin:IsBuffActive("player","Blessing of Kings")
		and IWin.hasPallyPower
		and PallyPower_Assignments[UnitName("player")][4] == 4 then
			Cast("Blessing of Kings")
	end
end

function IWin:BlessingOfLight()
	if IWin:IsSpellLearnt("Blessing of Light")
		and not IWin:IsBuffActive("player","Blessing of Light")
		and IWin.hasPallyPower
		and PallyPower_Assignments[UnitName("player")][4] == 3 then
			Cast("Blessing of Light")
	end
end

function IWin:BlessingOfMight()
	if IWin:IsSpellLearnt("Blessing of Might")
		and (
				(
					not IWin.hasPallyPower
					and not IWin:IsBlessingActive()
				)
			or (
					IWin.hasPallyPower
					and PallyPower_Assignments[UnitName("player")][4] == 1
					and not IWin:IsBuffActive("player","Blessing of Might")
				)
			) then
			Cast("Blessing of Might")
	end
end

function IWin:BlessingOfSalvation()
	if IWin:IsSpellLearnt("Blessing of Salvation")
		and not IWin:IsBuffActive("player","Blessing of Salvation")
		and IWin.hasPallyPower
		and PallyPower_Assignments[UnitName("player")][4] == 2 then
			Cast("Blessing of Salvation")
	end
end

function IWin:BlessingOfSanctuary()
	if IWin:IsSpellLearnt("Blessing of Sanctuary")
		and not IWin:IsBuffActive("player","Blessing of Sanctuary")
		and (
				not IWin.hasPallyPower
				or PallyPower_Assignments[UnitName("player")][4] == 5
			) then
			Cast("Blessing of Sanctuary")
	end
end

function IWin:BlessingOfWisdom()
	if IWin:IsSpellLearnt("Blessing of Wisdom")
		and (
				(
					not IWin.hasPallyPower
					and not IWin:IsBlessingActive()
				)
			or (
					IWin.hasPallyPower
					and PallyPower_Assignments[UnitName("player")][4] == 0
					and not IWin:IsBuffActive("player","Blessing of Wisdom")
				)
			) then
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
		and IWin:GetManaPercent("player") > 50
		and IWin:IsInRange("Judgement")
		and not IWin:IsOnCooldown("Consecration") then
			Cast("Consecration")
	end
end

function IWin:CrusaderStrike()
	if IWin:IsSpellLearnt("Crusader Strike")
		and not IWin:IsOnCooldown("Crusader Strike")
		and IWin:GetManaPercent("player") > 15
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
		and IWin:GetManaPercent("player") > 30
		and (
				UnitCreatureType("target") == "Undead"
				or UnitCreatureType("target") == "Demon"
			) then
			Cast("Exorcism")
	end
end

function IWin:ExorcismRanged()
	if IWin:IsSpellLearnt("Exorcism")
		and not IWin:IsOnCooldown("Exorcism")
		and IWin:GetManaPercent("player") > 30
		and (
				UnitCreatureType("target") == "Undead"
				or UnitCreatureType("target") == "Demon"
			)
		and not IWin:IsInRange("Holy Strike") then
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
		and (
				(
					IWin:IsElite()
					and not IWin:IsTanking()
					and IWin:GetManaPercent("player") > 30
				)
				or UnitIsPVP("target")
			)
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
				UnitCreatureType("target") == "Undead"
				or UnitCreatureType("target") == "Demon"
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
		and (
				IWin:GetTimeToDie() > 10
				or IWin:IsBuffActive("player","Seal of Righteousness")
				or IWin:IsBuffActive("player","Seal of Command")
			)
		and (
				(
					not IWin:IsBuffActive("player","Seal of Righteousness")
					and not IWin:IsBuffActive("player","Seal of Command")
				)
				or IWin:GetBuffRemaining("player","Seal of Righteousness") < 5
				or IWin:GetBuffRemaining("player","Seal of Command") < 5
				or IWin:GetManaPercent("player") > 50
			)
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
		and (
				IWin:GetTimeToDie() > 10
				or IWin:IsBuffActive("player","Seal of Righteousness")
				or IWin:IsBuffActive("player","Seal of Command")
			)
		and not IWin:IsGCDActive()
		and not IWin:IsInRange("Holy Strike") then
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
					and IWin_Settings["soc"] == "auto"
				)
				or IWin_Settings["soc"] == "on"
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
				IWin.hasPallyPower
				and PallyPower_SealAssignments[UnitName("player")] == 2
			) or (
				not IWin.hasPallyPower
				and IWin_Settings["judgement"] == "light"
			)) then
				Cast("Seal of Light")
	end
end

function IWin:SealOfLightSolo()
	if IWin:IsSpellLearnt("Seal of Light")
		and not IWin:IsSealActive()
		and GetNumPartyMembers() == 0
		and IWin:IsBuffActive("target","Judgement of Wisdom") then 
			Cast("Seal of Light")
	end
end

function IWin:SealOfRighteousness()
	if IWin:IsSpellLearnt("Seal of Righteousness")
		and IWin:GetManaPercent("player") > 15
		and (
				not IWin:IsSealActive()
				or (
						IWin:GetManaPercent("player") > 95
						and not IWin:IsBuffActive("player","Seal of Righteousness")
						and IWin:IsBuffActive("target","Judgement of Wisdom")
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
				IWin.hasPallyPower
				and PallyPower_SealAssignments[UnitName("player")] == 1
			) or (
				not IWin.hasPallyPower
				and IWin_Settings["judgement"] == "crusader"
			)) then
				Cast("Seal of the Crusader")
	end
end

function IWin:SealOfWisdom()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and not IWin:IsSealActive()
		and (
				IWin:GetManaPercent("player") < 30
				or (
						IWin:GetManaPercent("player") < 70
						and not IWin:IsBuffActive("target","Judgement of Wisdom")
						and IWin:GetTimeToDie() > 20
					)
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
				IWin.hasPallyPower
				and PallyPower_SealAssignments[UnitName("player")] == 0
			) or (
				not IWin.hasPallyPower
				and IWin_Settings["judgement"] == "wisdom"
			)) then
				Cast("Seal of Wisdom")
	end
end

function IWin:SealOfWisdomEco()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and not IWin:IsSealActive() then 
			Cast("Seal of Wisdom")
	end
end

---- idebug button ----
SLASH_IDEBUG1 = '/idebug'
function SlashCmdList.IDEBUG()
	DEFAULT_CHAT_FRAME:AddMessage(IWin:GetBuffRemaining("player","Zeal"))
	
end

---- commands ----
SLASH_IWIN1 = "/iwin"
function SlashCmdList.IWIN(command)
	if not command then return end
	local arguments = {}
	for token in string.gfind(command, "%S+") do
		table.insert(arguments, token)
	end
	if arguments[1] == "judgement"then
		if IWin.hasPallyPower then
			DEFAULT_CHAT_FRAME:AddMessage("Judgements are managed by your Pally Power.")
			return
		elseif arguments[2] ~= "wisdom"
			and arguments[2] ~= "light"
			and arguments[2] ~= "crusader"
			and arguments[2] ~= "off"
			and arguments[2] ~= nil then
				DEFAULT_CHAT_FRAME:AddMessage("Unkown judgement. Possible values: wisdom, light, crusader, off.")
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
        IWin_Settings["judgement"] = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Judgement: " .. IWin_Settings["judgement"])
	elseif arguments[1] == "soc" then
	    IWin_Settings["soc"] = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Seal of Command: " .. IWin_Settings["soc"])
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage:")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwin : Current setup")
		if IWin.hasPallyPower then
			DEFAULT_CHAT_FRAME:AddMessage("Judgements managed by PallyPowerTW")
		else
			DEFAULT_CHAT_FRAME:AddMessage(" /iwin judgement [" .. IWin_Settings["judgement"] .. "] : Setup for Judgement on elites and worldbosses")
		end
		DEFAULT_CHAT_FRAME:AddMessage(" /iwin soc [" .. IWin_Settings["soc"] .. "] : Setup for Seal of Command")
    end
end

---- idps button ----
SLASH_IDPS1 = '/idps'
function SlashCmdList.IDPS()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:SealOfWisdom()
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
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:HolyShield()
	IWin:SealOfWisdom()
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

---- itank button ----
SLASH_ITANK1 = '/itank'
function SlashCmdList.ITANK()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:HolyShield()
	IWin:SealOfWisdom()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand()
	IWin:SealOfRighteousness()
	IWin:ExorcismRanged()
	IWin:JudgementRanged()
	IWin:HolyStrike()
	IWin:Consecration()
	IWin:Exorcism()
	IWin:Judgement()
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- ihodor button ----
SLASH_IHODOR1 = '/ihodor'
function SlashCmdList.IHODOR()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:Consecration()
	IWin:HolyShield()
	IWin:SealOfWisdom()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfLightSolo()
	IWin:SealOfWisdomEco()
	IWin:ExorcismRanged()
	IWin:JudgementRanged()
	IWin:HolyStrike()
	IWin:Exorcism()
	IWin:Judgement()
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- ieco button ----
SLASH_IECO1 = '/ieco'
function SlashCmdList.IECO()
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:SealOfWisdom()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfWisdomEco()
	IWin:JudgementRanged()
	IWin:HolyStrike()
	IWin:Judgement()
	IWin:StartAttack()
end

---- ijudge button ----
SLASH_IJUDGE1 = '/ijudge'
function SlashCmdList.IJUDGE()
	IWin:TargetEnemy()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand()
	IWin:SealOfRighteousness()
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