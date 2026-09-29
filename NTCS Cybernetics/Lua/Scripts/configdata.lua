NTCS_Cybernetics.ConfigData = {
	
	NTCS_Cybernetics_waterDamage = {
		name = "Cyberlimb Water Damage",
		default = 1,
		range = { 0, 5 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 2 },
	},

	NTCS_Cybernetics_cyberpsychosisChance = {
		name = "Cyberpsychosis Chance",
		default = 1,
		range = { 0, 1 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 2 },
	},

	NTCS_Cybernetics_cyberarmSpeed = {
		name = "Cyberarm Speed Increase",
		default = 1,
		range = { 0, 2 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 2 },
	},
	
	NTCS_Cybernetics_cyberlegSpeed = {
		name = "Cyberleg Speed Increase",
		default = 1,
		range = { 0, 2 },
		type = "float",
		difficultyCharacteristics = { multiplier = 0.5, max = 2 },
	},
}

NTCS.Config.AddConfigOptions(NTCS_Cybernetics)
