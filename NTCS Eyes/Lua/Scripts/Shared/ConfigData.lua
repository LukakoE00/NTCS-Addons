--define the config options needed
NTCS_Eyes.ConfigData = {
	NTEYE_lightBoost = {
		name = "Default Light Level",
		description = "Modifies the amount of light (RGBA alpha value) each eye has. 'cl_reloadlua' is required to take effect.",
		default = 0,
		range = { -255, 255 },
		type = "float",
		group = true,
	},

	NTEYE_eyeDamageMultiplier = {
		name = "Eye Biological Damage Multiplier",
		description = "Multiplies the biological eye damage amount by the number set.",
		default = 1,
		range = { 0, 10 },
		type = "float",
		group = true,
	},

	NTEYE_pressureDamageMultiplier = {
		name = "Eye Pressure Damage Multiplier",
		description = "Multiplies the water presure eye damage amount by the number set.",
		default = 1,
		range = { 0, 10 },
		type = "float",
		group = true,
	},

	NTEYE_cataractChanceMultiplier = {
		name = "Cataract Chance Multiplier",
		description = "Multiplies the cataract chance value (0.03) by the number set.",
		default = 1,
		range = { 0, 10 },
		type = "float",
		group = true,
	},

	NTEYE_disableRetinopathy = {
		name = "Disable Retinopathy",
		description = "Disables the retinopathy chance upon having a dead eye.",
		default = false,
		type = "bool",
	},
}

NTCS.Config.AddConfigOptions(NTCS_Eyes)
