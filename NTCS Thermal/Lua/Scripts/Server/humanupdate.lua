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

NTCS_Thermal.DeltaTime = 2

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
			NTCS.HF.AddAfflictionLimb(character, "ntt_temperature", limb, TempDifference.ToLimbDiff, character)
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
		Symptom = "legswelling"
	end
	if Symptom ~= nil then
		NTHuman.getNTHumanFromCharacter(character):SetSymptomTrue(Symptom, duration)
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
		+ special * NTCS_Thermal.DeltaTime
	end
	return .25 * NTCS_Thermal.DeltaTime

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

local affLoader = NTCS.AfflictionsLoader("NTCS Thermal")
local builder = NTCS.AfflictionPrefabBuilder()

--#region Limb Afflictions

-- ntt_temperature
affLoader:Register(
    builder:New("ntt_temperature")
    :SetStrengths(1,101,38)
    :IsLimbSpecific(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
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

				if (CharacterTable.TemperatureUpdate or THERM.Round(affStr, 2) ~= FetchConfigStats().NormalBodyTemp) 
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
						C:SetAfflictionLimb(ID,Limb,affStr + THERM.CalculateTemperature(wetStr,C.Human,Limb,NTCS_Thermal.DeltaTime))
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
									C:AddAffliction("neurotrauma",.05 * NTCS_Thermal.DeltaTime)
								elseif affStr < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5 and not THERM.HasHuskSymbiosis(C.Human) then
									C:SetSymptomTrue("lightheadedness", 5)
								elseif affStr > HyperthermiaLevel * NTCS_Thermal.MediumHyperthermiaScaling then
									C:SetSymptomTrue("fever", 5)
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
								C:SetSymptomTrue("shortnessofbreath", 2)
								end
							
							-- Give hyperthermia
							elseif affStr > HyperthermiaLevel then
								NTCS.HF.SetAffliction(C.Human, "hyperthermia", 100)
								-- Get burnt nerd
								if affStr > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.05 then
									NTCS.HF.AddAfflictionLimb(C.Human, "burn", Limb, .5 * NTCS_Thermal.DeltaTime, C.Human)
								elseif affStr > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.3 then
									NTCS.HF.AddAfflictionLimb(C.Human, "burn", Limb, 2 * NTCS_Thermal.DeltaTime, C.Human)
								end
							end

							-- Transfer heat from body to rest of character for accurate gameplay provided by thou Rat Jaccuzi
							C:SetAfflictionLimb(ID,Limb,affStr + TransferBodyHeat(C.Human,TorsoTempStrength))
							affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
						end

						-- Passive temperature reactions
						-- Warm up if cold.
						local RoomTempGain = GetRoomTempAddition(C.Human,Limb)
						local AmputatedLimbValue = NTCS.HF.BoolToNum(NTCS.HF.LimbIsAmputated(C.Human, Limb),1) + 1
						if affStr < NormalBodyTemp then
							C:SetAfflictionLimb(ID,Limb,NTCS.HF.Clamp(affStr
								+ RoomTempGain + (.05
									/CompromisedTempVal
										*(C:GetAfflictionStrength("bloodpressure")
											/100)/AmputatedLimbValue
												* NTCS_Thermal.DeltaTime),1,NormalBodyTemp))
						
						-- Cool down if warm
						elseif affStr > NormalBodyTemp then
							C:SetAfflictionLimb(ID,Limb,NTCS.HF.Clamp(affStr
									- RoomTempGain - (.05
										/CompromisedTempVal
											*(C:GetAfflictionStrength("bloodpressure")
												/100)/AmputatedLimbValue 
												* NTCS_Thermal.DeltaTime),NormalBodyTemp,101))
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
	:IsConst(true)
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
									* NTCS_Thermal.DeltaTime), C.Human)
			end
			
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 1.05) -- 5% speed increase per limb
			if C:GetAfflictionStrength("bloodpressure") > 100 then
				C:AddAffliction("bloodpressure",-.05 * NTCS_Thermal.DeltaTime)
			end

			NTCS.HF.AddAfflictionLimb(C.Human, "warmth", Limb, -1.7 * NTCS_Thermal.DeltaTime, C.Human)

			if Limb == LimbType.Torso and C:GetAfflictionStrength("internalbleeding") > 0 then
				C:AddAffliction("internalbleeding",0.2 * NTCS_Thermal.DeltaTime)
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
	:IsConst(true)
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
				* NTCS_Thermal.DeltaTime), C.Human)
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
	:IsConst(true)
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
					NTCS.HF.AddAfflictionLimb(C.Human, "dirtybandage", Limb, WetStrength/4 * NTCS_Thermal.DeltaTime, C.Human)
					NTCS.HF.AddAfflictionLimb(C.Human, "bandaged", Limb, -WetStrength/4 * NTCS_Thermal.DeltaTime, C.Human)
				end

				NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", Limb, (.05
						* (WetStrength + WetTempAddition) 
							* NTCS_Thermal.DeltaTime), C.Human)
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local normalizedLimb = NTCS.HF.NormalizeLimbType(Limb)
		if normalizedLimb == LimbType.Head or normalizedLimb == LimbType.Torso then
			C:SetAfflictionLimb(ID,Limb,0)
			return
		end

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
				C:AddAffliction(ID,((HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling/LimbTemp)* NTCS_Thermal.DeltaTime))
			else
				C:AddAffliction(ID,-((LimbTemp/HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling)* NTCS_Thermal.DeltaTime))
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		local normalizedLimb = NTCS.HF.NormalizeLimbType(Limb)
		if normalizedLimb == LimbType.Head or normalizedLimb == LimbType.Torso then
			C:SetAfflictionLimb(ID,Limb,0)
			return
		end

		if affStr > 0 and not THERM.IsLimbCyber(C.Human,Limb) and not THERM.HasHuskSymbiosis(C.Human) then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.90) -- 10% slow per limb
			C:SetSymptomTrue("sym_pins_needles", 5)
			C:SetAfflictionLimb("frostnip",Limb,0)
			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
			if (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			or (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				C:SetAfflictionLimb(ID,Limb,0)
			end
			local LimbTemp = C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			if LimbTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling then
				C:AddAfflictionLimb(ID,Limb,(HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/LimbTemp)/2 * NTCS_Thermal.DeltaTime)
			else

				C:AddAfflictionLimb(ID,Limb, -((LimbTemp/HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling) * NTCS_Thermal.DeltaTime))
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		local normalizedLimb = NTCS.HF.NormalizeLimbType(Limb)
		if normalizedLimb == LimbType.Head or normalizedLimb == LimbType.Torso then
			C:SetAfflictionLimb(ID,Limb,0)
			return
		end

		if affStr > 0 and not THERM.IsLimbCyber(C.Human,Limb) and not THERM.HasHuskSymbiosis(C.Human) then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.80) -- 20% slow per limb
			C:SetSymptomTrue("sym_pins_needles", 5)
			C:SetAfflictionLimb("d1_frostbite",Limb,0)

			-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, remove the affliction
			if (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
			or (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				C:SetAfflictionLimb(ID,Limb,0)
			end

			local LimbTemp = C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			C:AddAfflictionLimb("bloodclot", Limb, (CalculateBloodClots(C.Human,Limb,1,NTCS_Thermal.DeltaTime) * NTCS_Thermal.DeltaTime))
			if LimbTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5 then
				C:AddAfflictionLimb(ID,Limb,(HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5/LimbTemp)/2 * NTCS_Thermal.DeltaTime)
			else

				C:AddAfflictionLimb(ID,Limb, -((LimbTemp/HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.1) * NTCS_Thermal.DeltaTime))
				affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)
				if affStr < .1 then
					C:SetAfflictionLimb("d1_frostbite",Limb,24.9)
					C:SetAfflictionLimb("chilblains",Limb,CalculateChilblains(Limb,C.Human))
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		local normalizedLimb = NTCS.HF.NormalizeLimbType(Limb)
		if normalizedLimb == LimbType.Head or normalizedLimb == LimbType.Torso then
			C:SetAfflictionLimb(ID,Limb,0)
			return
		end

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
			C:AddAfflictionLimb("bloodclot",Limb,(CalculateBloodClots(C.Human,Limb,.1,NTCS_Thermal.DeltaTime) * NTCS_Thermal.DeltaTime))

			if LimbTemp < 2 then
				C:AddAfflictionLimb(ID,Limb, .5 * dT)
			end
			if affStr > 10 then

				if C:GetAfflictionStrengthLimb("gangrene",Limb,0) < 15 then
					C:SetAfflictionLimb("gangrene",Limb,15)
				end
				C:AddAfflictionLimb("gangrene",Limb, .1 * NTCS_Thermal.DeltaTime)

			else
				C:AddAfflictionLimb(ID,Limb, -.2 * NTCS_Thermal.DeltaTime)
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
	:IsConst(true)
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
					C:AddAffliction("pulmonary_embolism",.5 * NTCS_Thermal.DeltaTime)
				end

			elseif affStr > 21 then

				LimbToSwelling(C.Human,Limb,5)
				BloodPressureIncrease = 3
				BloodClotGrowthRate = .04

				if C:GetAfflictionStrength("lungremoved") == 0 then
					C:AddAffliction("pulmonary_embolism",.5 * NTCS_Thermal.DeltaTime)
				end

			end

			C:AddAffliction("bloodpressure",BloodPressureIncrease * NTCS_Thermal.DeltaTime)

			C:AddAffliction(ID,
				-((BloodClotDissolvingRate 
					* (C:GetAfflictionStrength("thrombolytics")/10)
						- C:GetAfflictionStrength("acidosis")/1000
							+ C:GetAfflictionStrength("alkalosis")/1000
								+ C:GetAfflictionStrength("bloodpressure")/1000
									+ 1 * LimbClotScaling) 
										+ BloodClotGrowthRate * NTCS_Thermal.DeltaTime))
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local PassiveDecay = .05
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel

			C:AddAffliction(ID,.5 * - ((PassiveDecay
				+ C:GetAfflictionStrengthLimb("bandaged",Limb,0)/500 
					* NTCS.HF.Clamp(C:GetAfflictionStrengthLimb("ointmented",Limb,0)/500 /50,1,2))
						* NTCS.HF.Clamp(C:GetAfflictionStrengthLimb("warmth",Limb,0)/50,1,2)
							* NTCS_Thermal.DeltaTime))
			
			if C:GetAfflictionStrengthLimb("ntt_temperature",Limb,0) > HyperthermiaLevel then
				C:AddAfflictionLimb("infectedwound",Limb,.05 * NTCS_Thermal.DeltaTime)
			end

			if C:GetAfflictionStrengthLimb("bandaged",Limb,0) < 1 then
				C:AddAfflictionLimb("infectedwound",Limb,((C:GetAfflictionStrengthLimb("wet",Limb,0)/100) + math.random(.5,1) * NTCS_Thermal.DeltaTime))
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local InternalDamageRate = .05
			local BoneDamage = .1
			local PassiveHeal = .1
			C:AddAfflictionLimb("internaldamage",Limb,InternalDamageRate * NTCS_Thermal.DeltaTime)
			C:AddAfflictionLimb("bonedamage",Limb,BoneDamage * NTCS_Thermal.DeltaTime)
			C:AddAfflictionLimb(ID,Limb,-PassiveHeal * NTCS_Thermal.DeltaTime)
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
			NTCS.HF.AddAfflictionLimb(C.Human, "spasm", Limb, 10)
			C:AddAfflictionLimb(ID,Limb,-(.5 -- Go down 1 percent each tick.
									- (C:GetAfflictionStrength("afsaline")/50)
									* NTCS_Thermal.DeltaTime))
			
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			C:AddAfflictionLimb("infectedwound",Limb,.25 * NTCS_Thermal.DeltaTime)
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
	:IsConst(true)
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
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrengthLimb(ID,Limb,0)

		if affStr > 0 then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * 0.70) -- 30% slow per limb
			C:AddAfflictionLimb(ID,Limb,-.05 * NTCS_Thermal.DeltaTime)
		end

	end)
	:Build()
)

--#endregion

-- pulmonary_embolism
affLoader:Register(
    builder:New("pulmonary_embolism")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			if C:GetAfflictionStrength("lungremoved") > 0 then
				if C:GetAfflictionStrength("lungdamage") >= 50 then
					C:SetAffliction("internalbleeding",50)
				end
				C:SetAffliction(ID,0)
			end

			if C:GetBoolStat("stasis") then
				return
			end

			affStr = C:GetAfflictionStrength(ID)

			if affStr > 10 then
				C:SetSymptomTrue("shortnessofbreath", 5)
			elseif affStr > 25 then
				C:SetSymptomTrue("shortnessofbreath", 5)
				C:SetSymptomTrue("chestpain", 5)
			elseif affStr > 75 then
				C:SetSymptomTrue("shortnessofbreath", 5)
				C:SetSymptomTrue("chestpain", 5)
				C:SetAffliction("respiratoryarrest",100)
			end
			C:AddAffliction(ID,-(C:GetAfflictionStrength("thrombolytics")/3.5 - C:GetAfflictionStrength("afstreptokinase")/10 - .2 * NTCS_Thermal.DeltaTime))

		end

	end)
	:Build()
)

-- pulmonary_edema
affLoader:Register(
    builder:New("pulmonary_edema")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			if C:GetAfflictionStrength("lungremoved") > 0 then
				if C:GetAfflictionStrength("lungdamage") >= 50 then
					C:SetAffliction("internalbleeding",50)
				end
				C:SetAffliction(ID,0)
			end

			if C:GetBoolStat("stasis") then
				return
			end

			C:AddAffliction(ID,(C:GetAfflictionStrength("heartdamage")/80 + C:GetAfflictionStrength("bloodpressure")/50
								+ C:GetAfflictionStrength("sepsis")/50 + THERM.GetCharacter(C.Human.ID).LimbWaterValues.TorsoV/50
								- C:GetAfflictionStrength("diuretics")/10 * NTCS_Thermal.DeltaTime))
			C:SetSymptomTrue("shortnessofbreath", 5)
			affStr = C:GetAfflictionStrength(ID)
			if affStr > 25 then
				C:SetSymptomTrue("wheezing", 5)
				if affStr > 75 then
					C:SetSymptomTrue("vomitingblood", 5)
					C:SetAffliction("respiratoryarrest",100)
				end
			end
		elseif C:GetAfflictionStrength("heartdamage") > 80 and C:GetAfflictionStrength("heartremoved") == 0 then
			C:SetAffliction(ID,1)
		end

	end)
	:Build()
)

-- hypothermia
affLoader:Register(
    builder:New("hypothermia")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 and not THERM.HasHuskSymbiosis(C.Human) then
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			local TorsoTemp = NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0)

			local LowHypo = function ()
				C:AddAffliction("bloodpressure",(.5 * NTCS_Thermal.DeltaTime))
				C:SetSymptomTrue("hypoventilation", 2)
			end

			local MedHypo = function ()
				C:AddAffliction("bloodpressure",(.1 * NTCS_Thermal.DeltaTime))
				C:AddAffliction("pulmonary_edema",(THERM.GetCharacter(C.Human.ID).LimbWaterValues.TorsoV/50 + C:GetAfflictionStrength("lungdamage")/50 * NTCS_Thermal.DeltaTime))
				C:SetSymptomTrue("paleskin", 5)
				C:SetSymptomTrue("unconsciousness", 2)
			end

			local HighHypo = function ()
				C:SetAffliction("respiratoryarrest",100)
				C:AddAffliction("analgesia",(.5 * NTCS_Thermal.DeltaTime))
				C:AddAffliction("immunity",-(5 * NTCS_Thermal.DeltaTime))
			end

			local CookedHypo = function ()
				C:AddAffliction("frozen_vessels",(2 * NTCS_Thermal.DeltaTime))
				C:SetAffliction("coma",100)
			end
			
			C:AddAffliction("bloodpressure",(.2 * NTCS_Thermal.DeltaTime))
			if TorsoTemp < 2 then -- Horrible Hypothermia
				CookedHypo()
				HighHypo()
				MedHypo()
				LowHypo()

			elseif TorsoTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/2 then -- Bad Hypothermia
				HighHypo()
				MedHypo()
				LowHypo()

			elseif TorsoTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5 then -- Decent Hypothermia
				MedHypo()
				LowHypo()

			elseif TorsoTemp < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling then -- Low Hypothermia
				LowHypo()
			end

			if  NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0) > HypothermiaLevel then
				C:SetAffliction(ID,0)
			end

		elseif affStr > 0 and THERM.HasHuskSymbiosis(C.Human) then
			C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") * ((HypothermiaLevel/2)/NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0))/2)
		else
			C:SetAffliction(ID,0)
		end

	end)
	:Build()
)

-- hyperthermia
affLoader:Register(
    builder:New("hyperthermia")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			local Death = (5 * NTCS_Thermal.DeltaTime)
			local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
			local TorsoTemp = NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0)
			C:AddAffliction("bloodpressure",(-.2 * NTCS_Thermal.DeltaTime))

			if TorsoTemp < HyperthermiaLevel then
				C:SetAffliction(ID,0)
				return
			end

			if TorsoTemp > HyperthermiaLevel and TorsoTemp < HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.05 then
				C:SetSymptomTrue("sweating", 2)
			end

			local MediumHyper = function ()
				C:AddAffliction("heat_stroke",(1 * NTCS_Thermal.DeltaTime))
				NTCS.HF.AddAffliction(C.Human, "huskinfection", -10 * NTCS_Thermal.DeltaTime, C.Human) -- EXTERMINATE THE BITCH ASS HUSK. JUSTICE FOR ARTIE DOOLITTLE. THOSE BASTARDS SLIMED HIM OUT. God speed artie, love you.
				-- NT Symbiote compat:
				if NTCS.HF.HasAffliction(C.Human, "surgery_huskhealth", 1) then
					NTCS.HF.AddAffliction(C.Human, "surgery_huskhealth", -10 * NTCS_Thermal.DeltaTime, C.Human)
				end
			end

			local ExtremeHyper = function ()
				C:AddAffliction("neurotrauma",Death)
				C:AddAffliction("lungdamage",Death)
				C:AddAffliction("liverdamage",Death)
				C:AddAffliction("heartdamage",Death)
				C:AddAffliction("kidneydamage",Death)
			end

			if TorsoTemp > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling then
				C:SetSymptomTrue("sweating", 2)

			elseif TorsoTemp > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.05 then
				C:SetSymptomTrue("sweating", 2)
				MediumHyper()

			elseif TorsoTemp > HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.2 then
				C:SetSymptomTrue("sweating", 2)
				MediumHyper()
				ExtremeHyper()

			if THERM.HasHuskSymbiosis(C.Human) then
				C:SetFloatStat("speedmultiplier", C:GetFloatStat("speedmultiplier") / (NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0)/(HyperthermiaLevel))/2)
			end
		end

		end

	end)
	:Build()
)

-- frozen_vessels
affLoader:Register(
    builder:New("frozen_vessels")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			local PassiveDecay = .2
			local CellDeathGrowth = .2
			local BodyTemp = NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0)
			local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
			
			if affStr < 10 then
				C:AddAffliction(ID,-PassiveDecay * NTCS_Thermal.DeltaTime)
			end

			if BodyTemp > HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/4.5 then
				local Formula = ((CellDeathGrowth + BodyTemp/10)  * NTCS_Thermal.DeltaTime)
				C:AddAffliction("cell_death",Formula)
				C:AddAffliction(ID,-Formula)
			end

			C:AddAffliction(ID,-(C:GetAfflictionStrength("aafn")/20 * NTCS_Thermal.DeltaTime))

		end

	end)
	:Build()
)

-- cell_death
affLoader:Register(
    builder:New("cell_death")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			local InternalBleedingIncrease = .2
			local LiverDamageIncrease = 1
			local Death = (1 * NTCS_Thermal.DeltaTime)

			local KillOrgans = function ()
				C:AddAffliction("cerebralhypoxia",Death)
				C:AddAffliction("lungdamage",Death)
				C:AddAffliction("liverdamage",Death)
				C:AddAffliction("heartdamage",Death)
				C:AddAffliction("kidneydamage",Death)
			end

			if affStr <= 5 then
				C:SetSymptomTrue("confusion", 5)
				C:AddAffliction(ID,-(.01 * NTCS_Thermal.DeltaTime))
			
			elseif affStr > 5 and affStr <= 30 then
				C:SetSymptomTrue("nausea", 5)
				KillOrgans()
			
			elseif affStr > 30 then
				C:SetSymptomTrue("nausea", 5)
				KillOrgans()
				C:AddAffliction("internalbleeding",InternalBleedingIncrease * 2 * NTCS_Thermal.DeltaTime)
				C:AddAffliction("stroke",100)
			end

		end

	end)
	:Build()
)

--Give temperature affliction, this is used to hook water and fire related stuff to the player for temperature.
-- Those aren't stored in here since they have a independent tick rate.
-- give_temp
affLoader:Register(
    builder:New("givetemp")  -- This should cause an error, this doesn't match any affliction
    :SetStrengths(0,3,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			return
		else
			THERM.IntiateCharacterTemp(C.Human)
			THERM.ValidateThermalCharacterData()
			C:SetAffliction(ID,3)
		end

	end)
	:Build()
)

-- aafn_overdose
affLoader:Register(
    builder:New("aafn_overdose")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)
		local Death = (5 * NTCS_Thermal.DeltaTime)

		if affStr > 0 then

			if C:GetAfflictionStrength("aafn") > 0 then
				C:AddAffliction(ID,Death)

			else
				C:AddAffliction(ID,Death * -1)
			end

			C:AddAffliction("cerebralhypoxia",Death)
			C:AddAffliction("lungdamage",Death)
			C:AddAffliction("liverdamage",Death)
			C:AddAffliction("heartdamage",Death)
			C:AddAffliction("kidneydamage",Death)
			C:AddAffliction("seizure",10 * NTCS_Thermal.DeltaTime)

		end

	end)
	:Build()
)

-- thermal_shock
affLoader:Register(
    builder:New("thermal_shock")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local HeadTemp = NTCS.HF.GetAfflictionStrengthLimb(C.Human, LimbType.Head, "ntt_temperature", 0)
		local LastHeadTemp = 0
		local NormalBodyTemp = FetchConfigStats().NormalBodyTemp

		if THERM.GetCharacter(C.Human.ID) ~= nil then
			LastHeadTemp = THERM.GetCharacter(C.Human.ID).LastStoredHeadTemp
		end

		if LastHeadTemp == 0 then
			LastHeadTemp = HeadTemp
		end

		local ShockMargin = FetchConfigStats().ShockMargin * NTCS_Thermal.DeltaTime
		local ShockDecrease = 2.5
		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then

			C:SetAffliction("stroke",100)
			C:SetAffliction("seizure",100)
			C:AddAffliction("neurotrauma",.05 * NTCS_Thermal.DeltaTime)
			C:AddAffliction(ID,-(ShockDecrease * NTCS_Thermal.DeltaTime))

		elseif LastHeadTemp ~= HeadTemp then
			if    HeadTemp/LastHeadTemp/2 > ShockMargin -- Too hot
				or LastHeadTemp/HeadTemp/2 > ShockMargin -- Too cold
			then
				if (HeadTemp < NormalBodyTemp and LastHeadTemp > NormalBodyTemp)
					or (HeadTemp > NormalBodyTemp and LastHeadTemp < NormalBodyTemp)
					then
					C:SetAffliction(ID,100)
				end
			end
		end

	end)
	:Build()
)

-- heat_stroke
affLoader:Register(
    builder:New("heat_stroke")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local TorsoTemp = NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0)
		local HyperthermiaLevel = FetchConfigStats().HyperthermiaLevel
		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			C:SetAffliction("seizure",100)
			C:SetSymptomTrue("blurredvision", 2)
			C:SetSymptomTrue("confusion", 2)

			if affStr > 50 then
				C:SetAffliction("heartattack",100)
			end
			if affStr > 75 then
				C:AddAffliction("neurotrauma",.1 * NTCS_Thermal.DeltaTime)
			end
			if TorsoTemp < HyperthermiaLevel * NTCS_Thermal.ExtremeHyperthermiaScaling * 1.05 then
				C:SetAffliction(ID,0)
			end
		end

	end)
	:Build()
)

-- panicking
affLoader:Register(
    builder:New("panicking")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			C:AddAffliction(ID,-10 * NTCS_Thermal.DeltaTime)
			for n, limb in pairs({LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}) do
				NTCS.HF.AddAfflictionLimb(C.Human, "onfire", limb, 1 * NTCS_Thermal.DeltaTime, C.Human)
			end
		end

	end)
	:Build()
)

-- heated_diving_suit
affLoader:Register(
    builder:New("heated_diving_suit")
    :SetStrengths(0,100,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		local HypothermiaLevel = FetchConfigStats().HypothermiaLevel

		local CharacterTable = THERM.GetCharacter(C.Human.ID,C.Human)
		if affStr > 0 then
			local LimbsToCheck2 = {LimbType.Head,LimbType.Torso,LimbType.RightArm,LimbType.LeftArm,LimbType.LeftLeg,LimbType.RightLeg}
			for index, limb in pairs(LimbsToCheck2) do
				local LimbTemp = NTCS.HF.GetAfflictionStrengthLimb(C.Human, limb, "ntt_temperature", 0)
				if LimbTemp < FetchConfigStats().NormalBodyTemp then
					local WaterKey = THERM.LimbToWaterLimbV(limb)
					local WaterCounter = NTCS.HF.Clamp(CharacterTable.LimbWaterValues[WaterKey]/1,.1,1)
					local IsCyber = NTCS.HF.BoolToNum(THERM.IsLimbCyber(C.Human,limb),1) + 1
					local TempAmount = (HypothermiaLevel/LimbTemp/25) * (affStr/100) * 10 * IsCyber * WaterCounter * NTCS_Thermal.DeltaTime * NTCS.Config.Get("HeatedDivingSuitStrength",1)
					NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", limb, TempAmount)
				end
			end
		end

		local DivingSuit = THERM.GetSuitSlot(C.Human)
		local HeadSet = THERM.GetHeadSetSlot(C.Human)
		if DivingSuit == nil then -- Remove our heating, we dont have a suit.
			C:SetAffliction(ID,0)
			return
		end
		local DivingSuitIdentifier = "BlahBlah"
		if DivingSuit ~= nil then DivingSuitIdentifier = tostring(DivingSuit.Prefab.Identifier) end
		local Helmet = THERM.GetInnerSlot(C.Human)
		local Bag = THERM.GetBagSlot(C.Human)
		local BatteryConsumption = NTCS.Config.Get("HeaterBatteryConsumption",.2) * NTCS_Thermal.DeltaTime

		local Increase = function (UseBattery, BatteryCell) -- Increase Suit Heat
			C:AddAffliction(ID,5 * NTCS_Thermal.DeltaTime)
			if UseBattery then
				BatteryCell.Condition = BatteryCell.Condition - BatteryConsumption
			end
		end

		local Decrease = function () -- Decrease Suit Heat
			C:AddAffliction(ID,-5 * NTCS_Thermal.DeltaTime)
		end

		local Compat = function () -- This is our compatibility toggle heating.
			if NTCS.Config.Get("SuitCompatiblityMode", false) or (NTCS.Config.Get("BotSuitSafteyMode", true) and C.Human.IsBot) then
					Increase(false)
					return true
			end
		end

		local ESH = function () -- This is our ESH heating.
			if Bag ~= nil and Bag.Prefab.Identifier == "esh" and Bag.OwnInventory.GetItemAt(0) ~= nil and Bag.OwnInventory.GetItemAt(0).Condition > 1 then
			local BatteryCell = Bag.OwnInventory.GetItemAt(0)
			if BatteryCell ~= nil and BatteryCell.Condition > 1 then
				Increase(true, BatteryCell)
				return true
			end
				return false
			end
		end

		local CSH = function () -- This is our CSH heating.
			if CharacterTable ~= nil and CharacterTable.CompactHeater.Equipped then

				local CompactHeaterItem = CharacterTable.CompactHeater.Item
				local CompactHeaterBattery = CompactHeaterItem.OwnInventory.GetItemAt(0)

				if CompactHeaterItem.ParentInventory == C.Human.Inventory then
					if CompactHeaterBattery ~= nil and CompactHeaterBattery.Condition > 1 then
						Increase(true, CompactHeaterBattery)
						return true
					else
						return false
					end

				else
					CharacterTable.CompactHeater.Equipped = false
					return false
				end
			end
		end

		local HSH = function () -- This is our HSH heating.
			if HeadSet ~= nil and HeadSet.Prefab.Identifier == "hsh" and HeadSet.OwnInventory.GetItemAt(0) ~= nil and HeadSet.OwnInventory.GetItemAt(0).Condition > 1 then
			local BatteryCell = HeadSet.OwnInventory.GetItemAt(0)
			if BatteryCell ~= nil and BatteryCell.Condition > 1 then
				Increase(true, BatteryCell)
				return true
			end
				return false
			end
		end
		
		local OtherHeaters = function () -- Combine together.
			-- Compat Mode
			if Compat() then return true end

			-- External Heater
			if ESH() then return true end

			-- Compact Heater
			if CSH() then return true end

			-- Heaset Heater
			if HSH() then return true end
		end
		
		if THERM.IsDivingSuit(DivingSuit) and ExceptionsToNotUSE[DivingSuitIdentifier] == nil then -- Vanilla heating. (Not immersive diving gear.)

			if OtherHeaters() then return end

			-- Internal Heater
			local HeatedSuitTable = HeatedSuits[DivingSuitIdentifier] -- Get our heated suit list version
			local Index = 1 if HeatedSuitTable then Index = HeatedSuitTable.index end -- Set the index.
			local DivingSuitInventory = DivingSuit.OwnInventory

			if (DivingSuit.HasTag("thermal")                                                                            -- Base check, does it have a thermal tag?
				or (Index ~= 1 and DivingSuit.Prefab.VariantOf ~= "" and DivingSuit.Prefab.VariantOf.HasTag("thermal"))) -- Is it a variant of a suit that has a thermal tag?
				or (HeatedSuitTable and not HeatedSuitTable.needsTag) then                                               -- Does it need a thermal tag?

				if DivingSuitInventory ~= nil and DivingSuitInventory.GetItemAt(Index) ~= nil then
					local BatteryCell = DivingSuitInventory.GetItemAt(Index)
					if THERM.IsBatteryCell(BatteryCell) and BatteryCell.Condition > 1 then
						Increase(true, BatteryCell)
						return
					end
				end
				Decrease()
			else
				Decrease()
			end

		elseif THERM.ImmersiveDivingGearEquipped(DivingSuit,Helmet) and ExceptionsToNotUSE[DivingSuitIdentifier] == nil then -- Immersive Diving Gear compat

			if OtherHeaters() then return end
			
			-- Internal Heater
			local DivingSuitInventory = DivingSuit.OwnInventory
			if DivingSuitInventory ~= nil then 
				if DivingSuitInventory.GetItemAt(0) ~= nil then
					local BatteryCell = DivingSuitInventory.GetItemAt(0)
					if THERM.IsBatteryCell(BatteryCell) and BatteryCell.Condition > 1 then
						Increase(true, BatteryCell)
						return
					end
				end
				Decrease()
			else
				Decrease()
			end

		end

	end)
	:Build()
)

--:IsSymptom(true)

-- sym_cold
affLoader:Register(
    builder:New("sym_cold")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		C:SetAffliction(ID,NTCS.HF.BoolToNum(
					not not C:HasSymptom(ID)
					and (C:HasSymptom(ID)
					or NTCS.HF.GetAfflictionStrength(C.Human, "hypothermia", 0) > 0)
					and not THERM.HasHuskSymbiosis(C.Human),
				2
			))

	end)
	:Build()
)

-- sym_shivers
affLoader:Register(
    builder:New("sym_shivers")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
		C:SetAffliction(ID,NTCS.HF.BoolToNum(
				not not C:HasSymptom(ID)
					and (C:HasSymptom(ID)
					or (NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0) < HypothermiaLevel/NTCS_Thermal.MediumHypothermiaScaling 
					and NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0) > HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling))
					and not THERM.HasHuskSymbiosis(C.Human),
				2
			))

	end)
	:Build()
)

-- sym_numb
affLoader:Register(
    builder:New("sym_numb")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
		C:SetAffliction(ID,NTCS.HF.BoolToNum(
				not not C:HasSymptom(ID)
					and (C:HasSymptom(ID)
					or NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0) < HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling
					and NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0) > 0)
					and not THERM.HasHuskSymbiosis(C.Human),
				2
			))

	end)
	:Build()
)

-- sym_runny_nose
affLoader:Register(
    builder:New("sym_runny_nose")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local HypothermiaLevel = FetchConfigStats().HypothermiaLevel
		C:SetAffliction(ID,NTCS.HF.BoolToNum(
				not not C:HasSymptom(ID)
					and (C:HasSymptom(ID)
					or (NTCS.HF.GetAfflictionStrengthLimb(C.Human, LimbType.Head, "ntt_temperature", NTCS.Config.Get("NormalBodyTemp", 38)) < HypothermiaLevel 
					and NTCS.HF.GetAfflictionStrengthLimb(C.Human, LimbType.Head, "ntt_temperature", NTCS.Config.Get("NormalBodyTemp", 38)) > HypothermiaLevel/NTCS_Thermal.ExtremeHypothermiaScaling/1.5))
					and not THERM.HasHuskSymbiosis(C.Human),
				2
			))

	end)
	:Build()
)

-- sym_hot
affLoader:Register(
    builder:New("sym_hot")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local HyperthermiaLevel = FetchConfigStats().HypothermiaLevel
		C:SetAffliction(ID,NTCS.HF.BoolToNum(
				not not C:HasSymptom(ID)
					and (C:HasSymptom(ID)
					or NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", NTCS.Config.Get("NormalBodyTemp", 38)) > HyperthermiaLevel * NTCS_Thermal.MediumHyperthermiaScaling),
				2
			))

	end)
	:Build()
)

-- sym_armswelling
affLoader:Register(
    builder:New("sym_armswelling")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		C:SetAffliction(ID,NTCS.HF.BoolToNum(
				not not C:HasSymptom(ID)
					and C:HasSymptom(ID),
				2
			))

	end)
	:Build()
)

-- sym_pins_needles
affLoader:Register(
    builder:New("sym_pins_needles")
	:IsSymptom(true)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		C:SetAffliction(ID,NTCS.HF.BoolToNum(
				not not C:HasSymptom(ID)
					and C:HasSymptom(ID),
				2
			))

	end)
	:Build()
)

-- elevated_core_temperature
affLoader:Register(
    builder:New("elevated_core_temperature")
    :SetStrengths(0,50,0)
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local NormalBodyTemp = FetchConfigStats().NormalBodyTemp
		local MaxWarmingTemp = FetchOtherStats().MaxWarmingTemp
		local LimbStrength = NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", NormalBodyTemp)
		local BloodPressureMultiplier = 3
		local ElevationDecrease = .2
		local TempIncrease = .2
		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then

			THERM.ApplyTemperatureUpdate(C.Human.ID)
			for index, limb in pairs(FetchOtherStats().LimbsToCheck) do
				local Chilled = NTCS.HF.Clamp(NTCS.HF.GetAfflictionStrengthLimb(C.Human, limb, "iced", 1)/50,1,2)
				-- If the character is a bot with the temp ignore config on or is under pressure stabilizer effect with config on, set the temperature to normal body temp
				if not (NTCS.Config.Get("BotTempIgnoreMode", true) and C.Human.IsBot)
				and not (NTCS.Config.Get("PressureStabilizerTemperature", true) and NTCS.HF.GetAfflictionStrength(C.Human, "pressurestabilized", 0) > 0) then
				NTCS.HF.AddAfflictionLimb(C.Human, "ntt_temperature", limb, 
					TempIncrease
					+ (MaxWarmingTemp/LimbStrength)/80 
					* affStr/20 
					/ Chilled
					* NTCS_Thermal.DeltaTime)
				end
			end

			affStr = C:GetAfflictionStrength(ID)
			-- Side effect of elevated_core_temperature.
			if affStr > 30 then
				C:AddAffliction("bloodpressure",(affStr/15 * BloodPressureMultiplier * NTCS_Thermal.DeltaTime))
				C:SetSymptomTrue("lightheadedness", 5)
			
			elseif affStr > 40 then
				C:AddAffliction("bloodpressure",(affStr/15 * BloodPressureMultiplier * NTCS_Thermal.DeltaTime))
				C:SetSymptomTrue("lightheadedness", 5)

				C:SetSymptomTrue("confusion", 3)
				C:AddAffliction("seizure",(10 * NTCS_Thermal.DeltaTime))
				C:AddAffliction("organdamage",(.5 * NTCS_Thermal.DeltaTime))
			end

		end

	end)
	:Build()
)

-- thrombolytics
affLoader:Register(
    builder:New("thrombolytics")
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			C:AddAffliction("bloodpressure",-(affStr/800 * NTCS_Thermal.DeltaTime))
			C:AddAffliction("kidneydamage",(affStr/10000 * NTCS_Thermal.DeltaTime))
		end

	end)
	:Build()
)

-- diuretics
affLoader:Register(
    builder:New("diuretics")
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			local BloodPressureDecrease = .05
			C:AddAffliction("bloodpressure",-(BloodPressureDecrease * NTCS_Thermal.DeltaTime))
			C:SetSymptomTrue("headache", 3)
			affStr = C:GetAfflictionStrength(ID)
			if affStr > 50 then
				C:SetSymptomTrue("bloating", 5)
			end
		end

	end)
	:Build()
)

-- aafn
affLoader:Register(
    builder:New("aafn")
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			C:AddAffliction("heartdamage",(.1 * NTCS_Thermal.DeltaTime))
			C:SetSymptomTrue("bloating", 5)
			if affStr > 25 then
				C:AddAffliction("internalbleeding",(.1 * NTCS_Thermal.DeltaTime))
				C:SetSymptomTrue("vomitingblood", 5)
				if affStr > 80 then
					C:AddAffliction("aafn_overdose",(10 * NTCS_Thermal.DeltaTime))
				end
			end
			if C:GetAfflictionStrength("drunk") > 25 then
				NTCS.HF.Explode(C.Human, 50, 5, 100, 2, 100, 0, 0)
			end
		end

	end)
	:Build()
)

-- cryo_stasis_starter
affLoader:Register(
    builder:New("cryo_stasis_starter")
    :SetPriority(NTCS.AfflictionsPriority.HIGH)
	:IsConst(true)
    :SetUpdateAction(function(C, ID, Limb, dT)

		local affStr = C:GetAfflictionStrength(ID)

		if affStr > 0 then
			C:AddAffliction("aafn_overdose",-(.15 * NTCS_Thermal.DeltaTime))

			local temp = NTCS.HF.GetAfflictionStrength(C.Human, "ntt_temperature", 0) - 1
			if temp < FetchConfigStats().HyperthermiaLevel then

				if temp <= 2 then
					NTCS.HF.AddAffliction(C.Human, "stasis", 3 * NTCS_Thermal.DeltaTime, C.Human)
				end

				local StasisBag = function ()
					local item = THERM.GetSuitSlot(C.Human)
					if item ~= nil then
						if item.Prefab.Identifier == "stasis_bag" then
							return true
						else
							return false
						end
					end
				end

				affStr = C:GetAfflictionStrength(ID)
				if affStr <= 0 or (affStr > 0 and temp > 1 and NTCS.HF.GetAfflictionStrength(C.Human, "stasis", 0) > 0 ) then
					C:SetAffliction(ID,0)
					if not StasisBag() then
						NTCS.HF.SetAffliction(C.Human, "stasis", 0)
					end
				end

			else
				C:SetAffliction(ID,0)
			end
		end

	end)
	:Build()
)

print("blood")
for i, n in pairs(FetchOtherStats().BloodAfflictions) do
	print(n)
	NTCS.NTC.AddHematologyAffliction(n)
end