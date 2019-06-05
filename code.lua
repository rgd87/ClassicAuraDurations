local addonName, addon = ...

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    local LibClassicDurations = LibStub("LibClassicDurations")
    LibClassicDurations:RegisterFrame(addon)

    hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        local frame, frameName;
        local frameIcon, frameCount, frameCooldown;
        local numBuffs = 0;
        -- local playerIsTarget = UnitIsUnit(PlayerFrame.unit, self.unit);
        local selfName = self:GetName();

        for i = 1, MAX_TARGET_BUFFS do
            local buffName, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, _ , spellId, _, _, casterIsPlayer, nameplateShowAll = UnitBuff(self.unit, i, nil);
            if (buffName) then
                frameName = selfName.."Buff"..(i);
                frame = _G[frameName];

                -- Handle cooldowns
                frameCooldown = _G[frameName.."Cooldown"];
                local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(self.unit, spellId, caster)
                if durationNew then
                    duration = durationNew
                    expirationTime = expirationTimeNew
                end

                CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);
            end
        end


        local numDebuffs = 0;
        local frameNum = 1;
        local index = 1;

        local maxDebuffs = self.maxDebuffs or MAX_TARGET_DEBUFFS;
        while ( frameNum <= maxDebuffs and index <= maxDebuffs ) do
            local debuffName, icon, count, debuffType, duration, expirationTime, caster, _, _, spellId, _, _, casterIsPlayer, nameplateShowAll = UnitDebuff(self.unit, index, "INCLUDE_NAME_PLATE_ONLY");
            if ( debuffName ) then
                if ( TargetFrame_ShouldShowDebuffs(self.unit, caster, nameplateShowAll, casterIsPlayer) ) then
                    frameName = selfName.."Debuff"..frameNum;
                    frame = _G[frameName];

                    -- Handle cooldowns
                    frameCooldown = _G[frameName.."Cooldown"];
                    local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(self.unit, spellId, caster)
                    if durationNew then
                        duration = durationNew
                        expirationTime = expirationTimeNew
                    end
					CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);

                    frameNum = frameNum + 1;
                end
            else
                break;
            end
            index = index + 1;
        end
    end)

    hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, unit, index, filter)
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = UnitBuff(unit, index, filter);
        local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, unitCaster)
        if durationNew then
            duration = durationNew
            expirationTime = expirationTimeNew
        end
        local enabled = expirationTime and expirationTime ~= 0;
        if enabled then
            local startTime = expirationTime - duration;
            CooldownFrame_Set(buffFrame.cooldown, startTime, duration, true);
        else
            CooldownFrame_Clear(buffFrame.cooldown);
        end
    end)

    hooksecurefunc("CompactUnitFrame_UtilSetDebuff", function(debuffFrame, unit, index, filter, isBossAura, isBossBuff)
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId;
        if (isBossBuff) then
            name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitBuff(unit, index, filter);
        else
            name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId = UnitDebuff(unit, index, filter);
        end

        local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, unitCaster)
        if durationNew then
            duration = durationNew
            expirationTime = expirationTimeNew
        end

        local enabled = expirationTime and expirationTime ~= 0;
        if enabled then
            local startTime = expirationTime - duration;
            CooldownFrame_Set(debuffFrame.cooldown, startTime, duration, true);
        else
            CooldownFrame_Clear(debuffFrame.cooldown);
        end
    end)
end)