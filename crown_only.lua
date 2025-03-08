
local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local thread = thread
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

local mod = Core.NewMod("Crown Only")

if mod.Config.BigCrown == nil then
    mod.Config.BigCrown = true
end
if mod.Config.SmallCrown == nil then
    mod.Config.SmallCrown = true
end

if mod.Config.BigCrownFish == nil then
    mod.Config.BigCrownFish = true
end
if mod.Config.SmallCrownFish == nil then
    mod.Config.SmallCrownFish = true
end

if mod.Config.BigCrownAnimal == nil then
    mod.Config.BigCrownAnimal = true
end
if mod.Config.SmallCrownAnimal == nil then
    mod.Config.SmallCrownAnimal = true
end

-- EmParamRandom

-- app.user_data.EnemyManagerSetting
-- ._RandomSize
-- ._RandomSizeFish

-- mod.HookFunc("app.EnemyManager", "create(app.EnemyDef.CONTEXT_SUB_CATEGORY, System.Int32, app.cContextCreateArg_Enemy, app.EnemyDef.SYNC_TYPE, via.GameObject)",
-- function (args)
--     local CreateArg = Core.Cast(args[5])
--     local id = CreateArg:get_EmID()
--     local name = Core.GetEnemyName(id)
--     -- mod.verbose("Create: %s (%d) size %d", name, id, CreateArg:get_ModelRandomSize())
--     if CreateArg:get_ModelRandomSize() >= 129 then
--         mod.verbose("????Create: %s (%d) size %d", name, id, CreateArg:get_ModelRandomSize())
--     end
--     CreateArg:call("set_ModelRandomSize(System.UInt16)", 102)
-- end)

-- local AllowLog = false
-- mod.HookFunc("app.EnemyManager", "createMainTargetContext(app.FieldDef.STAGE)",
-- function (args)
--     AllowLog = true
-- end, function (retval)
--     AllowLog = false
--     return retval
-- end)

-- mod.HookFunc("app.EnemyManager", "create(System.Int32, app.cContextCreateArg_Enemy, app.EnemyDef.SYNC_TYPE)",
-- function (args)
--     local CreateArg = Core.Cast(args[4])
--     local id = CreateArg:get_EmID()
--     local name = Core.GetEnemyName(id)
--     if AllowLog then
--         mod.verbose("Create: %s (%d) size %d", name, id, CreateArg:get_ModelRandomSize())
--     end
--     if CreateArg:get_ModelRandomSize() >= 129 then
--         mod.verbose("??Create: %s (%d) size %d", name, id, CreateArg:get_ModelRandomSize())
--     end
--     CreateArg:call("set_ModelRandomSize(System.UInt16)", 101)
-- end)

-- called by quest end, field re-gen enemies
-- app.cExFieldEvent_PopEnemy.executeProc(System.Int32)
-- returned value used in app.cContextCreateArg_Enemy . <ModelRandomSize>k__BackingField
-- mod.HookFunc("app.EnemyUtil", "lotteryModelRandomSize_Boss(app.EnemyDef.ID, app.EnemyDef.LEGENDARY_ID, System.Guid)",
-- function (args)
--     local id = sdk.to_int64(args[3])
--     local name = Core.GetEnemyName(id)
--     -- mod.verbose("Util Random: %s (%d)", name, id)
-- end, function (retval)
--     local result = 110
--     if result then
--         -- mod.verbose("Util: %s -> %s", tostring(sdk.to_int64(retval)), tostring(result))
--         return sdk.to_ptr(result)
--     end
--     return retval
-- end)

-- mod.HookFunc("app.user_data.EmParamRandomSize", "getRandomSizeTblData_Boss(app.EnemyDef.ID_Fixed, app.EnemyDef.LEGENDARY_ID, app.QuestDef.EM_REWARD_RANK, System.Int32)", function (args)
--     local id = Core.FixedToEnum("app.EnemyDef.ID", sdk.to_int64(args[3]))
--     local name = Core.GetEnemyName(id)
--     -- mod.verbose("Random: %s", name)
-- end)

mod.HookFunc("app.user_data.EmParamRandomSize.cRandomSizeData", "lottery(System.Int32)",
function (args)
    local msg = string.format("Lottery Arg: %d", sdk.to_int64(args[3]))

    local this = Core.Cast(args[2])

    local table = this._ProbDataTbl

    local biggest = 0
    local nonZeroProbBiggest = 0

    local smallest = 1000000
    local nonZeroProbSmallest = 1000000

    Core.ForEach(table, function (probData)
        local prob = probData._Prob
        local scale = probData._Scale

        if scale > biggest then
            biggest = scale
        end
        if scale < smallest then
            smallest = scale
        end

        if prob > 0 then
            if scale > nonZeroProbBiggest then
                nonZeroProbBiggest = scale
            end
            if scale < nonZeroProbSmallest then
                nonZeroProbSmallest = scale
            end
        end
    end)

    if nonZeroProbBiggest > 0 then
        msg = msg .. string.format(", Big: %s -> %s", tostring(biggest), tostring(nonZeroProbBiggest))
        biggest = nonZeroProbBiggest
    end
    if nonZeroProbSmallest < 1000000 then
        msg = msg .. string.format(", Small: %s -> %s", tostring(smallest), tostring(nonZeroProbSmallest))
        smallest = nonZeroProbSmallest
    end

    local storage = thread.get_hook_storage()
    if mod.Config.BigCrown and mod.Config.SmallCrown then
        local ran = math.random()
        if ran > 0.5 then
            storage["retval"] = biggest
            msg = msg .. string.format("\nBig: %s (%0.2f)", tostring(storage["retval"]), ran)
        else
            storage["retval"] = smallest
            msg = msg .. string.format("\nSmall: %s (%0.2f)", tostring(storage["retval"]), ran)
        end
    elseif mod.Config.BigCrown then
        storage["retval"] = biggest
        msg = msg .. string.format("\nBig: %s", tostring(storage["retval"]))
    elseif mod.Config.SmallCrown then
        storage["retval"] = smallest
        msg = msg .. string.format("\nSmall: %s", tostring(storage["retval"]))
    end

    mod.verbose(msg)
end, function (retval)
    local storage = thread.get_hook_storage()
    local result = storage["retval"]

    if result then
        mod.verbose("%s -> %s", tostring(sdk.to_int64(retval)), tostring(result))
        return sdk.to_ptr(result)
    end
    return retval
end)

mod.Menu(function ()
	local configChanged = false
    local changed = false

    imgui.text("If both options are false, the mod is disabled.")

    changed, mod.Config.BigCrown = imgui.checkbox("BigCrown", mod.Config.BigCrown)
    configChanged = configChanged or changed

    changed, mod.Config.SmallCrown = imgui.checkbox("SmallCrown", mod.Config.SmallCrown)
    configChanged = configChanged or changed

    -- changed, mod.Config.BigCrownFish = imgui.checkbox("BigCrown Fish", mod.Config.BigCrownFish)
    -- configChanged = configChanged or changed

    -- changed, mod.Config.SmallCrownFish = imgui.checkbox("SmallCrown Fish", mod.Config.SmallCrownFish)
    -- configChanged = configChanged or changed


    return configChanged
end)
