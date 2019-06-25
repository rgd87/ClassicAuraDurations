local addonName, addon = ...

local db

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    ClassicAuraDurationsDB = ClassicAuraDurationsDB or { portraitIcon = true }
    db = ClassicAuraDurationsDB

    SLASH_CLASSICAURADURATIONS1= "/cad"
    SLASH_CLASSICAURADURATIONS2= "/classicauraduration"
    SlashCmdList["CLASSICAURADURATIONS"] = self.SlashCmd

    local LibClassicDurations = LibStub("LibClassicDurations")
    LibClassicDurations:RegisterFrame(addon)

    local LibAuraTypes = LibStub("LibAuraTypes")
    local LibSpellLocks = LibStub("LibSpellLocks")

    LibClassicDurations.RegisterCallback(addon, "UNIT_BUFF", function(event, unit)
        TargetFrame_UpdateAuras(TargetFrame)
    end)

    LibSpellLocks.RegisterCallback(addon, "UPDATE_INTERRUPT", function(event, guid)
        if UnitGUID("target") == guid then
            TargetFrame_UpdateAuras(TargetFrame)
        end
    end)

    local AURA_START_X = 5;
    local AURA_START_Y = 32;
    local AURA_OFFSET_Y = 1;
    local LARGE_AURA_SIZE = 21;
    local SMALL_AURA_SIZE = 17;
    local AURA_ROW_WIDTH = 122;
    local TOT_AURA_ROW_WIDTH = 101;
    local NUM_TOT_AURA_ROWS = 2;

    local largeBuffList = {};
    local largeDebuffList = {};
    local function ShouldAuraBeLarge(caster)
        -- In Classic, all auras will be the same size.
        return true;
    end

    local portraitTexture = _G["TargetFramePortrait"];

    local auraCD = CreateFrame("Cooldown", "ClassicAuraDurationsPortraitAura", TargetFrame, "CooldownFrameTemplate")
    auraCD:SetFrameStrata("BACKGROUND")
    auraCD:SetDrawEdge(false);
    -- auraCD:SetHideCountdownNumbers(true);
    auraCD:SetReverse(true)
    auraCD:SetSwipeTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMaskSmall")
    auraCD:SetAllPoints(portraitTexture)

    local auraIconTexture = auraCD:CreateTexture(nil, "BORDER", nil, 2)
    auraIconTexture:SetAllPoints(portraitTexture)
    -- auraIconTexture:Hide()
    -- SetPortraitToTexture(auraIconTexture, 136039)
    auraCD:Hide()

    hooksecurefunc("TargetFrame_UpdateAuras", function(self)
        local frame, frameName;
        local frameIcon, frameCount, frameCooldown;
        local numBuffs = 0;
        local playerIsTarget = UnitIsUnit(PlayerFrame.unit, self.unit);
        local selfName = self:GetName();
        local canAssist = UnitCanAssist("player", self.unit);


        local unit = self.unit
        --[[ PORTRAIT AURA ]]
        local maxPrio = 0
        local maxPrioFilter
        local maxPrioIndex = 1

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

                    --[[ PORTRAIT AURA ]]
                    if db.portraitIcon then
                        local rootSpellID, spellType, prio = LibAuraTypes.GetDebuffInfo(spellId)
                        if prio and prio > maxPrio then
                            maxPrio = prio
                            maxPrioIndex = i
                            maxPrioFilter = "HELPFUL"
                        end
                    end

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

                        --[[ PORTRAIT AURA ]]
                        if db.portraitIcon then
                            local rootSpellID, spellType, prio = LibAuraTypes.GetDebuffInfo(spellId)
                            if prio and prio > maxPrio then
                                maxPrio = prio
                                maxPrioIndex = index
                                maxPrioFilter = "HARMFUL"
                            end
                        end

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

        --[[ PORTRAIT AURA ]]
        if db.portraitIcon then
            local isLocked = LibSpellLocks:GetSpellLockInfo(unit)
            local PRIO_SILENCE = LibAuraTypes.GetDebuffTypePriority("SILENCE")
            if isLocked and PRIO_SILENCE > maxPrio then
                maxPrio = PRIO_SILENCE
                maxPrioIndex = -1
            end

            if maxPrio >= PRIO_SILENCE then
                local name, icon, _, _, duration, expirationTime, caster, _,_, spellId
                if maxPrioIndex == -1 then
                    spellId, name, icon, duration, expirationTime = LibSpellLocks:GetSpellLockInfo(unit)
                else
                    name, icon, _, _, duration, expirationTime, caster, _,_, spellId = LibClassicDurations:UnitAura(unit, maxPrioIndex, maxPrioFilter)
                    local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, caster)
                    if duration == 0 and durationNew then
                        duration = durationNew
                        expirationTime = expirationTimeNew
                    end
                end
                SetPortraitToTexture(auraIconTexture, icon)
                portraitTexture:Hide()
                auraCD:SetCooldown(expirationTime-duration, duration)
                auraCD:Show()
                -- auraIconTexture:Show()
            else
                auraCD:Hide()
                portraitTexture:Show()
                -- auraIconTexture:Hide()
            end
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

    --[[
    -- fuck this, PartyDebuffFrameTemplate doesn't create PartyMemberFrame1Debuff1Cooldown, even on live
    -- ToT frame does ( and also using this), but it also just spams this function in some OnUpdate probably

    hooksecurefunc("RefreshDebuffs", function(frame, unit, numDebuffs, suffix, checkCVar)
        if not unit:find("party") then return end

        local frameName = frame:GetName();
        numDebuffs = numDebuffs or MAX_PARTY_DEBUFFS;
        suffix = suffix or "Debuff";
        local filter;
        if ( checkCVar and SHOW_DISPELLABLE_DEBUFFS == "1" and UnitCanAssist("player", unit) ) then
            filter = "RAID";
        end

        for i=1, numDebuffs do
            local name, icon, count, debuffType, duration, expirationTime, caster, _, _, spellId = UnitDebuff(unit, i, filter);

            local debuffName = frameName..suffix..i;
            print(unit, i, numDebuffs, name, spellId, caster)
            if ( icon and ( SHOW_CASTABLE_DEBUFFS == "0" or not isEnemy or caster == "player" ) ) then
                -- if we have an icon to show then proceed with setting up the aura

                print(name, spellId, caster)
                local durationNew, expirationTimeNew = LibClassicDurations:GetAuraDurationByUnit(unit, spellId, caster)
                if duration == 0 and durationNew then
                    duration = durationNew
                    expirationTime = expirationTimeNew


                    local cdname = debuffName.."Cooldown"
                    local coolDown = _G[debuffName.."Cooldown"];
                    print("got duration", coolDown, frameName, cdname)
                    if ( coolDown ) then
                        print("setting", coolDown, expirationTime - duration, duration)
                        CooldownFrame_Set(coolDown, expirationTime - duration, duration, true);
                    end
                end
            end
        end

    end)
    ]]
end)





f.Commands = {
    ["portraiticon"] = function(v)
        db.portraitIcon = not db.portraitIcon
    end,
}

local helpMessage = {
    "|cff00ff00/cad portraiticon|r",
}

function f.SlashCmd(msg)
    local k,v = string.match(msg, "([%w%+%-%=]+) ?(.*)")
    if not k or k == "help" then
        print("Usage:")
        for k,v in ipairs(helpMessage) do
            print(" - ",v)
        end
    end
    if f.Commands[k] then
        f.Commands[k](v)
    end
end