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
	["queueGCD"] = true,
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
		if IWin_Paladin == nil then IWin_Paladin = {} end
		if IWin_Paladin["judgement"] == nil then IWin_Paladin["judgement"] = "wisdom" end
		if IWin_Paladin["soc"] == nil then IWin_Paladin["soc"] = "auto" end
		if IWin_Paladin["outOfRaidCombatLength"] == nil then IWin_Paladin["outOfRaidCombatLength"] = 25 end
		if IWin_Paladin["playerToNPCHealthRatio"] == nil then IWin_Paladin["playerToNPCHealthRatio"] = 0.75 end
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

IWin_DrinkVendor = {
	["Hyjal Nectar"] = 55,
	["Morning Glory Dew"] = 45,
	["Freshly-Squeezed Lemonade"] = 45,
	["Bottled Winterspring Water"] = 35,
	["Moonberry Juice"] = 35,
	["Enchanted Water"] = 25,
	["Goldthorn Tea"] = 25,
	["Green Garden Tea"] = 25,
	["Sweet Nectar"] = 25,
	["Bubbling Water"] = 15,
	["Fizzy Faire Drink"] = 15,
	["Melon Juice"] = 15,
	["Blended Bean Brew"] = 5,
	["Ice Cold Milk"] = 5,
	["Kaja'Cola"] = 1,
	["Refreshing Spring Water"] = 1,
	["Sun-Parched Waterskin"] = 1,
}

IWin_DrinkConjured = {
	["Conjured Crystal Water"] = 55,
	["Conjured Sparkling Water"] = 45,
	["Conjured Mineral Water"] = 35,
	["Conjured Spring Water"] = 25,
	["Conjured Purified Water"] = 15,
	["Conjured Fresh Water"] = 5,
	["Conjured Water"] = 1,
}

function IWin:GetTalentRank(tabIndex, talentIndex)
	local _, _, _, _, currentRank = GetTalentInfo(tabIndex, talentIndex)
	return currentRank
end

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
	if UnitInRaid("player") or UnitIsPVP("target") then
		ttd = 999
	elseif GetNumPartyMembers() ~= 0 then
		ttd = UnitHealth("target") / UnitHealthMax("player") * IWin_Paladin["playerToNPCHealthRatio"] * IWin_Paladin["outOfRaidCombatLength"] / GetNumPartyMembers() * 2
	else
		ttd = UnitHealth("target") / UnitHealthMax("player") * IWin_Paladin["playerToNPCHealthRatio"] * IWin_Paladin["outOfRaidCombatLength"]
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
	if not IsSpellInRange
		or not spell
		or not IWin:IsSpellLearnt(spell) then
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

function IWin:IsJudgementActive()
	return IWin:IsBuffActive("target","Judgement of Wisdom")
		or IWin:IsBuffActive("target","Judgement of Light")
		or IWin:IsBuffActive("target","Judgement of Justice")
		or IWin:IsBuffActive("target","Judgement of the Crusader")
end

function IWin:IsAuraActive()
	return IWin:IsStanceActive("Devotion Aura")
		or IWin:IsStanceActive("Retribution Aura")
		or IWin:IsStanceActive("Concentration Aura")
		or IWin:IsStanceActive("Shadow Resistance Aura")
		or IWin:IsStanceActive("Frost Resistance Aura")
		or IWin:IsStanceActive("Fire Resistance Aura")
		or IWin:IsStanceActive("Sanctity Aura")
end

function IWin:IsBlessingActive()
	return IWin:IsBuffActive("player","Blessing of Sanctuary")
		or IWin:IsBuffActive("player","Greater Blessing of Sanctuary")
		or IWin:IsBuffActive("player","Blessing of Might")
		or IWin:IsBuffActive("player","Greater Blessing of Might")
		or IWin:IsBuffActive("player","Blessing of Wisdom")
		or IWin:IsBuffActive("player","Greater Blessing of Wisdom")
		or IWin:IsBuffActive("player","Blessing of Light")
		or IWin:IsBuffActive("player","Greater Blessing of Light")
		or IWin:IsBuffActive("player","Blessing of Kings")
		or IWin:IsBuffActive("player","Greater Blessing of Kings")
		or IWin:IsBuffActive("player","Blessing of Salvation")
		or IWin:IsBuffActive("player","Greater Blessing of Salvation")
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

function IWin:CancelPlayerBuff(spell)
	local index = IWin:GetBuffIndex("player", spell)
	if index then
		CancelPlayerBuff(index)
	end
end

function IWin:CancelSalvation()
	IWin:CancelPlayerBuff("Blessing of Salvation")
	IWin:CancelPlayerBuff("Greater Blessing of Salvation")
end

function IWin:UseItem(item)
	for bag = 0, 4 do
		for slot = 1, GetContainerNumSlots(bag) do
			local itemName = GetContainerItemLink(bag, slot)
			if itemName and strfind(itemName,item) then
				UseContainerItem(bag, slot)
			end
		end
	end
end

function IWin:UseItemBuff(item, buff)
	if not IWin:IsBuffActive("player", buff) then
		IWin:UseItem(item)
	end
end

function IWin:UseDrinkItem()
	local playerLevel = UnitLevel("player")
	for drinkItem in IWin_DrinkConjured do
		if IWin:IsBuffActive("player", "Drink") then break end
		if playerLevel >= IWin_DrinkConjured[drinkItem] then
			IWin:UseItem(drinkItem)
		end
	end
	for drinkItem in IWin_DrinkVendor do
		if IWin:IsBuffActive("player", "Drink") then break end
		if playerLevel >= IWin_DrinkVendor[drinkItem] then
			IWin:UseItem(drinkItem)
		end
	end
end

---- Class Actions ----
function IWin:BlessingOfKings()
	if IWin:IsSpellLearnt("Blessing of Kings")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsBuffActive("player","Blessing of Kings")
		and not IWin:IsBuffActive("player","Greater Blessing of Kings")
		and GetNumPartyMembers() == 0
		and IWin.hasPallyPower
		and PallyPower_Assignments[UnitName("player")][4] == 4 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Blessing of Kings")
	end
end

function IWin:BlessingOfLight()
	if IWin:IsSpellLearnt("Blessing of Light")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsBuffActive("player","Blessing of Light")
		and not IWin:IsBuffActive("player","Greater Blessing of Light")
		and GetNumPartyMembers() == 0
		and IWin.hasPallyPower
		and PallyPower_Assignments[UnitName("player")][4] == 3 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Blessing of Light")
	end
end

function IWin:BlessingOfMight()
	if IWin:IsSpellLearnt("Blessing of Might")
		and IWin_CombatVar["queueGCD"]
		and GetNumPartyMembers() == 0
		and (
				(
					not IWin.hasPallyPower
					and not IWin:IsBlessingActive()
				)
			or (
					IWin.hasPallyPower
					and PallyPower_Assignments[UnitName("player")][4] == 1
					and not IWin:IsBuffActive("player","Blessing of Might")
					and not IWin:IsBuffActive("player","Greater Blessing of Might")
				)
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Blessing of Might")
	end
end

function IWin:BlessingOfSalvation()
	if IWin:IsSpellLearnt("Blessing of Salvation")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsBuffActive("player","Blessing of Salvation")
		and not IWin:IsBuffActive("player","Greater Blessing of Salvation")
		and GetNumPartyMembers() == 0
		and IWin.hasPallyPower
		and PallyPower_Assignments[UnitName("player")][4] == 2 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Blessing of Salvation")
	end
end

function IWin:BlessingOfSanctuary()
	if IWin:IsSpellLearnt("Blessing of Sanctuary")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsBuffActive("player","Blessing of Sanctuary")
		and not IWin:IsBuffActive("player","Greater Blessing of Sanctuary")
		and GetNumPartyMembers() == 0
		and (
				not IWin.hasPallyPower
				or PallyPower_Assignments[UnitName("player")][4] == 5
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Blessing of Sanctuary")
	end
end

function IWin:BlessingOfWisdom()
	if IWin:IsSpellLearnt("Blessing of Wisdom")
		and IWin_CombatVar["queueGCD"]
		and GetNumPartyMembers() == 0
		and (
				(
					not IWin.hasPallyPower
					and not IWin:IsBlessingActive()
				)
			or (
					IWin.hasPallyPower
					and PallyPower_Assignments[UnitName("player")][4] == 0
					and not IWin:IsBuffActive("player","Blessing of Wisdom")
					and not IWin:IsBuffActive("player","Greater Blessing of Wisdom")
				)
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Blessing of Wisdom")
	end
end

function IWin:Cleanse()
	if IWin:IsSpellLearnt("Cleanse")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Cleanse")
		and not HasFullControl() then
			IWin_CombatVar["queueGCD"] = false
			Cast("Cleanse")
	end
end

function IWin:ConcentrationAura()
	if IWin:IsSpellLearnt("Concentration Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and IWin.hasPallyPower
		and PallyPower_AuraAssignments[UnitName("player")] == 2 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Concentration Aura")
	end
end

function IWin:Consecration(manaPercent)
	if IWin:IsSpellLearnt("Consecration")
		and IWin_CombatVar["queueGCD"]
		and IWin:GetManaPercent("player") > manaPercent
		and not IWin:IsOnCooldown("Consecration") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Consecration")
	end
end

function IWin:CrusaderStrike(manaPercent)
	if IWin:IsSpellLearnt("Crusader Strike")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Crusader Strike")
		and IWin:GetManaPercent("player") > manaPercent
		and (
				IWin:GetBuffRemaining("player","Zeal") < 13
				or IWin:GetManaPercent("player") > 80
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Crusader Strike")
	end
end

function IWin:DevotionAura()
	if IWin:IsSpellLearnt("Devotion Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and IWin.hasPallyPower
		and PallyPower_AuraAssignments[UnitName("player")] == 0 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Devotion Aura")
	end
end

function IWin:DivineShield()
	if IWin:IsSpellLearnt("Divine Shield")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Divine Shield")
		and UnitAffectingCombat("player") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Divine Shield")
	end
end

function IWin:Exorcism(manaPercent)
	if IWin:IsSpellLearnt("Exorcism")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Exorcism")
		and IWin:GetManaPercent("player") > manaPercent
		and (
				UnitCreatureType("target") == "Undead"
				or UnitCreatureType("target") == "Demon"
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Exorcism")
	end
end

function IWin:ExorcismRanged(manaPercent)
	if IWin:IsSpellLearnt("Exorcism")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Exorcism")
		and IWin:GetManaPercent("player") > manaPercent
		and (
				UnitCreatureType("target") == "Undead"
				or UnitCreatureType("target") == "Demon"
			)
		and not IWin:IsInRange("Holy Strike") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Exorcism")
	end
end

function IWin:FireResistanceAura()
	if IWin:IsSpellLearnt("Fire Resistance Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and IWin.hasPallyPower
		and PallyPower_AuraAssignments[UnitName("player")] == 5 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Fire Resistance Aura")
	end
end

function IWin:FrostResistanceAura()
	if IWin:IsSpellLearnt("Frost Resistance Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and IWin.hasPallyPower
		and PallyPower_AuraAssignments[UnitName("player")] == 4 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Frost Resistance Aura")
	end
end

function IWin:HammerOfJustice()
	if IWin:IsSpellLearnt("Hammer of Justice")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Hammer of Justice") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Hammer of Justice")
	end
end

function IWin:HammerOfWrath(manaPercent)
	if IWin:IsSpellLearnt("Hammer of Wrath")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Hammer of Wrath")
		and (
				(
					IWin:IsElite()
					and not IWin:IsTanking()
					and IWin:GetManaPercent("player") > manaPercent
				)
				or UnitIsPVP("target")
			)
		and IWin:IsExecutePhase()
		and (
				not st_timer
				or st_timer > UnitAttackSpeed("player") * 0.9
				or st_timer > 1
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Hammer of Wrath")
	end
end

function IWin:HandOfFreedom()
	if IWin:IsSpellLearnt("Hand of Freedom")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Hand of Freedom")
		and not HasFullControl() then
			IWin_CombatVar["queueGCD"] = false
			Cast("Hand of Freedom")
	end
end

function IWin:HandOfReckoning()
	if IWin:IsSpellLearnt("Hand of Reckoning")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsTanking()
		and not IWin:IsOnCooldown("Hand of Reckoning")
		and not IWin:IsTaunted() then
			IWin_CombatVar["queueGCD"] = false
			Cast("Hand of Reckoning")
	end
end

function IWin:HolyShield(manaPercent)
	if IWin:IsSpellLearnt("Holy Shield")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Holy Shield")
		and IWin:GetManaPercent("player") > manaPercent
		and IWin:IsShieldEquipped()
		and (
				not UnitAffectingCombat("target")
				or IWin:IsTanking()
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Holy Shield")
	end
end

function IWin:HolyShock(manaPercent)
	if IWin:IsSpellLearnt("Holy Shock")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Holy Shock")
		and IWin:IsTanking()
		and IWin:GetHealthPercent("player") < 80
		and IWin:GetManaPercent("player") > manaPercent then
			IWin_CombatVar["queueGCD"] = false
			Cast("Holy Shock","player")
	end
end

function IWin:HolyShockPull(manaPercent)
	if IWin:IsSpellLearnt("Holy Shock")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Holy Shock")
		and IWin:GetManaPercent("player") > manaPercent
		and not UnitAffectingCombat("target") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Holy Shock")
	end
end

function IWin:HolyStrike()
	if IWin:IsSpellLearnt("Holy Strike")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Holy Strike") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Holy Strike")
	end
end

function IWin:HolyStrikeHolyMight()
	if IWin:IsSpellLearnt("Holy Strike")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Holy Strike")
		and not IWin:IsBuffActive("player","Holy Might")
		and IWin:GetTalentRank(3 ,15) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Holy Strike")
	end
end

function IWin:HolyWrath()
	if IWin:IsSpellLearnt("Holy Wrath")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Holy Wrath")
		and not IWin:IsTanking()
		and (
				UnitCreatureType("target") == "Undead"
				or UnitCreatureType("target") == "Demon"
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Holy Wrath")
	end
end

function IWin:Judgement(manaPercent)
	if IWin:IsSpellLearnt("Judgement")
		and not IWin:IsOnCooldown("Judgement")
		and IWin:IsSealActive()
		and (
				(
					IWin:GetTalentRank(1, 3) == 3
					and not IWin:IsBuffStack("player","Holy Judgement",1)
				)
				or (
					not IWin:IsJudgementOverwrite("Judgement of Wisdom","Seal of Wisdom")
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
							or IWin:GetManaPercent("player") > manaPercent
						)
					and not (
								IWin:IsJudgementActive()
								and IWin:IsBuffActive("player","Seal of Light")
								and GetNumPartyMembers() == 0
							)
					)
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
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Purify")
		and not HasFullControl() then
			IWin_CombatVar["queueGCD"] = false
			Cast("Purify")
	end
end

function IWin:Repentance()
	if IWin:IsSpellLearnt("Repentance")
		and not IWin:IsOnCooldown("Repentance") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Repentance")
	end
end

function IWin:RepentanceRaid()
	if IWin:IsSpellLearnt("Repentance")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsOnCooldown("Repentance")
		and UnitInRaid("player") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Repentance")
	end
end

function IWin:RetributionAura()
	if IWin:IsSpellLearnt("Retribution Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and (
				(
					IWin.hasPallyPower
					and PallyPower_AuraAssignments[UnitName("player")] == 1
				)
				or not IWin.hasPallyPower
			) then
				IWin_CombatVar["queueGCD"] = false
				Cast("Retribution Aura")
	end
end

function IWin:RighteousFury()
	if IWin:IsSpellLearnt("Righteous Fury")
		and IWin_CombatVar["queueGCD"]
		and IWin:IsBuffStack("player","Righteous Fury",0) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Righteous Fury")
	end
end

function IWin:SanctityAura()
	if IWin:IsSpellLearnt("Sanctity Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and IWin.hasPallyPower
		and PallyPower_AuraAssignments[UnitName("player")] == 6 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Sanctity Aura")
	end
end

function IWin:SealOfCommand(manaPercent)
	if IWin:IsSpellLearnt("Seal of Command")
		and IWin_CombatVar["queueGCD"]
		and IWin:GetManaPercent("player") > manaPercent
		and (
				(
					IWin_CombatVar["weaponAttackSpeed"] > 3.49
					and IWin_Paladin["soc"] == "auto"
				)
				or IWin_Paladin["soc"] == "on"
			)
		and (
				not IWin:IsSealActive()
				or IWin:GetManaPercent("player") > 95
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Seal of Command")
	end
end

function IWin:SealOfJustice()
	if IWin:IsSpellLearnt("Seal of Justice")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsBuffActive("target", "Judgement of Justice")
		and not IWin:IsBuffActive("player", "Seal of Justice") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Seal of Justice")
	end
end

function IWin:SealOfLightElite()
	if IWin:IsSpellLearnt("Seal of Light")
		and IWin_CombatVar["queueGCD"]
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
				and IWin_Paladin["judgement"] == "light"
			)) then
				IWin_CombatVar["queueGCD"] = false
				Cast("Seal of Light")
	end
end

function IWin:SealOfLightSolo()
	if IWin:IsSpellLearnt("Seal of Light")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsSealActive()
		and GetNumPartyMembers() == 0
		and IWin:IsBuffActive("target","Judgement of Wisdom") then
			IWin_CombatVar["queueGCD"] = false
			Cast("Seal of Light")
	end
end

function IWin:SealOfRighteousness(manaPercent)
	if IWin:IsSpellLearnt("Seal of Righteousness")
		and IWin_CombatVar["queueGCD"]
		and IWin:GetManaPercent("player") > manaPercent
		and (
				not IWin:IsSealActive()
				or (
						IWin:GetManaPercent("player") > 95
						and not IWin:IsBuffActive("player","Seal of Righteousness")
						and IWin:IsBuffActive("target","Judgement of Wisdom")
					)
			) then
			IWin_CombatVar["queueGCD"] = false
			Cast("Seal of Righteousness")
	end
end

function IWin:SealOfTheCrusaderElite()
	if IWin:IsSpellLearnt("Seal of the Crusader")
		and IWin_CombatVar["queueGCD"]
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
				and IWin_Paladin["judgement"] == "crusader"
			)) then
				IWin_CombatVar["queueGCD"] = false
				Cast("Seal of the Crusader")
	end
end

function IWin:SealOfWisdom()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsSealActive()
		and (
				IWin:GetManaPercent("player") < 30
				or (
						IWin:GetManaPercent("player") < 70
						and not IWin:IsBuffActive("target","Judgement of Wisdom")
						and IWin:GetTimeToDie() > 20
						and not IWin:IsElite()
					)
				or (
						GetNumPartyMembers() == 0
						and not IWin:IsElite()
						and not UnitAffectingCombat("player")
					)
			) then
				IWin_CombatVar["queueGCD"] = false
				Cast("Seal of Wisdom")
	end
end

function IWin:SealOfWisdomElite()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and IWin_CombatVar["queueGCD"]
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
				and IWin_Paladin["judgement"] == "wisdom"
			)) then
				IWin_CombatVar["queueGCD"] = false
				Cast("Seal of Wisdom")
	end
end

function IWin:SealOfWisdomEco()
	if IWin:IsSpellLearnt("Seal of Wisdom")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsSealActive() then
			IWin_CombatVar["queueGCD"] = false
			Cast("Seal of Wisdom")
	end
end

function IWin:ShadowResistanceAura()
	if IWin:IsSpellLearnt("Shadow Resistance Aura")
		and IWin_CombatVar["queueGCD"]
		and not IWin:IsAuraActive()
		and IWin.hasPallyPower
		and PallyPower_AuraAssignments[UnitName("player")] == 3 then
			IWin_CombatVar["queueGCD"] = false
			Cast("Shadow Resistance Aura")
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
        IWin_Paladin["judgement"] = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Judgement: " .. IWin_Paladin["judgement"])
	elseif arguments[1] == "soc" then
	    IWin_Paladin["soc"] = arguments[2]
	    DEFAULT_CHAT_FRAME:AddMessage("Seal of Command: " .. IWin_Paladin["soc"])
	else
		DEFAULT_CHAT_FRAME:AddMessage("Usage:")
		DEFAULT_CHAT_FRAME:AddMessage(" /iwin : Current setup")
		if IWin.hasPallyPower then
			DEFAULT_CHAT_FRAME:AddMessage("Judgements managed by PallyPowerTW")
		else
			DEFAULT_CHAT_FRAME:AddMessage(" /iwin judgement [" .. IWin_Paladin["judgement"] .. "] : Setup for Judgement on elites and worldbosses")
		end
		DEFAULT_CHAT_FRAME:AddMessage(" /iwin soc [" .. IWin_Paladin["soc"] .. "] : Setup for Seal of Command")
    end
end

---- idps button ----
SLASH_IDPS1 = '/idps'
function SlashCmdList.IDPS()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:DevotionAura()
	IWin:RetributionAura()
	IWin:ConcentrationAura()
	IWin:ShadowResistanceAura()
	IWin:FrostResistanceAura()
	IWin:FireResistanceAura()
	IWin:SanctityAura()
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
	IWin:SealOfCommand(15)
	IWin:SealOfRighteousness(15)
	IWin:HammerOfWrath(30)
	IWin:ExorcismRanged(30)
	IWin:JudgementRanged()
	IWin:HolyStrikeHolyMight()
	IWin:CrusaderStrike(15)
	IWin:HolyStrike()
	IWin:Exorcism(30)
	IWin:Judgement(50)
	IWin:RepentanceRaid()
	IWin:Consecration(90)
	IWin:StartAttack()
end

---- icleave button ----
SLASH_ICLEAVE1 = '/icleave'
function SlashCmdList.ICLEAVE()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:DevotionAura()
	IWin:RetributionAura()
	IWin:ConcentrationAura()
	IWin:ShadowResistanceAura()
	IWin:FrostResistanceAura()
	IWin:FireResistanceAura()
	IWin:SanctityAura()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:HolyShield(5)
	IWin:SealOfWisdom()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand(15)
	IWin:SealOfRighteousness(15)
	IWin:Consecration(50)
	IWin:HolyWrath()
	IWin:JudgementRanged()
	IWin:CrusaderStrike(15)
	IWin:HolyStrike()
	IWin:Judgement(50)
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- itank button ----
SLASH_ITANK1 = '/itank'
function SlashCmdList.ITANK()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:CancelSalvation()
	--IWin:RighteousFury()
	IWin:DevotionAura()
	IWin:RetributionAura()
	IWin:ConcentrationAura()
	IWin:ShadowResistanceAura()
	IWin:FrostResistanceAura()
	IWin:FireResistanceAura()
	IWin:SanctityAura()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:HolyShockPull(20)
	IWin:HolyShield(5)
	IWin:SealOfWisdom()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand(15)
	IWin:SealOfRighteousness(15)
	IWin:ExorcismRanged(30)
	IWin:JudgementRanged()
	IWin:HolyStrike()
	IWin:Exorcism(30)
	IWin:Judgement(50)
	IWin:HolyShock(15)
	IWin:Consecration(70)
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- ihodor button ----
SLASH_IHODOR1 = '/ihodor'
function SlashCmdList.IHODOR()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:MarkSkull()
	IWin:CancelSalvation()
	--IWin:RighteousFury()
	IWin:DevotionAura()
	IWin:RetributionAura()
	IWin:ConcentrationAura()
	IWin:ShadowResistanceAura()
	IWin:FrostResistanceAura()
	IWin:FireResistanceAura()
	IWin:SanctityAura()
	IWin:BlessingOfSanctuary()
	IWin:BlessingOfWisdom()
	IWin:BlessingOfMight()
	IWin:BlessingOfKings()
	IWin:BlessingOfLight()
	IWin:BlessingOfSalvation()
	IWin:Consecration(25)
	IWin:HolyShockPull(20)
	IWin:HolyShield(5)
	IWin:HolyShock(15)
	IWin:SealOfWisdom()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfWisdomEco()
	IWin:ExorcismRanged(30)
	IWin:JudgementRanged()
	IWin:HolyStrike()
	IWin:Exorcism(30)
	IWin:Judgement(50)
	IWin:RepentanceRaid()
	IWin:StartAttack()
end

---- ieco button ----
SLASH_IECO1 = '/ieco'
function SlashCmdList.IECO()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:DevotionAura()
	IWin:RetributionAura()
	IWin:ConcentrationAura()
	IWin:ShadowResistanceAura()
	IWin:FrostResistanceAura()
	IWin:FireResistanceAura()
	IWin:SanctityAura()
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
	IWin:HolyShield(5)
	IWin:HolyStrike()
	IWin:Judgement(50)
	IWin:HolyShock(15)
	IWin:StartAttack()
end

---- ijudge button ----
SLASH_IJUDGE1 = '/ijudge'
function SlashCmdList.IJUDGE()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:SealOfWisdomElite()
	IWin:SealOfLightElite()
	IWin:SealOfTheCrusaderElite()
	IWin:SealOfCommand(15)
	IWin:SealOfRighteousness(15)
	IWin:Judgement(50)
	IWin:StartAttack()
end

---- ichase button ----
SLASH_ICHASE1 = '/ichase'
function SlashCmdList.ICHASE()
	IWin_CombatVar["queueGCD"] = true
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
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:HammerOfJustice()
	IWin:StartAttack()
	IWin:Repentance()
end

---- itaunt button ----
SLASH_ITAUNT1 = '/itaunt'
function SlashCmdList.ITAUNT()
	IWin_CombatVar["queueGCD"] = true
	IWin:TargetEnemy()
	IWin:HandOfReckoning()
	IWin:StartAttack()
end

---- ibubblehearth button ----
SLASH_IBUBBLEHEARTH1 = '/ibubblehearth'
function SlashCmdList.IBUBBLEHEARTH()
	IWin_CombatVar["queueGCD"] = true
	IWin:DivineShield()
	IWin:UseItem("Hearthstone")
end

---- ihydrate button ----
SLASH_IHYDRATE1 = '/ihydrate'
function SlashCmdList.IHYDRATE()
	IWin_CombatVar["queueGCD"] = true
	IWin:UseDrinkItem()
end