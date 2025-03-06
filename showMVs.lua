local cfg = {}

if not cfg.rec_margin then cfg.rec_margin = 10 end
if not cfg.line_space then cfg.line_space = 30 end

if not cfg.general_x then cfg.general_x = 1000 end
if not cfg.general_y then cfg.general_y = 100 end
if not cfg.general_cap_width then cfg.general_cap_width = 350 end
if not cfg.general_width then cfg.general_width = 120 end

local total_line = 0
local general_line = 0
-- top left of rectengle

local printGeneralLine = function(cap, value, --[[optional]]value_color)
	draw.text(cap, cfg.general_x + cfg.rec_margin, cfg.general_y + cfg.rec_margin + general_line * cfg.line_space, 0xFFFFFFFF)
	if value == true then
		value = "true"
		value_color = value_color or 0xFF00FF00 --default value
	elseif value == false then
		value = "false"
		value_color = value_color or 0xFFFFFFFF --default value
	elseif value == nil then
		value = "nil"
		value_color = value_color or 0xFF808080 --default value
	end

    value_color = value_color or 0xFFFFFFFF --default value
	if value then
		draw.text(tostring(value), cfg.general_x + cfg.general_cap_width + cfg.rec_margin, cfg.general_y + general_line * cfg.line_space + cfg.rec_margin, value_color)
	end
	general_line = general_line + 1
end

local PlayMan
local function getPlayMan()
    if not PlayMan then
        PlayMan = sdk.get_managed_singleton("app.PlayerManager")
    end
    return PlayMan
end

local MasterPlayer --app.cPlayerManageInfo
local function getMasterPlayer()
    if not MasterPlayer then
        if not getPlayMan() then return nil end
        MasterPlayer = PlayMan:getMasterPlayer()
    end
    return MasterPlayer
end

local HunterController --app.HunterController
local function getHunterController()
    if not HunterController then
        if not getMasterPlayer() then return nil end
        HunterController = MasterPlayer:get_Controller()
    end
    return HunterController
end

local HunterCharacter --app.HunterCharacter
local function getHunterCharacter()
    if not HunterCharacter then
        if not getMasterPlayer() then return nil end
        HunterCharacter = MasterPlayer:get_Character()
    end
    return HunterCharacter
end

local PlayerObject --MasterPlayerObject
local function getPlayerObject()
    if not PlayerObject then
        if not getMasterPlayer() then return nil end
        PlayerObject = MasterPlayer:get_Object()
    end
    return PlayerObject
end

local HunterHitController
local function getHunterHitController()
    if not HunterHitController then
        if not getHunterCharacter() then return nil end
        HunterHitController = HunterCharacter:get_HitComponent()
    end
    return HunterHitController
end

local HunterMotion
local function getHunterMotion()
    if not HunterMotion then
        if not getHunterCharacter() then return nil end
        HunterMotion = HunterCharacter:get_MotionComponent()
    end
    return HunterMotion
end

-- HunterCharacter
-- get_MotionComponent()
-- get_HitComponent()
-- get_ColSwitcherComponent()
-- get_CharaCtrl() -- via.physics.CharacterController
-- get_CharaParamHolder()


local playerLabel1 = "melee base attack"
local playerLabel2 = "shell base attack"
local playerLabel3 = "buffed attack"
local function drawPlayerLabel(text, color, posOffset)
    if not getPlayerObject() then return end
    local PlayerTransform = PlayerObject:get_Transform()
    if not PlayerTransform then return end
    local playerPos =  PlayerTransform:get_Position()

    if playerPos then
        playerPos.y = playerPos.y+posOffset -- hunter height 1.8m
        draw.world_text(text, playerPos, color)
    end

end

local AttackUniqueID = nil
local CollisionDataID = nil

local CleanUp = function()
    PlayMan = nil
    MasterPlayer = nil
    HunterController = nil
    HunterCharacter = nil
    PlayerObject = nil
    HunterHitController = nil
    HunterMotion = nil
end

re.on_frame(function()

    if not getHunterCharacter() then CleanUp() return end
    
    local IsWeaponOn = HunterCharacter:get_IsWeaponOn()
    -- local IsWeaponOnAction = HunterCharacter:get_IsWeaponOnAction()
    -- local IsCombat = HunterCharacter:get_IsCombat()
    -- local IsCombatBoss = HunterCharacter:get_IsCombatBoss()
    -- local IsCombatAngryBoss = HunterCharacter:get_IsCombatAngryBoss()
    -- local IsHalfCombat = HunterCharacter:get_IsHalfCombat()
    -- local IsCombatCageLight = HunterCharacter:get_IsCombatCageLight()
    -- local IsInLifeArea = HunterCharacter:get_IsInLifeArea()
    -- local IsInBaseCamp = HunterCharacter:get_IsInBaseCamp()
    -- local IsInTent = HunterCharacter:get_IsInTent()

	-- if IsWeaponOn or (not IsInLifeArea) then

    general_line = 0

    -- draw.filled_rect(cfg.general_x, cfg.general_y, 
    --     cfg.general_width + cfg.general_cap_width + cfg.rec_margin * 2, 
    --     total_line * cfg.line_space + cfg.rec_margin * 2,
    --     0x44000000)

    total_line = general_line


    -- printGeneralLine("IsWeaponOn", IsWeaponOn)
    -- printGeneralLine("IsWeaponOnAction", IsWeaponOnAction)
    -- printGeneralLine("IsCombat", IsCombat)
    -- printGeneralLine("IsCombatBoss", IsCombatBoss)
    -- printGeneralLine("IsCombatAngryBoss", IsCombatAngryBoss)
    -- printGeneralLine("IsHalfCombat", IsHalfCombat)
    -- printGeneralLine("IsCombatCageLight", IsCombatCageLight)
    -- printGeneralLine("IsInLifeArea", IsInLifeArea)
    -- printGeneralLine("IsInBaseCamp", IsInBaseCamp)
    -- printGeneralLine("IsInTent", IsInTent)
    
    -- local BaseActionController = HunterCharacter:get_BaseActionController()
    -- if BaseActionController then
    --     local CurrentActionID = BaseActionController._CurrentActionID
    --     if CurrentActionID then
    --         printGeneralLine("[Base]CurrentActionID", "["..CurrentActionID:get_Category().."]"..CurrentActionID:get_Index())
    --     end
    --     local PrevActionID = BaseActionController._PrevActionID
    --     if PrevActionID then
    --         printGeneralLine("[Base]PrevActionID", "["..PrevActionID:get_Category().."]"..PrevActionID:get_Index())
    --     end
    -- end

    -- local SubActionController = HunterCharacter:get_SubActionController()
    -- if SubActionController then
    --     local CurrentActionID = SubActionController._CurrentActionID
    --     if CurrentActionID then
    --         printGeneralLine("[Sub]CurrentActionID", "["..CurrentActionID:get_Category().."]"..CurrentActionID:get_Index())
    --     end
    --     local PrevActionID = SubActionController._PrevActionID
    --     if PrevActionID then
    --         printGeneralLine("[Sub]PrevActionID", "["..PrevActionID:get_Category().."]"..PrevActionID:get_Index())
    --     end
    -- end

    
    if getPlayerObject() then
        drawPlayerLabel(playerLabel1, 0xFFFFFFFF, 1.8)
        drawPlayerLabel(playerLabel2, 0xFFFFFFFF, 1.9)
        drawPlayerLabel(playerLabel3, 0xFFFFFFFF, 2.0)
    end

    if IsWeaponOn then
        -- printGeneralLine("AttackUniqueID", AttackUniqueID)
        -- printGeneralLine("CollisionDataID", CollisionDataID)
    end

    total_line = general_line
	-- end

end)

-- thanks to @orcas
sdk.hook(
    sdk.find_type_definition("app.Weapon"):get_method("evAttackCollisionActive(app.col_user_data.AttackParam)"),
    function(args)
        local AttackParam = sdk.to_managed_object(args[3])
        if not AttackParam then return end
        -- local cRuntimeData = sdk.to_managed_object(AttackParam._RuntimeData)
        -- if not cRuntimeData then return end
        -- AttackUniqueID = cRuntimeData._AttackUniqueID
        -- CollisionDataID = cRuntimeData._CollisionDataID._Index
        
        local Attack = AttackParam:get_Attack()
        local TotalAttack = AttackParam:get_TotalAttack()
        local StatusAttrRate = AttackParam:get_StatusAttrRate()
        local StatusConditionRate = AttackParam:get_StatusConditionRate()

        playerLabel1 = "melee  [ "..Attack.." | "..TotalAttack.." ] "..StatusAttrRate.." / "..StatusConditionRate
    end,
    function (retval)
        return retval
    end
)

-- thanks to @orcas
sdk.hook(
    sdk.find_type_definition("app.mcShellColHit"):get_method(
        "evAttackPreProcess(app.HitInfo)"),
    function(args)
        local HitInfo = sdk.to_managed_object(args[3])
        if not HitInfo then return end
        if not (HitInfo:getActualAttackOwner():ToString() == getPlayerObject():ToString()) then return end

        local AttackParam = HitInfo:get_field("<AttackData>k__BackingField")
        if not AttackParam then return end

        local Attack = AttackParam:get_field("_Attack")
        local StatusAttrRate = AttackParam:get_field("_StatusAttrRate")
        local StatusConditionRate = AttackParam:get_field("_StatusConditionRate")

        playerLabel2 = "shell  [ "..Attack.." | ".." ] "..StatusAttrRate.." / "..StatusConditionRate
    end,
    function (retval)
        return retval
    end
)

-- thanks to @WAI
sdk.hook(
    sdk.find_type_definition("app.HunterCharacter"):get_method("evHit_AttackPostProcess(app.HitInfo)"),
    function(args)
        local HitInfo = sdk.to_managed_object(args[3])
        if not HitInfo then return end
        if not (HitInfo:getActualAttackOwner():ToString() == getPlayerObject():ToString()) then return end

        local AttackParam = HitInfo:get_field("<AttackData>k__BackingField")
        if not AttackParam then return end

        local Attack = AttackParam:get_field("_Attack")
        local StatusAttrRate = AttackParam:get_field("_StatusAttrRate")
        local StatusConditionRate = AttackParam:get_field("_StatusConditionRate")

        playerLabel3 = "buffed [ "..Attack.." | ".." ] "..StatusAttrRate.." / "..StatusConditionRate
    end,
    function (retval)
        return retval
    end
)
