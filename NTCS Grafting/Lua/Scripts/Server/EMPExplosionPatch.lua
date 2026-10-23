--On exploding, apply EMP affliction to character in range

Hook.Patch(
"Barotrauma.Explosion",
"Explode",
function (instance, ptable)
  if instance.EmpStrength > 0 then
    local explode_empstrength = instance.EmpStrength
    local explode_range = instance.Attack.Range
    local explode_range_sq = explode_range * explode_range
    local explode_worldposition = ptable["worldPosition"]
    local explode_attacker = ptable["attacker"]

    for key, character in pairs(Character.CharacterList) do
      if character.IsHuman and not character.IsDead then
        local distance_sq = Vector2.DistanceSquared(character.worldPosition, explode_worldposition)
        if distance_sq < explode_range_sq then
          local affliction_strength = 2 * explode_empstrength
          if HF.HasAfflictionLimb(character,"fractalGuardianEyesAffliction",LimbType.Head,90) then
            HF.AddAffliction(character,"empAegis",affliction_strength,explode_attacker)
          end

        end
      end
    end
  end
end, Hook.HookMethodType.After)
