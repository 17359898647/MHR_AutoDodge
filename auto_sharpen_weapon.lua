local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local require = require
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local type = type

local Core = require("_CatLib")
local CONST = require("_CatLib.const")

local mod = Core.NewMod("Auto Sharpen Weapon")

if mod.Config.SendNotification == nil then
    mod.Config.SendNotification = true
end

if mod.Config.SharpenOutOfBattle == nil then
    mod.Config.SharpenOutOfBattle = true
end

local NOTIFICATIONS = {
    [CONST.LanguageType.English] = "Weapon sharpened",
    [CONST.LanguageType.TraditionalChinese] = "武器已打磨",
    [CONST.LanguageType.SimplifiedChinese] = "武器已打磨",
}

local function Localized()
    local lang = Core.GetLanguage()
    if not NOTIFICATIONS[lang] then
        lang = CONST.LanguageType.English
    end

    return NOTIFICATIONS[lang]
end

local function FillKireaji()
    local mainWeapon = Core.GetPlayerWeaponHandling() -- app.cHunterWp03Handling -> app.cHunterWeaponHandlingBase
    if mainWeapon ~= nil then
        local kireaji = mainWeapon:get_Kireaji() -- app.cWeaponKireaji
        if kireaji ~= nil then
            kireaji:resetKireaji()
        end
    end

    local subWeapon = Core.GetPlayerSubWeaponHandling()
    if subWeapon ~= nil then
        local kireaji =subWeapon:get_Kireaji()
        if kireaji ~= nil then
            kireaji:resetKireaji()
        end
    end

    if mod.Config.SendNotification then
        local msg = Localized()
        Core.SendMessage(msg)
    end
end

local NeedSharpen = false
mod.OnUpdateBehavior(function ()
    if not mod.Config.SharpenOutOfBattle then
        return
    end

    local isInBattle = Core.IsInBattle()
    if not NeedSharpen and isInBattle then
        NeedSharpen = true
    elseif NeedSharpen and not isInBattle then
        NeedSharpen = false
        FillKireaji()
    end
end)

Core.OnQuestEnd(function ()
    if mod.Config.Enabled then
        FillKireaji()
    end
end)

mod.Menu(function ()
    local configChanged = false
    local changed

    changed, mod.Config.SendNotification = imgui.checkbox("Send Notification", mod.Config.SendNotification)
    configChanged = configChanged or changed

    changed, mod.Config.SharpenOutOfBattle = imgui.checkbox("Sharpen Out Of Battle", mod.Config.SharpenOutOfBattle)
    configChanged = configChanged or changed

    if imgui.button("Manual Sharpen") then
        FillKireaji()
    end

    return configChanged
end)

-- 快速出发/接取任务/接取任务完成 -- 不用，因为传送会恢复 app.cHunterStatus.resetOnSceneLoadEnd(app.HunterCharacter)
-- 打醒任务开始 -- 可能需要，取决于用户配置。额外配置：当且仅当斩味消耗超过 x 时重置
-- 打醒任务：成功 -- 需要，这就是目的
-- 打醒任务：重置/失败/超时 -- 貌似也会传送，所以不需要
-- 角色死亡 -- 配置
