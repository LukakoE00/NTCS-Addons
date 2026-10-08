function NTNan.addAfflictionAllLimbs(character, affliction, strength)
    character.Human.CharacterHealth.ReduceAfflictionOnAllLimbs(affliction, -strength)
end