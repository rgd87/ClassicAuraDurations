std = "lua51"
max_line_length = false
exclude_files = {
    "**/Libs",
}
only = {
    "011", -- syntax
    "1", -- globals
    -- "3", -- Value unused
    -- "41", -- Redefining
}
ignore = {
    "11/SLASH_.*", -- slash handlers
    "1/[A-Z][A-Z][A-Z0-9_]+", -- three letter+ constants
    "211", -- Unused variable
    "212", -- Unused argument.
    "213", -- Unused loop variable
    "42", -- Shadowing
    "43", -- Shadowing an upvalue.
}
globals = {
    -- wow std api
    "abs",
    "acos",
    "asin",
    "atan",
    "atan2",
    "bit",
    "ceil",
    "cos",
    "date",
    "debuglocals",
    "debugprofilestart",
    "debugprofilestop",
    "debugstack",
    "deg",
    "difftime",
    "exp",
    "fastrandom",
    "floor",
    "forceinsecure",
    "foreach",
    "foreachi",
    "format",
    "frexp",
    "geterrorhandler",
    "getn",
    "gmatch",
    "gsub",
    "hooksecurefunc",
    "issecure",
    "issecurevariable",
    "ldexp",
    "log",
    "log10",
    "max",
    "min",
    "mod",
    "rad",
    "random",
    "scrub",
    "securecall",
    "seterrorhandler",
    "sin",
    "sort",
    "sqrt",
    "strbyte",
    "strchar",
    "strcmputf8i",
    "strconcat",
    "strfind",
    "string.join",
    "strjoin",
    "strlen",
    "strlenutf8",
    "strlower",
    "strmatch",
    "strrep",
    "strrev",
    "strsplit",
    "strsub",
    "strtrim",
    "strupper",
    "table.wipe",
    "tan",
    "time",
    "tinsert",
    "tremove",
    "wipe",


    -- everything else
    "ClassicAuraDurationsDB",

    "SetPortraitToTexture",
    "SlashCmdList",
    "CreateFrame",
    "CopyTable",
    "UnitIsUnit",
    "UnitIsFriend",
    "UnitBuff",
    "CooldownFrame_Set",
    "UnitDebuff",
    "TargetFrame_ShouldShowDebuffs",
    "TargetFrame",
    "LibStub",
    "UnitGUID",
    "TargetFrame_UpdateAuras",
    "TargetFrame",
    "PlayerFrame",
    "CooldownFrame_Clear",
    "InterfaceOptionsFrame",
    "InterfaceOptions_AddCategory",
    "UnitAura",
    "GameTooltip",
    "ReloadUI",
    "UnitCanAssist",
    "DebuffTypeColor",
    "TargetFrame_UpdateAuraPositions",
    "TargetFrame_UpdateBuffAnchor",
    "TargetFrame_UpdateDebuffAnchor",
    "Target_Spellbar_AdjustPosition",
}
