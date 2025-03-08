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
local thread = thread

local Core = require("_CatLib")

local mod = require("mhwilds_overlay.mod")
mod.EnableCJKFont(18)

-- require conf first to sort menu options
local StatusConf = require("mhwilds_overlay.status.conf")
local BossConf = require("mhwilds_overlay.boss.conf")
local DpsChartConf = require("mhwilds_overlay.dps_chart.conf")
local DpsTableConf = require("mhwilds_overlay.dps_table.conf")
local ShowAllHpConf = require("mhwilds_overlay.show_all_hp.conf")

local OverlayDrawHp = require("mhwilds_overlay.draw.hp")

-- require this first to lower render priority
local ShowAllHp = require("mhwilds_overlay.show_all_hp.draw")

local OverlayData = require("mhwilds_overlay.data")
local OverlayCollector = require("mhwilds_overlay.collector")

local Boss = require("mhwilds_overlay.boss.draw")
local BossData = require("mhwilds_overlay.boss.data")

local DpsChart = require("mhwilds_overlay.dps_chart.draw")
local DpsChartData = require("mhwilds_overlay.dps_chart.data")

local DpsTable = require("mhwilds_overlay.dps_table.draw")

local Status = require("mhwilds_overlay.status.draw")
local StatusData = require("mhwilds_overlay.status.data")

-- mod.ShowCost()

local function ClearData()
    if OverlayDrawHp then
        OverlayDrawHp.ClearData()
    end

    if OverlayData then
        OverlayData.ClearData()
    end

    if BossData and Boss then
        Boss.ClearData()
        BossData.ClearData()
    end

    if DpsChartData and DpsChart then
        DpsChartData.ClearData()
        DpsChart.ClearData()
    end

    if DpsTable then
        DpsTable.ClearData()
    end

    if Status and StatusData then
        Status.ClearCache()
        StatusData.ClearData()
    end
end

local function Init()
    if OverlayData then
        OverlayData.OnQuestPlaying()
    end

    if BossData then
        BossData.OnQuestPlaying()
    end
end

Init()

Core.OnQuestStartPlaying(function ()
    mod.verbose("OnQuestStartPlaying")
    Init()
end)

Core.OnAcceptQuest(function ()
    mod.verbose("OnAcceptQuest")
    ClearData()
end)

Core.OnPlayerChangeEquip(function ()
    mod.verbose("OnPlayerChangeEquip")
    -- ClearData()
end)

Core.OnQuestEnd(function ()
    mod.verbose("OnQuestEnd")
    if mod.Config.ClearDataAfterQuestComplete then
        ClearData()
    end
end)

local NpcUtil = Core.WrapTypedef("app.NpcUtil")

local function HandleHunterRejoin(oldHunter, newHunter)
    OverlayData.HunterInfo[newHunter] = OverlayData.HunterInfo[oldHunter]
    OverlayData.HunterInfo[oldHunter] = nil    

    if OverlayData.HunterDamageRecords[oldHunter] then
        OverlayData.HunterDamageRecords[newHunter] = OverlayData.HunterDamageRecords[oldHunter]
        OverlayData.HunterDamageRecords[oldHunter] = nil
    end
    if OverlayData.HunterEnemyDamageRecords[oldHunter] then
        OverlayData.HunterEnemyDamageRecords[newHunter] = OverlayData.HunterEnemyDamageRecords[oldHunter]
        OverlayData.HunterEnemyDamageRecords[oldHunter] = nil
    end
    if DpsChartData.HunterDpsRecord[oldHunter] then
        DpsChartData.HunterDpsRecord[newHunter] = DpsChartData.HunterDpsRecord[oldHunter]
        DpsChartData.HunterDpsRecord[oldHunter] = nil
    end
end

local function HandleCreateNPC(this)
    local npc = this._ManageControl._HunterCharacter
    if not npc then
        return
    end
        
    local hunterExtend = npc:get_HunterExtend()
    if not hunterExtend then
        return
    end
    local isNPC = hunterExtend:get_IsNpc()
    if not isNPC then
        return
    end
    local npcCtxHolder = hunterExtend:get_field("_ContextHolder") -- cNpcContextHolder
    local npcCtx = npcCtxHolder:get_Npc()
    local npcName = NpcUtil:StaticCall("getNpcName(app.NpcDef.ID)", npcCtx.NpcID)

    for hunter, data in pairs(OverlayData.HunterInfo) do
        if not data.IsNPC then
            goto continue
        end

        if data.Name == npcName then
            HandleHunterRejoin(hunter, npc)
            mod.verbose(string.format("NPC %s Rejoin Quest", data.Name))
            break
        end

        ::continue::
    end

    if OverlayData.HunterInfo[npc] then
        OverlayData.HunterInfo[npc].IsLeave = false
    end
end

Core.OnCreateNPC(function (args)
    mod.verbose("OnCreateNPC...")
    local storage = thread.get_hook_storage()
    storage["this"] = Core.Cast(args[2])
end, function (retval)
    local storage = thread.get_hook_storage()
    local this = storage["this"]
    if this then
        HandleCreateNPC(this)
    end

    return retval
end)

Core.OnRemoveNPC(function (args)
    mod.verbose("OnRemoveNPC...")
    local this = Core.Cast(args[2])
    local npc = this._ManageControl._HunterCharacter
    if not npc then
        return
    end

    local hunterExtend = npc:get_HunterExtend()
    if not hunterExtend then
        return
    end
    local isNPC = hunterExtend:get_IsNpc()
    if not isNPC then
        mod.verbose("not isNPC...")
        return
    end
    local npcCtxHolder = hunterExtend:get_field("_ContextHolder") -- cNpcContextHolder
    local npcCtx = npcCtxHolder:get_Npc()
    local npcName = NpcUtil:StaticCall("getNpcName(app.NpcDef.ID)", npcCtx.NpcID)
    mod.verbose("OnRemoveNPC %s", npcName)

    -- 全部设置为 Leave，然后根据还存在的再加回来
    for hunter, data in pairs(OverlayData.HunterInfo) do
        mod.verbose("checking %s", data.Name)
        if not data.IsNPC then
            mod.verbose("skip %s", data.Name)
            goto continue
        end

        if data.Name == npcName then
        -- if data.StableMemberIndex == int then
            OverlayData.HunterInfo[hunter].IsLeave = true
            mod.verbose(string.format("NPC %s Leave Quest", data.Name))
            break
        end

        ::continue::
    end
end)

local function HandleMemberJoin(this, guidStr, shortId)
    if shortId == "" or not shortId then
        mod.verbose("HandleMemberJoin but empty short id")
    end

    mod.verbose("HandleMemberJoin with short id: %s", shortId)
    local mgr = this

    local newChara = mgr:findPlayerInfo_UniqueID(Core.NewGuid(guidStr))
    if not newChara then
        mod.verbose("no new chara")
        return
    end

    for hunter, data in pairs(OverlayData.HunterInfo) do
        if not data.IsLeave or not data.IsPlayer or data.IsNPC then
            goto continue
        end

        mod.verbose("HandleMemberJoin checking short id: %s", data.ShortID)
        if data.ShortID == shortId then
        -- if data.StableMemberIndex == int then
            HandleHunterRejoin(hunter, newChara)
            mod.verbose(string.format("Player %s (%s) Rejoin quest", data.ShortID, data.Name))
            break
        end

        ::continue::
    end
    if OverlayData.HunterInfo[newChara] then
        OverlayData.HunterInfo[newChara].IsLeave = false
        OverlayData.HunterInfo[newChara].GUID = guidStr
    end
    -- app.PlayerManager
    -- findPlayer_UniqueID(System.Guid)
    -- _PlayerList
end

Core.OnMemberJoinQuest(function (args)
    OverlayData.RequestUpdateEnemyHealth = true

    local int = sdk.to_int64(args[4])
    local guid = Core.CastGUID(args[6]) -- hunter id
    local guidStr = Core.FormatGUID(guid)
    local shortId = Core.GetShortHunterIDFromUniqueID(guidStr)
    mod.verbose(string.format("Member join: %s of %s, short id: %s", tostring(int), guidStr, shortId))

    local storage = thread.get_hook_storage()
    storage["this"] = Core.Cast(args[2])
    storage["guidStr"] = guidStr
    storage["shortId"] = shortId
end, function (retval)
    local storage = thread.get_hook_storage()
    local this = storage["this"]
    local guidStr = storage["guidStr"]
    local shortId = storage["shortId"]
    if this then
        HandleMemberJoin(this, guidStr, shortId)
    end

    return retval
end)

-- 这个貌似本人掉线并不触发
Core.OnMemberLeaveQuest(function (args)
    OverlayData.RequestUpdateEnemyHealth = true

    local int = sdk.to_int64(args[4])
    local guid = Core.FormatGUID(Core.CastGUID(args[5]))
    local shortId = Core.GetShortHunterIDFromUniqueID(guid)
    mod.verbose(string.format("Member leave: %s of %s, short id: %s", tostring(int), guid, shortId))

    for hunter, data in pairs(OverlayData.HunterInfo) do
        if data.IsLeave or not data.IsPlayer or data.IsNPC then
            goto continue
        end

        if (shortId ~= "" and data.ShortID == shortId) or data.GUID == guid then
        -- if data.StableMemberIndex == int then
            OverlayData.HunterInfo[hunter].IsLeave = true
            mod.verbose(string.format("Leave Quest"))
            break
        end

        ::continue::
    end
end)

Core.OnLoading(function ()
    if mod.Config.ClearDataAfterQuestComplete then
        ClearData()
    end
end)
