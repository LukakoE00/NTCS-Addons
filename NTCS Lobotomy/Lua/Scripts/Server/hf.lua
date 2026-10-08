NTCS_Lobotomy.eyes = {"human", "cyber", "enhanced", "plastic", "husk", "crawler", "mudraptor", "hammerhead", "watcher", "latcher", "terror"}
-- charybdis eye damage exists but seems like no corresponding eye affliction exists ? is it a remnant of old code ?

function NTCS_Lobotomy.DealEyeDamage(target, strength)
    for _,name in NTCS_Lobotomy.eyes do
        
        if target:HasAfflictionLimb("vi_"..name, LimbType.Head) then
            target:AddAfflictionLimb("dm_"..name, LimbType.Head, strength)
        end
    end
end