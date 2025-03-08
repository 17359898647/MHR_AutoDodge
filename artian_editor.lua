local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local string = string
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local table = table
local _ = _
local math = math

local Core = require("_CatLib")
local Imgui = require("_CatLib.imgui")

local mod = Core.NewMod("Artian Editor")
mod.EnableCJKFont(18) -- if needed

local PerformanceTypeNames = Core.GetEnumMap("app.ArtianDef.PERFORMANCE_TYPE")
local BonusTypeNames = Core.GetEnumMap("app.ArtianDef.BONUS_ID")

local Get_PerformanceType = Core.TypeMethod("app.ArtianUtil", "getPerformanceType(app.savedata.cEquipWork)")
local Get_BonusList = Core.TypeMethod("app.ArtianUtil", "getBonusIdList(app.savedata.cEquipWork)")
local Get_PerformanceTypeName = Core.TypeMethod("app.ArtianUtil", "Name(app.ArtianDef.PERFORMANCE_TYPE)")
local Get_BonusTypeName = Core.TypeMethod("app.ArtianUtil", "Name(app.ArtianDef.BONUS_ID)")
local Get_BonusData = Core.TypeMethod("app.ArtianUtil", "Data(app.ArtianDef.BONUS_ID)")

local Get_WeaponData = Core.TypeMethod("app.WeaponUtil", "getWeaponData(app.savedata.cEquipWork)")

local ArtianDataInited = false
local Valid_CreateBonusNames
local Valid_GrindBonusNames
local PerformanceTypeNames_WithAttributeBoost

local function InitArtianNames()
    if ArtianDataInited then
        return
    end
    Valid_CreateBonusNames = {
        [1] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 1)),
        [2] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 2))
    }
    Valid_GrindBonusNames = {
        [0] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 0)),
        [4] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 4)),
        [5] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 5)),
        [6] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 6)),
        [7] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 7))
    }


    PerformanceTypeNames_WithAttributeBoost = {}

    local mgr = Core.GetVariousDataManager()
    local perf = mgr._Setting._EquipDatas._ArtianDataSetting._PerformanceData

    Core.ForEach(perf._Values, function (data)
        local perfType = data:get_PerformanceType()
        local bonus = data:get_BonusId()
        local name = Core.GetLocalizedText(data._Name)
        if bonus > 0 then
            name = name .. " " .. Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonus))
        end
        PerformanceTypeNames_WithAttributeBoost[perfType] = name
    end)


    ArtianDataInited = true
end

local function EquipBoxEditor()
    local mgr = Core.GetVariousDataManager()
    if not mgr then
        return
    end

    local data = mgr._Setting._EquipDatas
    -- sdk.get_managed_singleton("app.SaveDataManager"):getCurrentUserSaveData():get_Equip()._EquipBox:get_Item(98)

    local mgr = Core.GetSaveDataManager()
    if not mgr then
        return false
    end
    InitArtianNames()

    local configChanged = false
    local changed = false
    local box = mgr:getCurrentUserSaveData()._Equip._EquipBox

    Core.ForEach(box, function (work, i)
        local category = work:get_Category()
        if category ~= 1 then
            return
        end
        if work.BonusByCreating <= 0 then
            return
        end

        local wpData = Get_WeaponData:call(nil, work)
        local wpName = Core.GetLocalizedText(wpData._Name)
        local perfType = Get_PerformanceType:call(nil, work)
        local perfName = PerformanceTypeNames_WithAttributeBoost[perfType]

        imgui.push_id(string.format("WpIndex%d", i))
        local open = imgui.tree_node(string.format("%s##WpIndex%d", wpName, i))
        imgui.same_line()
        imgui.text(perfName)
        if open then
            if mod.Config.Debug then
                imgui.text(string.format("Weapon %d", i))
                local fixedPerfType = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
                imgui.text(string.format("%s: %d (%d)", perfName, perfType, fixedPerfType))
            end

            changed, perfType = imgui.combo("Element Type", perfType, PerformanceTypeNames_WithAttributeBoost)
            if changed then
                work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
            end

            Imgui.Rect(function ()
                configChanged = false
                imgui.text(string.format("Production Bonus"))
                local bonusData = work.BonusByCreating

                if mod.Config.Debug then
                    imgui.text(string.format("value: %d", bonusData))
                end

                local first = bonusData % 1000
                local second = math.floor(bonusData/1000) % 1000
                local third = math.floor(bonusData/1000000) % 1000

                first = Core.FixedToEnum("app.ArtianDef.BONUS_ID", first)
                second = Core.FixedToEnum("app.ArtianDef.BONUS_ID", second)
                third = Core.FixedToEnum("app.ArtianDef.BONUS_ID", third)

                changed, first = imgui.combo("First Bonus##CreateFirst", first, Valid_CreateBonusNames)
                configChanged = configChanged or changed

                changed, second = imgui.combo("Second Bonus##CreateSecond", second, Valid_CreateBonusNames)
                configChanged = configChanged or changed

                changed, third = imgui.combo("Third Bonus##CreateThird", third, Valid_CreateBonusNames)
                configChanged = configChanged or changed

                if configChanged then
                    local result = 0

                    first = Core.EnumToFixed("app.ArtianDef.BONUS_ID", first)
                    second = Core.EnumToFixed("app.ArtianDef.BONUS_ID", second)
                    third = Core.EnumToFixed("app.ArtianDef.BONUS_ID", third)

                    result = third
                    result = result * 1000 + second
                    result = result * 1000 + first
                    work.BonusByCreating = result
                end
            end)

            Imgui.Rect(function ()
                configChanged = false
                imgui.text(string.format("Reinforcement Bonus"))
                local bonusData = work.BonusByGrinding

                if mod.Config.Debug then
                    imgui.text(string.format("value: %d", bonusData))
                end

                local first = bonusData % 1000

                bonusData = math.floor(bonusData/1000)
                local second = bonusData % 1000

                bonusData = math.floor(bonusData/1000)
                local third = bonusData % 1000

                bonusData = math.floor(bonusData/1000)
                local fourth = bonusData % 1000

                bonusData = math.floor(bonusData/1000)
                local fifth = bonusData % 1000

                first = Core.FixedToEnum("app.ArtianDef.BONUS_ID", first)
                second = Core.FixedToEnum("app.ArtianDef.BONUS_ID", second)
                third = Core.FixedToEnum("app.ArtianDef.BONUS_ID", third)
                fourth = Core.FixedToEnum("app.ArtianDef.BONUS_ID", fourth)
                fifth = Core.FixedToEnum("app.ArtianDef.BONUS_ID", fifth)

                changed, first = imgui.combo("First Bonus##GrindFirst", first, Valid_GrindBonusNames)
                configChanged = configChanged or changed

                changed, second = imgui.combo("Second Bonus##GrindSecond", second, Valid_GrindBonusNames)
                configChanged = configChanged or changed

                changed, third = imgui.combo("Third Bonus##GrindThird", third, Valid_GrindBonusNames)
                configChanged = configChanged or changed

                changed, fourth = imgui.combo("Fourth Bonus##GrindFourth", fourth, Valid_GrindBonusNames)
                configChanged = configChanged or changed

                changed, fifth = imgui.combo("Fifth Bonus##GrindFifth", fifth, Valid_GrindBonusNames)
                configChanged = configChanged or changed

                -- bonus count validation
                local bonus_list = {first, second, third, fourth, fifth}
                local bonus_id_count = {}
                for _, bonus_id in ipairs(bonus_list) do
                    local b_data = Get_BonusData:call(nil, bonus_id)
                    if b_data then
                        bonus_id_count[bonus_id] = (bonus_id_count[bonus_id] or 0) + 1
                    else
                        log.warn("Invalid bonus id: ", bonus_id)
                    end
                end
                for bonus_id, count in pairs(bonus_id_count) do
                    local b_data = Get_BonusData:call(nil, bonus_id)
                    if count > b_data._GrindingMaxNum then
                        imgui.text_colored(string.format(
                            "Warning: Bonus `%s` has exceeded\n  the max count of grinding.\nThe max count is %d, but current count is %d.",
                            Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonus_id)), b_data._GrindingMaxNum, count),
                            Core.ReverseRGB(0xffff8000))
                    end
                end

                if configChanged then
                    local result = 0

                    first = Core.EnumToFixed("app.ArtianDef.BONUS_ID", first)
                    second = Core.EnumToFixed("app.ArtianDef.BONUS_ID", second)
                    third = Core.EnumToFixed("app.ArtianDef.BONUS_ID", third)
                    fourth = Core.EnumToFixed("app.ArtianDef.BONUS_ID", fourth)
                    fifth = Core.EnumToFixed("app.ArtianDef.BONUS_ID", fifth)

                    local num = 0

                    -- we assign the value directly because if we have values like 11011
                    -- which is invalid in vanilla game but possible with Editor
                    -- in this situation, we count num=4 but the game reads only 1011
                    -- so the fifth bonus is ignored
                    if first > 0 then
                        num = 1
                    end
                    if second > 0 then
                        num = 2
                    end
                    if third > 0 then
                        num = 3
                    end
                    if fourth > 0 then
                        num = 4
                    end
                    if fifth > 0 then
                        num = 5
                    end

                    result = fifth
                    result = result * 1000 + fourth
                    result = result * 1000 + third
                    result = result * 1000 + second
                    result = result * 1000 + first
                    work.BonusByGrinding = result
                    work.GrindingNum = num
                end
            end)

            if mod.Config.Debug then
                local bonusList = Get_BonusList:call(nil, work)
                Core.ForEach(bonusList, function(bonusId)
                    local fixedBonusId = Core.EnumToFixed("app.ArtianDef.BONUS_ID", bonusId)
                    local bonusName = Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonusId))

                    imgui.text(string.format("  %s: %d (%d)", bonusName, bonusId, fixedBonusId))
                end)
            end

            imgui.tree_pop()
        end
        imgui.pop_id()
    end)

    return configChanged
end

mod.Menu(function()
    EquipBoxEditor()
end)
