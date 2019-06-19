local addonName, addon = ...

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    local LibClassicDurations = LibStub("LibClassicDurations")
    LibClassicDurations:RegisterFrame(addon)

    LibClassicDurations.RegisterCallback(addon, "UNIT_BUFF", function(event, unit)
        TargetFrame_UpdateAuras(TargetFrame)
    end)

    local AURA_ROW_WIDTH = 122;
    local TOT_AURA_ROW_WIDTH = 101;

    local largeBuffList = {};
    local largeDebuffList = {};
    local function ShouldAuraBeLarge(caster)
        -- In Classic, all auras will be the same size.
        return true;
    end

    hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        local frame, frameName;
        local frameIcon, frameCount, frameCooldown;
        local numBuffs = 0;
        local playerIsTarget = UnitIsUnit(PlayerFrame.unit, self.unit);
        local selfName = self:GetName();
        local canAssist = UnitCanAssist("player", self.unit);

        for i = 1, MAX_TARGET_BUFFS do
            local buffName, icon, count, debuffType, duration, expirationTime, caster, canStealOrPurge, _ , spellId, _, _, casterIsPlayer, nameplateShowAll = LibClassicDurations:UnitAura(self.unit, i, "HELPFUL");
            if (buffName) then
                frameName = selfName.."Buff"..(i);
                frame = _G[frameName];
                if ( not frame ) then
                    if ( not icon ) then
                        break;
                    else
                        frame = CreateFrame("Button", frameName, self, "TargetBuffFrameTemplate");
                        frame.unit = self.unit;
                    end
                end
                if ( icon and ( not self.maxBuffs or i <= self.maxBuffs ) ) then
                    frame:SetID(i);

                    -- set the icon
                    frameIcon = _G[frameName.."Icon"];
                    frameIcon:SetTexture(icon);

                    -- set the count
                    frameCount = _G[frameName.."Count"];
                    if ( count > 1 and self.showAuraCount ) then
                        frameCount:SetText(count);
                        frameCount:Show();
                    else
                        frameCount:Hide();
                    end

                    -- Handle cooldowns
                    frameCooldown = _G[frameName.."Cooldown"];
                    local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(self.unit, spellId, caster)
                    if duration == 0 and durationNew then
                        duration = durationNew
                        expirationTime = expirationTimeNew
                    end
                    CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);

                    -- Show stealable frame if the target is not the current player and the buff is stealable.
                    local frameStealable = _G[frameName.."Stealable"];
                    if ( not playerIsTarget and canStealOrPurge ) then
                        frameStealable:Show();
                    else
                        frameStealable:Hide();
                    end

                    -- set the buff to be big if the buff is cast by the player or his pet
                    numBuffs = numBuffs + 1;
                    largeBuffList[numBuffs] = ShouldAuraBeLarge(caster);

                    frame:ClearAllPoints();
                    frame:Show();
                else
                    frame:Hide();
                end
            else
                break;
            end
        end

        for i = numBuffs + 1, MAX_TARGET_BUFFS do
            local frame = _G[selfName.."Buff"..i];
            if ( frame ) then
                frame:Hide();
            else
                break;
            end
        end

        local color;
        local frameBorder;
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
                    if ( icon ) then
                        if ( not frame ) then
                            frame = CreateFrame("Button", frameName, self, "TargetDebuffFrameTemplate");
                            frame.unit = self.unit;
                        end
                        frame:SetID(index);

                        -- set the icon
                        frameIcon = _G[frameName.."Icon"];
                        frameIcon:SetTexture(icon);

                        -- set the count
                        frameCount = _G[frameName.."Count"];
                        if ( count > 1 and self.showAuraCount ) then
                            frameCount:SetText(count);
                            frameCount:Show();
                        else
                            frameCount:Hide();
                        end

                        -- Handle cooldowns
                        frameCooldown = _G[frameName.."Cooldown"];
                        local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(self.unit, spellId, caster)
                        if duration == 0 and durationNew then
                            duration = durationNew
                            expirationTime = expirationTimeNew
                        end
                        CooldownFrame_Set(frameCooldown, expirationTime - duration, duration, duration > 0, true);

                        -- set debuff type color
                        if ( debuffType ) then
                            color = DebuffTypeColor[debuffType];
                        else
                            color = DebuffTypeColor["none"];
                        end
                        frameBorder = _G[frameName.."Border"];
                        frameBorder:SetVertexColor(color.r, color.g, color.b);

                        -- set the debuff to be big if the buff is cast by the player or his pet
                        numDebuffs = numDebuffs + 1;
                        largeDebuffList[numDebuffs] = ShouldAuraBeLarge(caster);

                        frame:ClearAllPoints();
                        frame:Show();

                        frameNum = frameNum + 1;
                    end
                end
            else
                break;
            end
            index = index + 1;
        end

        for i = frameNum, MAX_TARGET_DEBUFFS do
            local frame = _G[selfName.."Debuff"..i];
            if ( frame ) then
                frame:Hide();
            else
                break;
            end
        end

        self.auraRows = 0;

        local mirrorAurasVertically = false;
        if ( self.buffsOnTop ) then
            mirrorAurasVertically = true;
        end
        local haveTargetofTarget;
        if ( self.totFrame ) then
            haveTargetofTarget = self.totFrame:IsShown();
        end
        self.spellbarAnchor = nil;
        local maxRowWidth;
        -- update buff positions
        maxRowWidth = ( haveTargetofTarget and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
        TargetFrame_UpdateAuraPositions(self, selfName.."Buff", numBuffs, numDebuffs, largeBuffList, TargetFrame_UpdateBuffAnchor, maxRowWidth, 3, mirrorAurasVertically);
        -- update debuff positions
        maxRowWidth = ( haveTargetofTarget and self.auraRows < NUM_TOT_AURA_ROWS and self.TOT_AURA_ROW_WIDTH ) or AURA_ROW_WIDTH;
        TargetFrame_UpdateAuraPositions(self, selfName.."Debuff", numDebuffs, numBuffs, largeDebuffList, TargetFrame_UpdateDebuffAnchor, maxRowWidth, 3, mirrorAurasVertically);
        -- update the spell bar position
        if ( self.spellbar ) then
            Target_Spellbar_AdjustPosition(self.spellbar);
        end
    end)

    hooksecurefunc("CompactUnitFrame_UtilSetBuff", function(buffFrame, unit, index, filter)
        local name, icon, count, debuffType, duration, expirationTime, unitCaster, canStealOrPurge, _, spellId, canApplyAura = UnitBuff(unit, index, filter);
        local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, unitCaster)
        if duration == 0 and durationNew then
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
        if duration == 0 and durationNew then
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