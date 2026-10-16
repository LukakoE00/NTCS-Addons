-- Apply the graft EMP effect to eligible characters inside the explosion range.
Hook.Patch(
  "Barotrauma.Explosion",
  "Explode",
  function(instance, ptable)
    if instance == nil or instance.EmpStrength == nil or instance.EmpStrength <= 0
      or instance.Attack == nil or ptable == nil then
      return
    end

    local explodeRange = instance.Attack.Range
    local explodeWorldPosition = ptable["worldPosition"]
    if explodeRange == nil or explodeRange <= 0 or explodeWorldPosition == nil then return end

    local explodeRangeSquared = explodeRange * explodeRange
    local afflictionStrength = 2 * instance.EmpStrength
    local explodeAttacker = ptable["attacker"]

    for _, character in pairs(Character.CharacterList) do
      if character.IsHuman and not character.IsDead and not character.Removed then
        local characterPosition = character.worldPosition
        local dx = characterPosition.X - explodeWorldPosition.X
        local dy = characterPosition.Y - explodeWorldPosition.Y

        -- Reject the surrounding square before performing the circle check.
        if math.abs(dx) <= explodeRange
          and math.abs(dy) <= explodeRange
          and dx * dx + dy * dy < explodeRangeSquared
          and HF.HasAfflictionLimb(character, "fractalGuardianEyesAffliction", LimbType.Head, 90) then
          HF.AddAffliction(character, "empAegis", afflictionStrength, explodeAttacker)
        end
      end
    end
  end,
  Hook.HookMethodType.After
)
