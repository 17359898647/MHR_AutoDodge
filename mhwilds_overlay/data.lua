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

local mod = require("mhwilds_overlay.mod")

local _M = {}

_M.IsQuestHost = true

function _M.RefreshQuestHost()
    mod.verbose("RefreshQuestHost...")
    if Core.IsActiveQuest then
        -- local isQuestHost = NetUtil:StaticCall("isMultiplayHost(System.Boolean)")
        local mgr = Core.GetNetworkManager()
        local userInfoManager = mgr:get_UserInfoManager()
        local userInfo = userInfoManager:call("getHostUserInfo(app.net_session_manager.SESSION_TYPE)", 2)
        if userInfo then
            _M.IsQuestHost = userInfo:get_IsSelf()
            mod.verbose("IsQuestHost: %s", tostring(_M.IsQuestHost))
        end
    end
end

Core.HookFunc("app.cQuestDirector", "notifyHostChangeQuestSession(System.Int32)",
function (args)
    Core.SendMessage("Notify Host Change %d", sdk.to_int64(args[3]))
end, function (retval)
    _M.RefreshQuestHost()
    
    return retval
end)

local NetUtil = Core.WrapTypedef("app.NpcUtilNet")
-- app.cNpcPartnerManager removeRescurePartner_NpcId(System.Int32, System.Boolean)
-- app.cNpcPartnerManageControl.remove(app.cNpcPartnerManageControl.REMOVE_TYPE)
function _M.OnQuestPlaying()
    mod.verbose("OnQuestPlaying")
    _M.ClearData()

    _M.RefreshQuestHost()

    local isQuest = Core.IsActiveQuest()
    if isQuest then
        -- call this every frame will leak some memory
        local browsers = Core.GetMissionManager():getAcceptQuestTargetBrowsers()
        if browsers then
            Core.ForEach(browsers, function (browser)
                local ctx = browser:get_EmContext()
                table.insert(_M.QuestStats.EnemyContexts, ctx)
            end)
        end
    end
end

_M.SimulatedTime = 0


---@alias Hunter app.HunterCharacter
---@alias Otomo app.OtomoCharacter
---@alias Attacker Hunter|Otomo

---@alias EnemyContext app.cEnemyContext
---@alias Enemy app.EnemyCharacter
---@alias ACCESS_KEY app.TARGET_ACCESS_KEY

---@class HunterData
---@field GUID string -- 非 NPC 玩家 GUID, 猫没有
---@field ShortID string -- 非 NPC 玩家 ShortHunterID
---@field StableMemberIndex integer
---@field Name string
---@field IsPlayer boolean -- Is hunter or Otomo
---@field IsNPC boolean
---@field IsLeave boolean -- 检测是否已经离开任务
---@field WeaponType number
---@field HR integer
---@field MR integer
---@field ID string
---@field StartQuestTime number
---@field FirstHitTime number
---@field FightingTime number
---@field IsCombatBoss boolean -- 临时数据，计时用
---@field LastCombatBossStartTime number -- 临时数据，计时用
---@field HitCount number -- 命中数（不含爆破、毒、集中攻击伤口爆裂、骑乘终结伤口爆裂）
---@field CriticalCount number
---@field NegCriticalCount number
---@field NoCriticalHitCount number -- 无法会心
---@field NoKireajiHitCount number -- 不消耗斩味
---@field WeakPartHitCount number
---@field ScarHitCount number
---@field NoMeatHitCount number -- 无视肉质的攻击计数（炮击）
---@field PhysicalExploitHitCount number -- 弱特，45肉质，且非无视肉质
---@field ElementalExploitHitCount number -- 属弱，25吸收
---@field HitIndex number -- 指代该角色是第几个进战斗的，用于标识玩家颜色，猫没有

-- 记录角色的数据，如HR MR 名字 任务时间等
---@type table<Attacker, HunterData>
_M.HunterInfo = {} -- FIXME: 掉线后其他人加入？

---@return HunterData
local function NewHunterInfo()
    return {
        GUID = "",
        StableMemberIndex = -1,
        IsLeave = false,

        HitCount = 0,
        CriticalCount = 0,
        NegCriticalCount = 0,
        NoCriticalHitCount = 0,
        NoKireajiHitCount = 0,
        WeakPartHitCount = 0,
        ScarHitCount = 0,
        NoMeatHitCount = 0,
        PhysicalExploitHitCount = 0,
        ElementalExploitHitCount = 0,

        FightingTime = 0,
        IsCombatBoss = false,
        LastCombatBossStartTime = 0,
    }
end

---@class EnemyCharacterData
---@field Ctx EnemyContext
---@field IsBoss boolean

-- force update enemy health
_M.RequestUpdateEnemyHealth = false

---@type table<app.EnemyCharacter, EnemyCharacterData>
_M.EnemyCharacterData = {}

---@class EnemyData
---@field Name string
---@field HP number
---@field MaxHP number
---@field IsBoss boolean
---@field IsZako boolean
---@field IsAnimal boolean
---@field ACCESS_KEY ACCESS_KEY
---@field IsTarget boolean
---@field Character app.EnemyCharacter
---@field ActionController ace.cActionController

-- 记录怪物的数据，如名字、血量等
---@type table<EnemyContext, EnemyData>
_M.EnemyInfo = {} -- EnemyContext -> {Name, HP, MaxHP, ACCESS_KEY, IsTarget}

---@class QuestData
---@field Total number
---@field MaxPlayerTotal number
---@field MaxPlayerDPS number
---@field ElapsedTime number
---@field LimitTime number
---@field CurrentIndex number -- 指代目前有几个角色进了战斗，用于标识玩家，猫没有
---@field EnemyContexts EnemyContext[]

-- 记录怪物的统计数据，如总承伤
---@type table<EnemyContext, DamageRecord>
_M.EnemyDamageRecords = {}

---@class DamageRecord
---@field Total number
---@field Physical number
---@field Elemental number
---@field Fixed number
---@field PoisonDamage number
---@field BlastDamage number
---@field StatusTotal number
---@field Poison number
---@field Paralyse number
---@field Sleep number
---@field Blast number
---@field Stamina number
--- BLEED number
--- DEFENCE_DOWN number
---@field Stun number
---@field Ride number
---@field Parry number
---@field Block number
--- STENCH number
--- FREEZE number
--- FRENZY number

function _M.NewDamageRecord(t)
    if t == nil then
        t = {}
    end

    t.Total = 0
    t.Physical = 0
    t.Elemental = 0
    t.Fixed = 0
    t.PoisonDamage = 0
    t.BlastDamage = 0

    t.StatusTotal = 0

    t.Stun = 0
    t.Ride = 0
    t.Parry = 0
    t.Block = 0
    
    t.Poison = 0
    t.Paralyse = 0
    t.Sleep = 0
    t.Blast = 0
    t.Stamina = 0

    return t
end

---@return QuestRecord
local function NewQuestStats()
    local t = _M.NewDamageRecord()
    
    t.MaxPlayerTotal = 0
    t.MaxPlayerDPS = 0
    t.ElapsedTime = 0
    t.LimitTime = 0
    t.CurrentIndex = 0
    t.EnemyContexts = {}

    return t
end

---@class QuestRecord : QuestData, DamageRecord
-- 记录任务的统计数据，如总伤害等
---@type QuestRecord
_M.QuestStats = NewQuestStats()

_M.ValidCondType = {
    [CONST.EnemyConditionType.Stun] = "Stun",
    [CONST.EnemyConditionType.Ride] = "Ride",
    [CONST.EnemyConditionType.Block] = "Block",
    [CONST.EnemyConditionType.Parry] = "Parry",

    [CONST.EnemyConditionType.Poison] = "Poison",
    [CONST.EnemyConditionType.Paralyse] = "Paralyse",
    [CONST.EnemyConditionType.Sleep] = "Sleep",
    [CONST.EnemyConditionType.Blast] = "Blast",
    [CONST.EnemyConditionType.Stamina] = "Stamina",
}

-- 记录猎人合并的统计数据，如总造伤
---@type table<Hunter,  DamageRecord>
_M.HunterDamageRecords = {}

-- 记录猎人对不同怪物单独的统计数据，如总造伤
---@type table<Hunter,  table<EnemyContext, DamageRecord>>
_M.HunterEnemyDamageRecords = {} -- Hunter -> EnemyContext -> DamgeRecord

function _M.ClearData()
    mod.verbose("Overlay Data Cleared")
    _M.SimulatedTime = 0
    _M.IsQuestHost = true
    _M.HunterInfo = {}
    _M.EnemyCharacterData = {}
    _M.EnemyInfo = {}
    _M.QuestStats = NewQuestStats()
    _M.EnemyDamageRecords = {}
    _M.HunterDamageRecords = {}
    _M.HunterEnemyDamageRecords = {}
    
    _M.EnemyCrown = {}
    _M.EnemyScale = {}
end

---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param isPlayer boolean
---@param totalDamage number|nil
function _M.InitDamageRecord(attacker, enemyCtx, isPlayer, totalDamage)
    -- Update quest data
    if _M.QuestStats.Total == nil then
        _M.QuestStats = NewQuestStats()
    end

    if attacker then
        -- Core.SendMessage("DMG FROM: " .. tostring(_M.GetHunterName(attacker)))
        -- Update player info
        if _M.HunterInfo[attacker] == nil then
            _M.HunterInfo[attacker] = NewHunterInfo()
            _M.HunterInfo[attacker].IsPlayer = isPlayer
            _M.HunterInfo[attacker].IsNPC = false
            if isPlayer then
                local hunterExtend = attacker:get_HunterExtend()
                local isNPC = hunterExtend:get_IsNpc()
                _M.HunterInfo[attacker].IsNPC = isNPC

                if not isNPC then
                    local playerCtxHolder = hunterExtend:get_field("_ContextHolder") -- cPlayerContextHolder
                    local playerCtx = playerCtxHolder:get_Pl()
                    local playerName = playerCtx:get_PlayerName()
                    _M.HunterInfo[attacker].GUID = Core.FormatGUID(playerCtx:get_UniqueID())
                    _M.HunterInfo[attacker].ShortID = Core.GetShortHunterIDFromUniqueID(_M.HunterInfo[attacker].GUID)
                    _M.HunterInfo[attacker].StableMemberIndex = playerCtx._StableMemberIndex
                end

                _M.HunterInfo[attacker].Name = _M.GetHunterName(attacker)
                _M.HunterInfo[attacker].HR = _M.GetHunterHR(attacker)

                mod.verbose(string.format("Player %s Record: %s of %s", tostring(_M.HunterInfo[attacker].Name), tostring(_M.HunterInfo[attacker].StableMemberIndex), tostring(_M.HunterInfo[attacker].GUID)))
            else
                _M.HunterInfo[attacker].Name = _M.GetOtomoName(attacker)
            end
            -- Name
            -- HR = 0,
            -- MR = 0,
            -- ID = 0,
        end

        if _M.HunterInfo[attacker].FirstHitTime == nil then
            _M.HunterInfo[attacker].FirstHitTime = _M.QuestStats.ElapsedTime
            _M.HunterInfo[attacker].IsPlayer = isPlayer
            if isPlayer then
                _M.HunterInfo[attacker].HitIndex = _M.QuestStats.CurrentIndex
                _M.QuestStats.CurrentIndex = _M.QuestStats.CurrentIndex + 1
            end
        end
        
        -- Update per player data
        if _M.HunterDamageRecords[attacker] == nil then
            _M.HunterDamageRecords[attacker] = _M.NewDamageRecord()
        end

        -- Update per player per enemy data
        if _M.HunterEnemyDamageRecords[attacker] == nil then
            _M.HunterEnemyDamageRecords[attacker] = {}
        end

        if enemyCtx then
            if _M.HunterEnemyDamageRecords[attacker][enemyCtx] == nil then
                _M.HunterEnemyDamageRecords[attacker][enemyCtx] = _M.NewDamageRecord()
            end
        end
    end

    if enemyCtx then
        -- Update per enemy data
        if _M.EnemyDamageRecords[enemyCtx] == nil then
            _M.EnemyDamageRecords[enemyCtx] = _M.NewDamageRecord()
        end
    end
end

local NpcUtil = Core.WrapTypedef("app.NpcUtil")

---@param hunter Hunter
function _M.GetHunterName(hunter)
    local hunterExtend = hunter:get_HunterExtend()
    local isNPC = hunterExtend:get_IsNpc()
    if isNPC then
        local npcCtxHolder = hunterExtend:get_field("_ContextHolder") -- cNpcContextHolder
        local npcCtx = npcCtxHolder:get_Npc()
        return NpcUtil:StaticCall("getNpcName(app.NpcDef.ID)", npcCtx.NpcID)
    else
        local playerCtxHolder = hunterExtend:get_field("_ContextHolder") -- cPlayerContextHolder
        local playerCtx = playerCtxHolder:get_Pl()
        local playerName = playerCtx:get_PlayerName()
        return playerName
    end
end

function _M.GetMasterPlayerHR()
    local save = Core.GetSaveDataManager():getCurrentUserSaveData()
    local basicParam = save._BasicData -- app.savedata.cBasicParam
    local hp = basicParam:getHunterPoint()

    if mod.Config.Debug then
        hp = 9999
    end
    local hr = basicParam:getHunterRank(hp)
    -- FIXME: is it right??
    return hr
end

function _M.GetHunterHR(hunter)
    if hunter:get_IsMaster() then
        return _M.GetMasterPlayerHR()
    end

    local hunterExtendPlayer = hunter:get_HunterExtend() -- app.HunterCharacter.cHunterExtendBase
    local isNPC = hunterExtendPlayer:get_IsNpc()
    if isNPC then
        return 1
        -- local npcMgr = Core.GetNpcManager()
        -- local npcPartnerMgr = npcMgr:get_PartnerManager()
        -- local partners = npcPartnerMgr._PartnerList
        -- Core.ForEach(partners, function (partner)
        --     if partner:get_PartnerType() ~= 1 or not partner:get_Valid() then
        --         return
        --     end
        --     local ctrl = partner._ManageControl
        --     local npc = ctrl._HunterCharacter
        --     if hunter == npc then
        --         local rankType = partner:get_RankType()
        --         return rankType
        --     end
        -- end)
    end
    local questIndex = hunterExtendPlayer:get_StableQuestMemberIndex()

    local mgr = Core.GetNetworkManager()
    local netMgr = mgr:get_UserInfoManager()
    local netUserInfoList = netMgr:getUserInfoList(2) -- app.Net_UserInfoList, app.net_session_manager.SESSION_TYPE
    local memberNum = netUserInfoList:get_MemberNum()

    if questIndex == 0 or memberNum <= 1 then
        return _M.GetMasterPlayerHR()
    else
        local playerCtxHolder = hunterExtendPlayer:get_field("_ContextHolder") -- cPlayerContextHolder
        local playerCtx = playerCtxHolder:get_Pl()
        local hunterUniqueID = Core.FormatGUID(playerCtx:get_UniqueID())
    
        local hr = 1
        Core.ForEach(netUserInfoList._ListInfo, function (userInfo)
            if not userInfo:get_IsValid() then
                return
            end
            local param = userInfo.param
            local guid = Core.FormatGUID(param.HunterId)
            if param == hunterUniqueID then
                hr = userInfo:get_HunterRank()
                return Core.ForEachBreak
            end
        end)
        return hr
    end

    return 0
end

---@param otomo Otomo
function _M.GetOtomoName(otomo)
    local hunter = otomo:get_OwnerHunterCharacter()
    mod.verbose("Get Otomo Name: %s of %s", tostring(otomo), tostring(hunter))
    if hunter:get_IsMaster() then
        return Core.GetNetworkManager():SelfOtomoName()
    end

    local hunterExtendPlayer = hunter:get_HunterExtend() -- app.HunterCharacter.cHunterExtendBase
    local isNPC = hunterExtendPlayer:get_IsNpc()
    if isNPC then
        return _M.GetHunterName(hunter) .. " Otomo"
        -- TODO: 不知道怎么拿到 NPC 的猫的名字
        -- local npcMgr = Core.GetNpcManager()
        -- local npcPartnerMgr = npcMgr:get_PartnerManager()
        -- local partners = npcPartnerMgr._PartnerList
        -- Core.ForEach(partners, function (partner)
        --     if partner:get_PartnerType() ~= 1 or not partner:get_Valid() then
        --         return
        --     end
        --     local ctrl = partner._ManageControl
        --     local npc = ctrl._HunterCharacter
        --     if hunter == npc then
        --         -- OTOMO_TYPE_Fixed
        --         local otomoID = partner:get_OtomoID()
        --         local otomoMgr = Core.GetOtomoManager()
        --         local otomoInfo = otomoMgr:call("findPartnerNpcOtomoManagedInfo(app.OtomoDef.PARTNER_OTOMO_TYPE_Fixed)", otomoID)
        --     end
        -- end)
    end
    local questIndex = hunterExtendPlayer:get_StableQuestMemberIndex()

    local mgr = Core.GetNetworkManager()
    local netMgr = mgr:get_UserInfoManager()
    local netUserInfoList = netMgr:getUserInfoList(2) -- app.Net_UserInfoList, app.net_session_manager.SESSION_TYPE
    local memberNum = netUserInfoList:get_MemberNum()

    -- 这个 List 是按加入任务顺序来的，但是StableQuestMemberIndex 不是
    -- 玩家本人的 Stable Index 永远为0

    mod.verbose(string.format("Get OtomoName: QIndex: %s, MemNum: %s", tostring(questIndex), tostring(memberNum)))

    if questIndex == 0 or memberNum <= 1 then
        return mgr:SelfOtomoName()
    else
        local playerCtxHolder = hunterExtendPlayer:get_field("_ContextHolder") -- cPlayerContextHolder
        local playerCtx = playerCtxHolder:get_Pl()
        local hunterUniqueID = Core.FormatGUID(playerCtx:get_UniqueID())
    
        local otomoName = ""
        Core.ForEach(netUserInfoList._ListInfo, function (userInfo)
            if not userInfo:get_IsValid() then
                return
            end
            local param = userInfo.param
            local guid = Core.FormatGUID(param.HunterId)
            if param == hunterUniqueID then
                otomoName = userInfo:get_OtomoName()
                return Core.ForEachBreak
            end
        end)
        if otomoName == "" then
            otomoName = _M.GetHunterName(hunter) .. "_Otomo"
        end
        return otomoName
    end
end

_M.EnemyElementMeat = {
    Placeholder = true,
}
---@type table<EnemyContext, app.EnemyDef.CrownType>
_M.EnemyCrown = {}

---@type table<EnemyContext, integer>
_M.EnemyScale = {}

---@param ctx EnemyContext
function _M.InitEnemyCtxMeat(ctx)
    local emIdKey = tostring(ctx:get_EmID())
    if _M.EnemyElementMeat[emIdKey] then return end

    local meatArray = {}
    _M.EnemyElementMeat[emIdKey] = meatArray

    if not ctx.Parts then return end

    local param = ctx.Parts._ParamParts
    if not param then return end
    if not param._MeatArray then return end
    local meats = param._MeatArray._DataArray
    if not meats then return end

    local mFire, mWater, mIce, mThunder, mDragon = 0, 0, 0, 0, 0
    Core.ForEach(meats, function (meat)
        local fire, water, ice, thunder, dragon = meat._Fire, meat._Water, meat._Ice, meat._Thunder, meat._Dragon
        if fire > mFire then
            mFire = fire
        end
        if water > mWater then
            mWater = water
        end
        if ice > mIce then
            mIce = ice
        end
        if thunder > mThunder then
            mThunder = thunder
        end
        if dragon > mDragon then
            mDragon = dragon
        end
    end)

    table.insert(meatArray, {
        Meat = mFire,
        Type = "Fire",
    })
    table.insert(meatArray, {
        Meat = mWater,
        Type = "Water",
    })
    table.insert(meatArray, {
        Meat = mIce,
        Type = "Ice",
    })
    table.insert(meatArray, {
        Meat = mThunder,
        Type = "Thunder",
    })
    table.insert(meatArray, {
        Meat = mDragon,
        Type = "Dragon",
    })

    table.sort(meatArray, function (l, r)
        return l.Meat > r.Meat
    end)

    _M.EnemyElementMeat[emIdKey] = meatArray
end

---@param ctx EnemyContext
function _M.InitEnemyCtx(ctx, character)
    -- mod.verbose(string.format("InitEnemyCtx ctx: %s, chara: %s", tostring(ctx), tostring(character)))

    if not _M.EnemyInfo[ctx] then
        _M.EnemyInfo[ctx] = {}

        _M.EnemyInfo[ctx].Character = character
        _M.EnemyInfo[ctx].ActionController = character:get_BaseActionController()

        _M.EnemyInfo[ctx].IsBoss = ctx:get_IsBoss()
        _M.EnemyInfo[ctx].IsZako = ctx:get_IsZako()
        _M.EnemyInfo[ctx].IsAnimal = ctx:get_IsAnimal()
        
        if not _M.EnemyInfo[ctx].IsAnimal then
            _M.InitEnemyCtxMeat(ctx)
        end
        local browser = ctx:get_Browser()
        if browser then
            _M.EnemyCrown[ctx] = browser:checkCrownType()
        end

        _M.EnemyScale[ctx] = ctx:getModelScale_Boss()
    end

    if not _M.EnemyCharacterData[character] then
        _M.EnemyCharacterData[character] = {
            Ctx = ctx,
            IsBoss = _M.EnemyInfo[ctx].IsBoss,
        }
    end
end

---@param character app.EnemyCharacter
---@return EnemyContext, boolean
function _M.GetEnemyContext(character)
    if _M.EnemyCharacterData[character] then
        return _M.EnemyCharacterData[character].Ctx, _M.EnemyCharacterData[character].IsBoss
    end

    local enemyCtx = character:get_Context():get_Em()
    local isBoss = enemyCtx:get_IsBoss()
    _M.EnemyCharacterData[character] = {
        Ctx = enemyCtx,
        IsBoss = isBoss,
    }
    return enemyCtx, isBoss
end

---@param ctx EnemyContext
---@param hp number
---@param max number
function _M.UpdateEnemyCtxHealth(ctx, hp, max)
    _M.EnemyInfo[ctx].HP = hp
    _M.EnemyInfo[ctx].MaxHP = max
end

---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param condType app.EnemyDef.CONDITION
---@param value number
function _M.UpdateStatusDamage(attacker, enemyCtx, condType, value)
    local key = _M.ValidCondType[condType]
    if key then
        _M.QuestStats.StatusTotal = _M.QuestStats.StatusTotal + value
        _M.QuestStats[key] = _M.QuestStats[key] + value

        local data = _M.HunterDamageRecords[attacker]
        data.StatusTotal = data.StatusTotal + value
        data[key] = data[key] + value
        _M.HunterDamageRecords[attacker] = data

        local data = _M.HunterEnemyDamageRecords[attacker][enemyCtx]
        data.StatusTotal = data.StatusTotal + value
        data[key] = data[key] + value
        _M.HunterEnemyDamageRecords[attacker][enemyCtx] = data
    end
end

local ActionTypeNames = Core.GetEnumMap("app.HitDef.ACTION_TYPE")
---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param attackData app.cAttackParamPl | app.cAttackParamOt -- app.cAttackParamBase
---@param damageData app.cDamageParamEm -- app.cDamageParamBase
---@param isPlayer boolean
function _M.HandleHitData(attacker, enemyCtx, attackData, damageData, isPlayer)
    _M.HunterInfo[attacker].HitCount = _M.HunterInfo[attacker].HitCount + 1
    if attackData._CriticaType == CONST.CriticalType.Critical then
        _M.HunterInfo[attacker].CriticalCount = _M.HunterInfo[attacker].CriticalCount + 1
    elseif attackData._CriticaType == CONST.CriticalType.Negative then
        _M.HunterInfo[attacker].NegCriticalCount = _M.HunterInfo[attacker].NegCriticalCount + 1
    end

    if attackData._IsNoCritical then
        _M.HunterInfo[attacker].NoCriticalHitCount = _M.HunterInfo[attacker].NoCriticalHitCount + 1
    end
    if attackData._IsNoUseKireaji then
        _M.HunterInfo[attacker].NoKireajiHitCount = _M.HunterInfo[attacker].NoKireajiHitCount + 1
    end
    if damageData.IsHitWeakPoint_Parts then
        _M.HunterInfo[attacker].WeakPartHitCount = _M.HunterInfo[attacker].WeakPartHitCount + 1
    elseif damageData.IsHitWeakPoint_Scar then
        _M.HunterInfo[attacker].ScarHitCount = _M.HunterInfo[attacker].ScarHitCount + 1
    end
end

---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param FinalDamage number
function _M.HandleFixedDamage(attacker, enemyCtx, FinalDamage)
    -- Update quest data
    _M.QuestStats.Total = _M.QuestStats.Total + FinalDamage
    _M.QuestStats.Fixed = _M.QuestStats.Fixed + FinalDamage

    -- Update per player data
    _M.HunterDamageRecords[attacker].Total = _M.HunterDamageRecords[attacker].Total + FinalDamage
    _M.HunterDamageRecords[attacker].Fixed = _M.HunterDamageRecords[attacker].Fixed + FinalDamage

    -- Update per player per enemy data
    _M.HunterEnemyDamageRecords[attacker][enemyCtx].Total = _M.HunterEnemyDamageRecords[attacker][enemyCtx].Total + FinalDamage
    _M.HunterEnemyDamageRecords[attacker][enemyCtx].Fixed = _M.HunterEnemyDamageRecords[attacker][enemyCtx].Fixed + FinalDamage

    -- Update per enemy data
    _M.EnemyDamageRecords[enemyCtx].Total = _M.EnemyDamageRecords[enemyCtx].Total + FinalDamage
    _M.EnemyDamageRecords[enemyCtx].Fixed = _M.EnemyDamageRecords[enemyCtx].Fixed + FinalDamage
end

---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param FinalDamage number
function _M.HandlePoisonDamage(attacker, enemyCtx, FinalDamage)
    -- Update quest data
    _M.QuestStats.Total = _M.QuestStats.Total + FinalDamage
    _M.QuestStats.PoisonDamage = _M.QuestStats.PoisonDamage + FinalDamage

    -- Update per player data
    _M.HunterDamageRecords[attacker].Total = _M.HunterDamageRecords[attacker].Total + FinalDamage
    _M.HunterDamageRecords[attacker].PoisonDamage = _M.HunterDamageRecords[attacker].PoisonDamage + FinalDamage

    -- Update per player per enemy data
    _M.HunterEnemyDamageRecords[attacker][enemyCtx].Total = _M.HunterEnemyDamageRecords[attacker][enemyCtx].Total + FinalDamage
    _M.HunterEnemyDamageRecords[attacker][enemyCtx].PoisonDamage = _M.HunterEnemyDamageRecords[attacker][enemyCtx].PoisonDamage + FinalDamage

    -- Update per enemy data
    _M.EnemyDamageRecords[enemyCtx].Total = _M.EnemyDamageRecords[enemyCtx].Total + FinalDamage
    _M.EnemyDamageRecords[enemyCtx].PoisonDamage = _M.EnemyDamageRecords[enemyCtx].PoisonDamage + FinalDamage
end

---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param FinalDamage number
function _M.HandleBlastDamage(attacker, enemyCtx, FinalDamage)
    -- Update quest data
    _M.QuestStats.Total = _M.QuestStats.Total + FinalDamage
    _M.QuestStats.BlastDamage = _M.QuestStats.BlastDamage + FinalDamage

    -- Update per player data
    _M.HunterDamageRecords[attacker].Total = _M.HunterDamageRecords[attacker].Total + FinalDamage
    _M.HunterDamageRecords[attacker].BlastDamage = _M.HunterDamageRecords[attacker].BlastDamage + FinalDamage

    -- Update per player per enemy data
    local data = _M.HunterEnemyDamageRecords[attacker][enemyCtx]
    _M.HunterEnemyDamageRecords[attacker][enemyCtx].Total = _M.HunterEnemyDamageRecords[attacker][enemyCtx].Total + FinalDamage
    _M.HunterEnemyDamageRecords[attacker][enemyCtx].BlastDamage = _M.HunterEnemyDamageRecords[attacker][enemyCtx].BlastDamage + FinalDamage

    -- Update per enemy data
    local data = _M.EnemyDamageRecords[enemyCtx]
    _M.EnemyDamageRecords[enemyCtx].Total = _M.EnemyDamageRecords[enemyCtx].Total + FinalDamage
    _M.EnemyDamageRecords[enemyCtx].BlastDamage = _M.EnemyDamageRecords[enemyCtx].BlastDamage + FinalDamage
end

---@param attacker Attacker
---@param enemyCtx EnemyContext
---@param isPlayer boolean
---@param calcDamage app.cEnemyStockDamage.cCalcDamage
---@param damageRate app.cEnemyStockDamage.cDamageRate
---@param preCalc app.cEnemyStockDamage.cPreCalcDamage
function _M.HandleCalcDamage(attacker, enemyCtx, isPlayer, calcDamage, damageRate, preCalc)
    -- damage detail
    local FinalDamage = calcDamage.FinalDamage
    -- local SkillAdditionalDamge = Common.SkillAdditionalDamge
    local Physical = calcDamage.Physical
    local Fixed = 0
    local Elemental = calcDamage.Element
    -- TODO: Missing Parry/Block?
    local Ride = calcDamage.Ride
    local Stun = calcDamage.Stun
    -- bad conditions/debuffs
    local Blast = calcDamage.Blast
    local Paralyse = calcDamage.Paralyse
    local Poison = calcDamage.Poison
    local Sleep = calcDamage.Sleep
    local Stamina = calcDamage.Stamina

    if mod.Config.Debug and FinalDamage > 0  then
        local Common = calcDamage.Common
        local Msg = string.format("%0.1f: ScarCate: %d, PartCate: %d", FinalDamage, Common.ScarDamageCategory, Common.PartsCategory)
        Msg = Msg .. "\n"
        if FinalDamage > 0 then
            Msg = Msg .. Core.FloatFixed1(FinalDamage) .. "="
        end
        if Physical > 0 then
            Msg = Msg .. Core.FloatFixed1(Physical) .. "(P)"
        end
        if Elemental > 0 then
            Msg = Msg .. "+" .. Core.FloatFixed1(Elemental) .. "(E)"
        end
        local ScarIndex = calcDamage.ScarIndex or 0
        if ScarIndex > 0 then
            Msg = Msg .. string.format("[%d]", ScarIndex)
        end
        Core.SendMessage(Msg)
    end

    if isPlayer and (preCalc.ActionType == 0 or damageRate.Hide > 1.1) then -- or damageRate.Meat == 1 then
        -- 炮击？
        Fixed = Physical
        Physical = 0
        _M.HunterInfo[attacker].NoMeatHitCount = _M.HunterInfo[attacker].NoMeatHitCount + 1
    end

    if Physical > 0 and damageRate.Meat*100 >= 44.9 then
        _M.HunterInfo[attacker].PhysicalExploitHitCount = _M.HunterInfo[attacker].PhysicalExploitHitCount + 1
    end
    if Elemental > 0 and damageRate.MeatElem*100 >= 19.9 then
        _M.HunterInfo[attacker].ElementalExploitHitCount = _M.HunterInfo[attacker].ElementalExploitHitCount + 1
    end

    if mod.Config.Debug and FinalDamage > 0 then
        local Msg = ""
        local Meat = damageRate.Meat or 1
        local MeatElem = damageRate.MeatElem or 1
        local Angry = damageRate.Angry or 1
        local Difficulity = damageRate.Difficulity or 1
        if not (Meat == 1 and MeatElem == 1 and Angry == 1 and Difficulity == 1) then
            Msg = Msg .. string.format("Meat %0.3f/%0.3f +%0.3f +%0.3f\n", Meat, MeatElem, Angry, Difficulity)
        end

        local Kireaji = damageRate.Kireaji or 1
        local KireajiElem = damageRate.KireajiElem or 1
        local KireajiStun = damageRate.KireajiStun or 1
        if not (Kireaji == 1 and KireajiElem == 1 and KireajiStun == 1) then
            Msg = Msg .. string.format("Kireaji %0.3f +%0.3f +%0.3f\n", Kireaji, KireajiElem, KireajiStun)
        end

        local Hide = damageRate.Hide or 1
        local Sleep = damageRate.Sleep or 1
        local Stun = damageRate.Stun or 1
        local Ride = damageRate.Ride or 1
        if not (Hide == 1 and Sleep == 1 and Stun == 0 and Ride == 1) then
            Msg = Msg .. string.format("Debuff %0.3f +%0.3f +%0.3f +%0.3f\n", Hide, Sleep, Stun, Ride)
        end
        if Msg ~= "" then
            Msg = string.sub(Msg, 1, string.len(Msg)-1)
            Core.SendMessage(Msg)
        end

        Msg = ""
        local LightPlant = damageRate.LightPlant or 1
        local PartsBreak = damageRate.PartsBreak or 1

        local PorterRidingShell = damageRate.PorterRidingShell or 1
        local RidingOther = damageRate.RidingOther or 1
        if not (LightPlant == 0 and PartsBreak == 1 and PorterRidingShell == 1 and RidingOther == 1) then
            Msg = Msg .. string.format("?? %0.3f +%0.3f +%0.3f +%0.3f\n", LightPlant, PartsBreak, PorterRidingShell, RidingOther)
        end

        local ScarVital = damageRate.ScarVital or 1
        local TearScarDamage = damageRate.TearScarDamage or 1
        local RawScarDamage = damageRate.RawScarDamage or 1
        local OldScarDamage = damageRate.OldScarDamage or 1
        if not (ScarVital == 1 and TearScarDamage == 1 and RawScarDamage == 1 and OldScarDamage == 1) then
            Msg = Msg .. string.format("Scar %0.3f +%0.3f +%0.3f +%0.3f\n", ScarVital, TearScarDamage, RawScarDamage, OldScarDamage)
        end

        local ForAnimal = damageRate.ForAnimal or 1
        local FromEm = damageRate.FromEm or 1
        local FromEmPost = damageRate.FromEmPost or 1
        if not (ForAnimal == 1 and FromEm == 1 and FromEmPost == 1) then
            Msg = Msg .. string.format("From %0.3f +%0.3f +%0.3f\n", ForAnimal, FromEm, FromEmPost)
        end
        if Msg ~= "" then
            Msg = string.sub(Msg, 1, string.len(Msg)-1)
            Core.SendMessage(Msg)
        end
    end

    -- Update quest data
    _M.QuestStats.Total = _M.QuestStats.Total + FinalDamage
    _M.QuestStats.Physical = _M.QuestStats.Physical + Physical
    _M.QuestStats.Elemental = _M.QuestStats.Elemental + Elemental
    _M.QuestStats.Fixed = _M.QuestStats.Fixed + Fixed
    -- debuffs

    -- Update per player data
    local data = _M.HunterDamageRecords[attacker]
    data.Total = data.Total + FinalDamage
    data.Physical = data.Physical + Physical
    data.Elemental = data.Elemental + Elemental
    data.Fixed = data.Fixed + Fixed

    _M.HunterDamageRecords[attacker] = data

    -- Update per player per enemy data
    local data = _M.HunterEnemyDamageRecords[attacker][enemyCtx]
    data.Total = data.Total + FinalDamage
    data.Physical = data.Physical + Physical
    data.Elemental = data.Elemental + Elemental
    data.Fixed = data.Fixed + Fixed

    _M.HunterEnemyDamageRecords[attacker][enemyCtx] = data

    -- Update per enemy data
    local data = _M.EnemyDamageRecords[enemyCtx]
    data.Total = data.Total + FinalDamage
    data.Physical = data.Physical + Physical
    data.Elemental = data.Elemental + Elemental
    data.Fixed = data.Fixed + Fixed

    _M.EnemyDamageRecords[enemyCtx] = data
end

return _M