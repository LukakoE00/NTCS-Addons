-- Most of this has been lifted from NT Eyes.
-- Table of characters and their temp info.
THERMCharacters = {}
-- Cold
NTCS_Thermal.ExtremeHypothermiaScaling = 1.3
NTCS_Thermal.MediumHypothermiaScaling = 1.2
NTCS_Thermal.LowHypothermiaScaling = 1
-- Hot
NTCS_Thermal.ExtremeHyperthermiaScaling = 1.1
NTCS_Thermal.MediumHyperthermiaScaling = 1.05
NTCS_Thermal.LowHyperthermiaScaling = 1

--#region HU Helper Functions

local Limbs = {LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}
-- Function used to take two limbs and apply the heat difference to both.
local function ApplyHeatDifference(character, ToLimbTemp, ToLimbType, FromLimbTemp, FromLimbType)
	local ClampedArteriesResistance = 1
	if NTCS.HF.GetAfflictionStrengthLimb(character, FromLimbType, "arteriesclamp", 0) > 0 or NTCS.HF.GetAfflictionStrengthLimb(character, ToLimbType, "arteriesclamp", 0) > 0 then
		-- Drastically reduces the amount of heat transferred when having clamped arteries.
		ClampedArteriesResistance = 3
	end
	-- Make sure the temperature isn't zero. Else temperature shouldn't be added and or removed.
	if FromLimbTemp > 1 then
		local TempDifference = ((ToLimbTemp/FromLimbTemp) - 1)/-1
		return {ToLimbDiff = TempDifference/ClampedArteriesResistance, FromLimbDiff = TempDifference/ClampedArteriesResistance * -1}
	end
	return {ToLimbDiff = 0, FromLimbDiff = 0}
end

-- Function used to return config stats.
local function FetchConfigStats()
	local ConfigStats = 
		{
		NormalBodyTemp = NTCS.Config.Get("NewNormalBodyTemp", 38),
		HypothermiaLevel = NTCS.Config.Get("NewHypothermiaLevel", 36),
		HyperthermiaLevel = NTCS.Config.Get("NewHyperthermiaLevel", 39),
		WarmingAbility = NTCS.Config.Get("NewWarmingAbility", .2),
		DryingSpeed = NTCS.Config.Get("NewDryingSpeed", -.1),
		PerformanceMode = NTCS.Config.Get("PerformanceMode",true),
		ShockMargin = NTCS.Config.Get("ShockMargin",100)/357.142
		}
	return ConfigStats
end


-- Function used to return random stats that I can't think of a better name for.
local function FetchOtherStats()
	local Stats =
	{
	AffectBodyCold = 1.1,
	AffectBodyWarm = 1.1,	
	LimbsToCheck = {LimbType.Head,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg},
	BloodAfflictions = {"elevated_core_temperature","diuretics","thrombolytics","aafn","cryo_stasis_starter"},
	MaxWarmingTemp = FetchConfigStats().NormalBodyTemp * 1.02,
	MaxCoolingTemp = FetchConfigStats().NormalBodyTemp/1.02
	}
	return Stats
end


-- Function used to transfer heat between limbs and torso.
local function TransferBodyHeat(character, TorsoTemp)
	local limbTemp = nil
	local TempDifference = nil
	local TotalTorsoTempDiff = 0
	-- Check to make sure that the temp isn't too low, else the torso will yoink temperature from nowhere. It shouldn't due to code I implemented in the ApplyHeatDifference func but this is still here as a failsafe.
	if not (TorsoTemp < 1.5) then
		for index, limb in pairs(FetchOtherStats().LimbsToCheck) do
			limbTemp = NTCS.HF.GetAfflictionStrengthLimb(character, limb, "ntt_temperature", NTCS.Config.Get("NewNormalBodyTemp", 38))
			TempDifference = ApplyHeatDifference(character,limbTemp,limb,TorsoTemp,LimbType.Torso)
			TotalTorsoTempDiff = TotalTorsoTempDiff + TempDifference.FromLimbDiff
			HF.AddAfflictionLimb(character, "ntt_temperature", limb, TempDifference.ToLimbDiff, character)
		end
		return TotalTorsoTempDiff
	end 
	return 0 
end

-- Used for the passive temp increase from the environment.
local function GetRoomTempAddition(character,limb)
	local WetTemp = 0
	local WetStrength = NTCS.HF.GetAfflictionStrengthLimb(character, limb, "wet", FetchConfigStats().NormalBodyTemp)
	local RoomTemp = 1
	if THERMRoom.GetRoom(character.CurrentHull) ~= nil then
		RoomTemp = THERMRoom.GetRoom(character.CurrentHull).Temp/THERMRoom.DefaultRoomTemp
	end
	if WetStrength > 0 then
		WetTemp = WetStrength/-1000
	end
	return (RoomTemp/10)
			+ WetTemp
end

-- Used to set arm swelling or leg swelling from a limb type.
local function LimbToSwelling(character,limb,duration)
	duration = duration or 2
	local Symptom = nil
	if NTCS.HF.NormalizeLimbType(limb) == LimbType.LeftArm or NTCS.HF.NormalizeLimbType(limb) == LimbType.RightArm then
		Symptom = "sym_armswelling"
	elseif NTCS.HF.NormalizeLimbType(limb) == LimbType.LeftLeg or NTCS.HF.NormalizeLimbType(limb) == LimbType.RightLeg then
		Symptom = "sym_legswelling"
	end
	if Symptom ~= nil then
		NTCS.NTC.SetSymptomTrue(character, Symptom, duration)
	end
end


-- Used for a more varied blood clotting simulator.
local function CalculateBloodClots(character,limb,special,deltaTime)
	special = special or 0
	local BloodClottedLimbs = function ()
		local TotalClottedValue = 0
		for index, limb in pairs(Limbs) do
			if NTCS.HF.GetAfflictionStrengthLimb(character, limb, "bloodclot", 0) > 0 then
				TotalClottedValue = TotalClottedValue + 1
			end
		end
		return TotalClottedValue
	end
	local TotalClots = BloodClottedLimbs()
	if NTCS.HF.GetAfflictionStrengthLimb(character, limb, "bloodclot", 0) == 0 and math.random(TotalClots,4) > TotalClots + 1 then
		return .5
		* NTCS.HF.GetAfflictionStrength(character, "bloodpressure", 100)
		/100 
		+ special * deltaTime
	end
	return .25 * deltaTime

end


-- Used to determine if a limb has been heated up too much. Basically make sure you're a good doctor. 
-- Note this is much different from thermal shock, as thermal shock is a body metric occuring every NT interval.
local function CalculateReperfusionInjury(degree, FrostBiteStrength, temp)
	local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
	local DegreeMaxTemp = HypothermiaLevel
	if degree == "d1" then
		DegreeMaxTemp = HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling/1.6
	elseif degree == "d2" then
		DegreeMaxTemp = HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.4
	elseif degree == "d3" then
		DegreeMaxTemp = 10
	end
	-- Formula to determine if the frostbite temp is too high given the temp it occurs at.
	if FrostBiteStrength/2/DegreeMaxTemp*(temp/DegreeMaxTemp) > 1.5 then
		return 25
	end
	return 0 
end


-- Used to determine if a limb will receive chilblains for a more varied experience.
local function CalculateChilblains(limb,character)
	local DefaultChance = 1
	local Chance = (NTCS.HF.GetAfflictionStrengthLimb(character, limb, "wet", 0)/50)
	+ (NTCS.HF.GetAfflictionStrength(character, "bloodpressure", 100)/100)
	+ DefaultChance
	if math.random(Chance,5) > Chance then
		return 25
	end
	return 0
end

-- Used to determine if the limb will heat cramp
local function CalculateHeatCramp(limb,character)
	local DefaultChance = 5
	local ElectrolyteGameplay = NTCS.HF.GetAfflictionStrength(character, "afsaline", 100)/50
	if math.random(0,10) > DefaultChance + ElectrolyteGameplay then
		return 5
	end
	return 0
end

--#endregion

local affLoader = NTCS.AfflictionsLoader(NTCS_Thermal.Name)
local builder = NTCS.AfflictionPrefabBuilder()

--#region Limb Afflictions

-- ntt_temperature
affLoader:Register(
    builder:New("ntt_temperature")
    :SetStrengths(1,101,38)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)
        local CharacterTable = THERM.GetCharacter(C.Human.ID)

        local function RoomIsHot()
				if THERMRoom and C.Human.CurrentHull ~= nil and THERMRoom.Rooms ~= nil 
					and THERMRoom.Intiated and THERMRoom.GetRoom(C.Human.CurrentHull) ~= nil 
					and THERMRoom.GetRoom(C.Human.CurrentHull).Temp >= THERMRoom.DefaultRoomTemp then
                	return true
        		end
				return false
			end
        
		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
		local wetStr = C:GetAfflictionStrengthLimb("wet",Limb,0)

		if affStr > 0 then
			if CharacterTable ~= nil then
				if CharacterTable.InCustomWater or C.Human.InWater or RoomIsHot() 
					or C:GetAfflictionStrength("bloodloss") > 0 or C:GetAfflictionStrength("sepsis") > 0 then -- We check to see if we need to update.
					CharacterTable.TemperatureUpdate = true
				end

				if (CharacterTable.TemperatureUpdate or NTCS.HF.Round(affStr, 2) ~= FetchConfigStats().NormalBodyTemp) 
					or not NTCS.Config.Get("PerformanceMode", true) then

					local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
					-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, don't change the temperature
					if not (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
						and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
						
						local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
						local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
						local TorsoTempStrength = NTCS.HF.GetAfflictionStrengthLimb(C.Human, LimbType.Torso, "ntt_temperature", 0)

						-- CompromisedTemp is the value at which the body will struggle to generate it's own heat or cool down. (You're cooked essentially.)
						local CompromisedColdTemp = HypothermiaLevel/1.5
						local CompromisedHotTemp = HyperthermiaLevel*1.5
						local CompromisedTempVal = 1

						-- Calculate new temperature
						C:SetAfflictionLimb(ID,Limb,affStr + THERM.CalculateTemperature(wetStr,C.Human,Limb))
						affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
						-- Calculate CompromisedTempVal: Being too low or high in temperature will make the body slower to reach normal body temp.
						-- The division by three is a scaling feature, i'm too lazy to make it a variable.
						if affStr < CompromisedColdTemp then
							CompromisedTempVal = (CompromisedColdTemp/affStr)/3
						-- The division by five is a scaling feature as well, same as last one.
						elseif affStr > CompromisedHotTemp then
							CompromisedTempVal = (affStr/CompromisedHotTemp)/5
						end

							-- Make torso colder or warmer based off limb temp being lower then certain point.
						if Limb ~= LimbType.Torso then 

							-- Slight optimization, if the temps are the same don't calculate.
							if TorsoTempStrength ~= affStr then
								local TempDiffs = ApplyHeatDifference(C.Human,TorsoTempStrength,LimbType.Torso,affStr,Limb)
								NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", LimbType.Torso, TempDiffs.ToLimbDiff, C.Human)
								C:SetAfflictionLimb(ID,Limb,affStr + TempDiffs.FromLimbDiff)
								affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
							end

							if Limb == LimbType.Head then

								-- Overlays
								if affStr < HypothermiaLevel and not THERM.HasHuskSymbiosis(C.Human) then
									NTCS.HF.SetAffliction(C.Human, "overlay_ice", NTCS.HF.Clamp(5/affStr*150,0,60))
								elseif affStr > HyperthermiaLevel then
									NTCS.HF.SetAffliction(C.Human, "overlay_fire", NTCS.HF.Clamp(affStr/NormalBodyTemp*50,0,100))
								else
									NTCS.HF.SetAffliction(C.Human, "overlay_ice", 0)
									NTCS.HF.SetAffliction(C.Human, "overlay_fire", 0)
								end

								if affStr < 2 and not THERM.HasHuskSymbiosis(C.Human) then
									C:AddAffliction("neurotrauma",.05 * dT)
								elseif affStr < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5 and not THERM.HasHuskSymbiosis(C.Human) then
									NTCS.NTC.SetSymptomTrue(C.Human, "sym_lightheadedness", 5)
								elseif affStr > HyperthermiaLevel * NTCS_Thermal.MediumHyperthermiaScaling then
									NTCS.NTC.SetSymptomTrue(C.Human, "sym_fever", 5)
								end
							else
								--FrostNip
								if affStr < HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling 
									and C:GetAfflictionStrengthLimb("frostnip",Limb,0)
									and C:GetAfflictionStrengthLimb("d1_frostbite",Limb,0)
									and C:GetAfflictionStrengthLimb("d2_frostbite",Limb,0)
									and C:GetAfflictionStrengthLimb("d3_frostbite",Limb,0)
									and not THERM.IsLimbCyber(C.Human,Limb) 
									and not THERM.HasHuskSymbiosis(C.Human) then
										C:SetAfflictionLimb("frostnip",Limb,1)
								
								elseif affStr > HyperthermiaLevel * NTCS_Thermal.MediumHyperthermiaScaling then
									C:AddAffliction("heat_cramp",CalculateHeatCramp(Limb,C.Human))
								end

								if Limb == LimbType.RightLeg then -- We tell the temp to stop.
									CharacterTable.TemperatureUpdate = false
								end

							end
						else

							-- Give hypothermia
							if affStr < HypothermiaLevel and not THERM.HasHuskSymbiosis(C.Human) then
								NTCS.HF.SetAffliction(C.Human, "hypothermia", 100)
								if affStr < HypothermiaLevel * NTCS_Thermal.ExtremeHypothermiaScaling then
								NTCS.NTC.SetSymptomTrue(C.Human, "shortnessofbreath", 2)
								end
							
							-- Give hyperthermia
							elseif affStr > HyperthermiaLevel then
								NTCS.HF.SetAffliction(C.Human, "hyperthermia", 100)
								-- Get burnt nerd
								if affStr > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.05 then
									NTCS.HF.AddAfflictionLimb(C.Human, "burn", Limb, .5 * dT, C.Human)
								elseif affStr > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.3 then
									NTCS.HF.AddAfflictionLimb(C.Human, "burn", Limb, 2 * dT, C.Human)
								end
							end

							-- Transfer heat from body to rest of character for accurate gameplay provided by thou Rat Jaccuzi
							C:SetAfflictionLimb(ID,Limb,affStr + TransferBodyHeat(C.Human,TorsoTempStrength))
							affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
						end

						-- Passive temperature reactions
						-- Warm up if cold.
						local RoomTempGain = GetRoomTempAddition(C.Human,Limb)
						local AmputatedLimbValue = NTCS.HF.BoolToNum(NTCS.NT.LimbIsAmputated(C.Human, Limb),1) + 1
						if affStr < NormalBodyTemp then
							C:SetAfflictionLimb(ID,Limb,NTCS.HF.Clamp(affStr
								+ RoomTempGain + (.05
									/CompromisedTempVal
										*(C:GetAfflictionStrength("bloodpressure")
											/100)/AmputatedLimbValue
												* dT),1,NormalBodyTemp))
						
						-- Cool down if warm
						elseif affStr > NormalBodyTemp then
							C:SetAfflictionLimb(ID,Limb,NTCS.HF.Clamp(affStr
									- RoomTempGain - (.05
										/CompromisedTempVal
											*(C:GetAfflictionStrength("bloodpressure")
												/100)/AmputatedLimbValue 
												* dT),NormalBodyTemp,101))
						end
					else
						-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, set the temperature to normal body temp
						C:SetAfflictionLimb(ID,Limb,NormalBodyTemp)
						NTCS.HF.SetAffliction(C.Human, "overlay_ice", 0)
						NTCS.HF.SetAffliction(C.Human, "overlay_fire", 0)
					end
				end
			end
			return
		-- Set Temperature since the current is 0.
		else
			C:SetAfflictionLimb(ID,Limb,FetchConfigStats().NormalBodyTemp)
		end  
    end)
    :Build()
)

-- warmth
affLoader:Register(
    builder:New("warmth")
    :SetStrengths(0,100,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.MEDIUM)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local WarmingAbility = FetchConfigStats().WarmingAbility
		local WarmthScaling = 4
		local MaxWarmingTemp = FetchOtherStats().MaxWarmingTemp
		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		-- Warm up skin.
		if affStr > 0 then
			THERM.ApplyTemperatureUpdate(C.Human.ID)
			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, don't change the temperature
			if not (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
			
			NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", Limb, (WarmingAbility
									/(C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)/MaxWarmingTemp)
									/WarmthScaling 
									* dT), C.Human)
			end
			
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 1.05) -- 5% speed increase per limb
			if C:GetAfflictionStrength("bloodpressure") > 100 then
				C:AddAffliction("bloodpressure",-.05 * dT)
			end

			NTCS.HF.AddAfflictionLimb(C.Human, "warmth", Limb, -1.7 * dT, C.Human)

			if Limb == LimbType.Torso and C:GetAfflictionStrength("internalbleeding") > 0 then
				C:AddAffliction("internalbleeding",0.2 * dT)
			end
		end

	end)
	:Build()
)

-- ntt_iced
affLoader:Register(
    builder:New("ntt_iced")
    :SetStrengths(0,100,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.MEDIUM)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local CoolingAbility = FetchConfigStats().WarmingAbility
		local MaxCoolingTemp = FetchOtherStats().MaxCoolingTemp
		local CoolScaling = -2.9
		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
		local icedStr = C:GetAfflictionStrengthLimb("iced",Limb,0)

		-- over time skin temperature goes up again
		if icedStr > 0 then
			THERM.ApplyTemperatureUpdate(C.Human.ID)
			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, don't change the temperature
			if not (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
			NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", Limb, ((CoolingAbility
				/(MaxCoolingTemp/C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)))
				* CoolScaling  
				* dT), C.Human)
			end
		end
		
	end)
	:Build()
)

-- wet
affLoader:Register(
    builder:New("wet")
    :SetStrengths(0,100,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		-- cool down skin.
		if affStr > 1.1 then
			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, don't change the temperature
			if not (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				THERM.ApplyTemperatureUpdate(C.Human.ID)
				local WetStrength = affStr
				local WetTempAddition = .1

				if C:GetAfflictionStrengthLimb("bandaged",Limb,0) > 0 and NTCS.Config.Get("WaterDirtiesBandages",true) then
					NTCS.HF.AddAfflictionLimb(C.Human, "dirtybandage", Limb, WetStrength/4 * dT, C.Human)
					NTCS.HF.AddAfflictionLimb(C.Human, "bandaged", Limb, -WetStrength/4 * dT, C.Human)
				end

				NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", Limb, (.05
						* (WetStrength + WetTempAddition) 
							* dT), C.Human)
			else
				-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
				C:SetAfflictionLimb(ID,Limb,0)
				THERM.ApplyTemperatureUpdate(C.Human.ID)
			end

		end
	end)
	:Build()
)

-- frostnip
affLoader:Register(
    builder:New("frostnip")
    :SetStrengths(0,25,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
		local d1_frostbiteStr = C:GetAfflictionStrengthLimb("d1_frostbite",Limb,0)

		if affStr > 0 and d1_frostbiteStr == 0 and not THERM.IsLimbCyber(C.Human,Limb) and not THERM.HasHuskSymbiosis(C.Human) then

			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
			if (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			or (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				C:SetAfflictionLimb(ID,Limb,0)
			end

			local LimbTemp = C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			if LimbTemp < HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling then
				C:AddAffliction(ID,((HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling/LimbTemp)* dT))
			else
				C:AddAffliction(ID,-((LimbTemp/HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling)* dT))
			end
			affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
			if affStr > 24.9  and LimbTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling then
				C:SetAfflictionLimb("d1_frostbite",Limb,1)
			end
			return
		end

		C:SetAfflictionLimb(ID,Limb,0)

	end)
	:Build()
)

-- d1_frostbite
affLoader:Register(
    builder:New("d1_frostbite")
    :SetStrengths(0,25,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 and not THERM.IsLimbCyber(C.Human,Limb) and not THERM.HasHuskSymbiosis(C.Human) then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.90) -- 10% slow per limb
			NTCS.NTC.SetSymptomTrue(C.Human, "sym_pins_needles", 5)
			C:SetAfflictionLimb("frostnip",Limb,0)
			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
			if (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			or (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				C:SetAfflictionLimb(ID,Limb,0)
			end
			local LimbTemp = C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			if LimbTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling then
				C:AddAfflictionLimb(ID,Limb,(HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/LimbTemp)/2 * dT)
			else

				C:AddAfflictionLimb(ID,Limb, -((LimbTemp/HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling) * dT))
				affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
				if affStr < .1 then
					C:SetAfflictionLimb("frostnip",Limb,24.9)
				end

			end
			affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
			if affStr > 24.9 and LimbTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5 then
				C:SetAfflictionLimb("d2_frostbite",Limb,1)
			end

			C:AddAfflictionLimb("reperfusion_injury",Limb, CalculateReperfusionInjury("d1", affStr,NTCS.HF.GetAfflictionStrengthLimb(C.Human, Limb, "ntt_temperature", 0)))
			return
		end
		
		C:SetAfflictionLimb(ID,Limb,0)

	end)
	:Build()
)

-- d2_frostbite
affLoader:Register(
    builder:New("d2_frostbite")
    :SetStrengths(0,25,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 and not THERM.IsLimbCyber(C.Human,Limb) and not THERM.HasHuskSymbiosis(C.Human) then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.80) -- 20% slow per limb
			NTCS.NTC.SetSymptomTrue(C.Human, "sym_pins_needles", 5)
			C:SetAfflictionLimb("d1_frostbite",Limb,0)

			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
			if (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			or (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				C:SetAfflictionLimb(ID,Limb,0)
			end

			local LimbTemp = C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			C:AddAfflictionLimb("bloodclot", Limb, (CalculateBloodClots(C.Human,Limb) * dT))
			if LimbTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5 then
				C:AddAfflictionLimb(ID,Limb,(HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5/LimbTemp)/2 * dT)
			else

				C:AddAfflictionLimb(ID,Limb, -((LimbTemp/HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.1) * dT))
				affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
				if affStr < .1 then
					C:SetAfflictionLimb("d1_frostbite",Limb,24.9)
					C:SetAfflictionLimb("chilblains",Limb,CalculateChilblains(type,C.Human))
					C:SetAfflictionLimb("inflammation",Limb,10)
					C:SetAfflictionLimb("intensepain",Limb,10)
				end

			end
			affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

			if affStr > 24.9 and LimbTemp < 2 and not NTCS.NT.LimbIsAmputated(C.Human, Limb) then
				C:SetAfflictionLimb("d3_frostbite",Limb,1)
			end

			C:AddAfflictionLimb("reperfusion_injury",Limb, CalculateReperfusionInjury("d2", affStr,NTCS.HF.GetAfflictionStrengthLimb(C.Human, Limb, "ntt_temperature", 0)))
			return
		end
		
		C:SetAfflictionLimb(ID,Limb,0)

	end)
	:Build()
)

-- d3_frostbite
affLoader:Register(
    builder:New("d3_frostbite")
    :SetStrengths(0,25,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 and not THERM.IsLimbCyber(C.Human,Limb) and not THERM.HasHuskSymbiosis(C.Human) then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.70) -- 30% slow per limb
			C:SetAfflictionLimb("d2_frostbite",Limb,0)

			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
			if (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			or (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				C:SetAfflictionLimb(ID,Limb,0)
			end
			
			local LimbTemp = C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			C:AddAfflictionLimb("bloodclot",Limb,(CalculateBloodClots(C.Human,Limb,.1) * dT))

			if LimbTemp < 2 then
				C:AddAfflictionLimb(ID,Limb, .5 * dT)
			end
			if affStr > 10 then

				if C:GetAfflictionStrengthLimb("gangrene",Limb,0) < 15 then
					C:SetAfflictionLimb("gangrene",Limb,15)
				end
				C:AddAfflictionLimb("gangrene",Limb, .1 * dT)

			else
				C:AddAfflictionLimb(ID,Limb, -.2 * dT)
				affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
				if affStr < .1 then
					C:SetAfflictionLimb("d2_frostbite",Limb,24.9)
					C:SetAfflictionLimb("inflammation",Limb,10)
				end
			end

			affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

			if NTCS.NT.LimbIsAmputated(C.Human, Limb) then
				C:SetAfflictionLimb("d3_frostbite",Limb,0)
				C:SetAfflictionLimb("d2_frostbite",Limb,24.9)
				C:AddAfflictionLimb("chilblains",Limb,CalculateChilblains(Limb,C.Human))
				C:SetAfflictionLimb("pain_extremity",Limb,10)
				C:SetAfflictionLimb("inflammation",Limb,10)
			end

			affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
			C:AddAfflictionLimb("reperfusion_injury",Limb,
				CalculateReperfusionInjury("d3", affStr, NTCS.HF.GetAfflictionStrengthLimb(C.Human, Limb, "ntt_temperature", 0)))
			return

		end
		C:SetAfflictionLimb(ID,Limb,0)

	end)
	:Build()
)

-- bloodclot
affLoader:Register(
    builder:New("bloodclot")
    :SetStrengths(0,25,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local BloodClotDissolvingRate = 0
			local BloodClotGrowthRate = 0
			local BloodPressureIncrease = 0
			local LimbClotScaling = 1
			
			if C:GetBoolStat("stasis") then
				return
			end
			if Limb == LimbType.LeftArm or Limb == LimbType.RightArm then
				LimbClotScaling = .4
			else
				LimbClotScaling = .2
			end
			if affStr < 16 then

				BloodClotDissolvingRate = .05
				BloodClotGrowthRate = .02
				BloodPressureIncrease = 1

			elseif affStr < 21 then

				LimbToSwelling(C.Human,Limb,5)
				BloodClotDissolvingRate = .03
				BloodClotGrowthRate = .03
				BloodPressureIncrease = 2

				if math.random(0,5) > 4 and C:GetAfflictionStrength("lungremoved") == 0 then
					C:AddAffliction("pulmonary_embolism",.5 * dT)
				end

			elseif affStr > 21 then

				LimbToSwelling(C.Human,Limb,5)
				BloodPressureIncrease = 3
				BloodClotGrowthRate = .04

				if C:GetAfflictionStrength("lungremoved") == 0 then
					C:AddAffliction("pulmonary_embolism",.5 * dT)
				end

			end

			C:AddAffliction("bloodpressure",BloodPressureIncrease * dT)

			C:AddAffliction(ID,
				-((BloodClotDissolvingRate 
					* (C:GetAfflictionStrength("thrombolytics")/10)
						- C:GetAfflictionStrength("acidosis")/1000
							+ C:GetAfflictionStrength("alkalosis")/1000
								+ C:GetAfflictionStrength("bloodpressure")/1000
									+ 1 * LimbClotScaling) 
										+ BloodClotGrowthRate * dT))
		end

	end)
	:Build()
)

-- chilblains
affLoader:Register(
    builder:New("chilblains")
    :SetStrengths(0,100,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local PassiveDecay = .05
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel

			C:AddAffliction(ID,.5 * - ((PassiveDecay
				+ C:GetAfflictionStrengthLimb("bandaged",Limb,0)/500 
					* NTCS.HF.Clamp(C:GetAfflictionStrengthLimb("ointmented",Limb,0)/500 /50,1,2))
						* NTCS.HF.Clamp(C:GetAfflictionStrengthLimb("warmth",Limb,0)/50,1,2)
							* dT))
			
			if C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0) > HyperthermiaLevel then
				C:AddAfflictionLimb("infectedwound",Limb,.05 * dT)
			end

			if C:GetAfflictionStrengthLimb("bandaged",Limb,0) < 1 then
				C:AddAfflictionLimb("infectedwound",Limb,((C:GetAfflictionStrengthLimb("wet",Limb,0)/100) + math.random(.5,1) * dT))
			end

		end

	end)
	:Build()
)

-- reperfusion_injury
affLoader:Register(
    builder:New("reperfusion_injury")
    :SetStrengths(0,100,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local InternalDamageRate = .05
			local BoneDamage = .1
			local PassiveHeal = .1
			C:AddAfflictionLimb("internaldamage",Limb,InternalDamageRate * dT)
			C:AddAfflictionLimb("bonedamage",Limb,BoneDamage * dT)
			C:AddAfflictionLimb(ID,Limb,-PassiveHeal * dT)
		end

	end)
	:Build()
)

-- heat_cramp
affLoader:Register(
    builder:New("heat_cramp")
    :SetStrengths(0,25,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
			NTCS.HF.AddAfflictionLimb(C.Human, "spasm", type, 10)
			C:AddAfflictionLimb(ID,Limb,-(.5 -- Go down 1 percent each tick.
									- (c.afflictions.afsaline.strength/50)
									* dT))
			
			if C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0) < HyperthermiaLevel * NTCS_Thermal.MediumHyperthermiaScaling then
				C:SetAfflictionLimb(ID,Limb,0)
			end
		end

	end)
	:Build()
)

-- removed_skin
affLoader:Register(
    builder:New("removed_skin")
    :SetStrengths(0,20,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			C:AddAfflictionLimb("infectedwound",Limb,.25 * dT)
			C:SetAfflictionLimb("inflammation",Limb,10)
		end

	end)
	:Build()
)

-- grafted_skin
affLoader:Register(
    builder:New("grafted_skin")
    :SetStrengths(0,10,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.LOW)
    :SetUpdateAction(function(C, ID, Limb, dT)


	end)
	:Build()
)

-- stretched_skin
affLoader:Register(
    builder:New("stretched_skin")
    :SetStrengths(0,10,0)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.LOW)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.70) -- 30% slow per limb
			C:AddAfflictionLimb(ID,Limb,-.05 * dT)
		end

	end)
	:Build()
)

--#endregion

-- pulmonary_embolism
affLoader:Register(
    builder:New("pulmonary_embolism")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.LOW)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.70) -- 30% slow per limb
			C:AddAfflictionLimb(ID,Limb,-.05 * dT)
		end

	end)
	:Build()
)