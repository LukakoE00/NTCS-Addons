
NTCS_Symbiote.HF = {}

NTCS_Symbiote.HF.HasHusk = function(character)
    return NTCS.HF.GetAfflictionStrength(character,"huskinfection") > 0.1
end
